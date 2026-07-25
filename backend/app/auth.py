"""Authentication dependency。

后端是单用户应用（决策 D2），不运行 account system。相反，每个 request 都必须提供
operator 在 ``.env`` 中配置的共享 bearer token（决策 D7）。token 使用 constant-time
比较，以避免 timing side channel。

由于 streaming endpoint 使用浏览器的 ``EventSource`` API，而该 API 无法设置 custom
header，因此 dependency 也接受 ``token`` query parameter。非 streaming endpoint 应
使用 ``Authorization: Bearer ...`` header。
"""

from __future__ import annotations

import secrets

from fastapi import Depends, HTTPException, Request, status

from .config import Settings, get_settings


def _extract_token(request: Request) -> str | None:
    """从 header 或 query string 中提取 bearer token。"""
    auth_header = request.headers.get("Authorization")
    if auth_header:
        parts = auth_header.split()
        if len(parts) == 2 and parts[0].lower() == "bearer":
            return parts[1]
    return request.query_params.get("token")


async def verify_token(
    request: Request,
    settings: Settings = Depends(get_settings),
) -> None:
    """除非提供有效的共享 token，否则拒绝 request。

    失败时返回 401；成功时返回 ``None``，因此该 dependency 可以作为 guard 使用，而
    不需要注入任何值。
    """
    token = _extract_token(request)
    if token is None or not secrets.compare_digest(token, settings.auth_token):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="invalid or missing bearer token",
            headers={"WWW-Authenticate": "Bearer"},
        )
