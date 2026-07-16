"""Authentication dependency.

The backend is single-user (decision D2) and does not run an account system.
Instead, every request must present a shared bearer token that the operator
configures in ``.env`` (decision D7). The token is compared in constant time
to avoid timing side channels.

Because the streaming endpoint is consumed from the browser's
``EventSource`` API, which cannot set custom headers, the dependency also
accepts the token as a ``token`` query parameter. Non-streaming endpoints
should use the ``Authorization: Bearer ...`` header.
"""

from __future__ import annotations

import secrets

from fastapi import Depends, HTTPException, Request, status

from .config import Settings, get_settings


def _extract_token(request: Request) -> str | None:
    """Pull the bearer token out of either the header or the query string."""
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
    """Reject the request unless a valid shared token is presented.

    Raises a 401 response on failure; returns ``None`` on success so the
    dependency can be used as a guard without injecting any value.
    """
    token = _extract_token(request)
    if token is None or not secrets.compare_digest(token, settings.auth_token):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="invalid or missing bearer token",
            headers={"WWW-Authenticate": "Bearer"},
        )
