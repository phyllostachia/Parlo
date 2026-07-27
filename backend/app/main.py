"""FastAPI application factory 和 wiring。

应用负责 SQLite database，将流式聊天请求代理到选定的上游 provider，提供上传的图片，
并暴露 Flutter 客户端使用的 REST API。由于前端部署在独立 origin，CORS 会根据
``settings.cors_origins`` 配置。
"""

from __future__ import annotations

import os
from contextlib import asynccontextmanager

from fastapi import Depends, FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from starlette.staticfiles import StaticFiles

from .api import conversations, chat, messages, models, profiles
from .auth import verify_token
from .config import get_settings
from .db import init_db
from .storage import safe_filename

_MEDIA_TYPES = {
    "png": "image/png",
    "jpg": "image/jpeg",
    "jpeg": "image/jpeg",
    "webp": "image/webp",
    "gif": "image/gif",
}


@asynccontextmanager
async def lifespan(app: FastAPI):
    """在启动时创建 data directory 和 database schema。

    在这里运行 ``init_db`` 后，全新 checkout 无需手动 migration step 即可工作。图片
    directory 也会提前创建，避免第一次 upload 与 lazy ``makedirs`` 发生竞争。
    """
    settings = get_settings()
    image_upload_dir = settings.app_config.images.upload_dir
    os.makedirs(image_upload_dir, exist_ok=True)
    db_dir = os.path.dirname(
        settings.app_config.database.url.replace("sqlite+aiosqlite:///", "")
    )
    if db_dir:
        os.makedirs(db_dir, exist_ok=True)
    await init_db()
    yield


def create_app() -> FastAPI:
    """构建已配置的 FastAPI application instance。"""
    settings = get_settings()
    app = FastAPI(
        title="Tan Backend",
        version="0.1.0",
        lifespan=lifespan,
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.app_config.server.cors_origins,
        allow_methods=["GET", "POST", "PATCH", "DELETE", "OPTIONS"],
        allow_headers=["Authorization", "Content-Type"],
        allow_credentials=False,
    )

    app.include_router(profiles.router, prefix="/api")
    app.include_router(conversations.router, prefix="/api")
    app.include_router(messages.router, prefix="/api")
    app.include_router(models.router, prefix="/api")
    app.include_router(chat.router, prefix="/api")

    @app.get("/api/health", tags=["meta"])
    async def health() -> dict[str, str]:
        """供客户端 setup screen 使用的免鉴权 liveness probe。"""
        return {"status": "ok"}

    @app.get(
        "/images/{filename}",
        dependencies=[Depends(verify_token)],
        tags=["images"],
    )
    async def get_image(filename: str) -> FileResponse:
        """向已鉴权客户端提供上传的图片。

        这里强制执行 auth，因此仅猜到 URL 也不足以读取图片；filename 仍必须是服务器
        生成的 UUID name，:func:`safe_filename` 会检查其 path-traversal safety。
        """
        safe_filename(filename)
        path = os.path.join(get_settings().app_config.images.upload_dir, filename)
        if not os.path.isfile(path):
            raise HTTPException(status.HTTP_404_NOT_FOUND, "image not found")
        ext = filename.rsplit(".", 1)[-1].lower()
        return FileResponse(path, media_type=_MEDIA_TYPES.get(ext, "application/octet-stream"))

    return app


app = create_app()
