"""图片 upload 和 retrieval。

图片以 base64 data URL 的形式从客户端到达，因此 Flutter 客户端在 Web 和 native 上都能
使用同一条 code path，不需要处理 multipart form 差异。图片会通过 Pillow 校验，写入已
配置的 directory，并且只用服务器生成的 filename 在 message 中引用，绝不使用客户端提供
的 name，因此不存在 path-traversal surface。

provider adapter 需要将图片转发到上游时，会通过 :func:`read_image_base64` 重新读取图片。
"""

from __future__ import annotations

import base64
import binascii
import os
import re
import uuid
from io import BytesIO
from typing import Any

import anyio
from PIL import Image

from .config import Settings

_DATA_URL_RE = re.compile(
    r"data:image/(?P<ext>[a-zA-Z0-9.+]+);base64,(?P<data>.+)",
    re.DOTALL,
)
"""匹配 ``data:image/<ext>;base64,<data>`` URL 的 pattern。"""

_ALLOWED_EXTS: dict[str, str] = {
    "png": "png",
    "jpeg": "jpg",
    "jpg": "jpg",
    "webp": "webp",
    "gif": "gif",
}
"""允许的 source format，以及映射到的磁盘存储 extension。"""

_MEDIA_TYPES: dict[str, str] = {
    "png": "image/png",
    "jpg": "image/jpeg",
    "webp": "image/webp",
    "gif": "image/gif",
}


class ImageError(ValueError):
    """当图片无法解析或未通过校验时抛出。"""


def _parse_and_validate(data_url: str, max_bytes: int) -> tuple[str, bytes]:
    """解码 data URL，并返回 ``(extension, raw_bytes)``。

    校验分为两层：base64 必须能够解析，Pillow 必须能够以允许的 format 打开并验证真实
    图片。byte length 会在 Pillow 之前检查，因此过大的 upload 会在消耗解码 CPU 之前被拒绝。
    """
    match = _DATA_URL_RE.match(data_url)
    if not match:
        raise ImageError("not a valid image data URL")
    ext = match.group("ext").lower()
    if ext not in _ALLOWED_EXTS:
        raise ImageError(f"unsupported image format: {ext}")
    try:
        data = base64.b64decode(match.group("data"))
    except (binascii.Error, ValueError) as exc:
        raise ImageError("invalid base64 image data") from exc
    if len(data) > max_bytes:
        raise ImageError("image exceeds the maximum allowed size")
    try:
        image = Image.open(BytesIO(data))
        image.verify()
    except Exception as exc:  # Pillow 对损坏输入可能抛出多种类型的异常
        raise ImageError("corrupt or unreadable image") from exc
    return _ALLOWED_EXTS[ext], data


def _write_image_sync(upload_dir: str, ext: str, data: bytes) -> str:
    """创建 directory 并写入文件的同步 helper。

    该 helper 预期通过 :func:`anyio.to_thread.run_sync` 在 worker thread 中运行，从而在
    执行 disk I/O 时不会阻塞 event loop。
    """
    os.makedirs(upload_dir, exist_ok=True)
    filename = f"{uuid.uuid4().hex}.{ext}"
    path = os.path.join(upload_dir, filename)
    with open(path, "wb") as handle:
        handle.write(data)
    return filename


async def save_image(data_url: str, settings: Settings) -> str:
    """校验并持久化图片，返回生成的 filename。

    返回 filename 而不是完整 path，使调用方可以将它存入 database，并使用 API base
    prefix 构造 URL。
    """
    ext, data = await anyio.to_thread.run_sync(
        _parse_and_validate, data_url, settings.app_config.images.max_bytes
    )
    return await anyio.to_thread.run_sync(
        _write_image_sync, settings.app_config.images.upload_dir, ext, data
    )


def _read_image_sync(upload_dir: str, filename: str) -> tuple[str, bytes]:
    """从磁盘读取图片，并返回 ``(extension, raw_bytes)``。"""
    path = os.path.join(upload_dir, filename)
    ext = filename.rsplit(".", 1)[-1].lower()
    with open(path, "rb") as handle:
        return ext, handle.read()


async def read_image_base64(
    settings: Settings,
    filename: str,
) -> tuple[str, str]:
    """为磁盘中的图片返回 ``(media_type, base64_data)``。

    provider adapter 转发图片到上游时会使用该函数。media type 从 file extension 推导，
    且 filename 由服务器生成，因此是安全的。
    """
    ext, data = await anyio.to_thread.run_sync(
        _read_image_sync, settings.app_config.images.upload_dir, filename
    )
    if ext not in _MEDIA_TYPES:
        raise ImageError(f"unknown stored image extension: {ext}")
    return _MEDIA_TYPES[ext], base64.b64encode(data).decode("ascii")


def image_url_for(filename: str | None) -> str | None:
    """根据已存储的图片 filename 构建面向客户端的 URL。"""
    if not filename:
        return None
    return f"/images/{filename}"


def safe_filename(filename: str) -> Any:
    """拒绝包含 path separator 的 filename。

    static-file mount 已经阻止 traversal，但此 guard 可以确保 direct lookup 安全，并在
    call site 明确表达这一意图。
    """
    if not filename or "/" in filename or "\\" in filename or ".." in filename:
        raise ImageError("invalid image filename")
    return filename
