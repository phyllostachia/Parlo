"""FastAPI application factory and wiring.

The application owns the SQLite database, proxies streaming chat requests to
the selected upstream provider, serves uploaded images, and exposes the REST
API consumed by the Flutter client. The frontend is deployed as a separate
origin, so CORS is configured from ``settings.cors_origins``.
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
    """Create data directories and the database schema on startup.

    Running ``init_db`` here means a fresh checkout works with no manual
    migration step. The image directory is also created eagerly so the first
    upload does not race a lazy ``makedirs``.
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
    """Build the configured FastAPI application instance."""
    settings = get_settings()
    app = FastAPI(
        title="Parlo Backend",
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
        """Unauthenticated liveness probe used by the client setup screen."""
        return {"status": "ok"}

    @app.get(
        "/images/{filename}",
        dependencies=[Depends(verify_token)],
        tags=["images"],
    )
    async def get_image(filename: str) -> FileResponse:
        """Serve an uploaded image to an authenticated client.

        Auth is enforced so a guessed URL alone is not enough to read images;
        the filename still has to be a server-generated UUID name, which
        :func:`safe_filename` checks for path-traversal safety.
        """
        safe_filename(filename)
        path = os.path.join(get_settings().app_config.images.upload_dir, filename)
        if not os.path.isfile(path):
            raise HTTPException(status.HTTP_404_NOT_FOUND, "image not found")
        ext = filename.rsplit(".", 1)[-1].lower()
        return FileResponse(path, media_type=_MEDIA_TYPES.get(ext, "application/octet-stream"))

    return app


app = create_app()
