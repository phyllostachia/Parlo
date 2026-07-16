"""Model registry endpoint.

``GET /api/models`` returns the list of models declared in ``config.yaml``
together with the configured default, so the client can populate its model
and thinking-effort selectors without any protocol knowledge baked in. The
endpoint is authenticated like every other API route; the response carries
no secrets (``api_key`` and ``base_url`` are stripped).
"""

from __future__ import annotations

from fastapi import APIRouter, Depends

from ..auth import verify_token
from ..config import get_settings
from ..models import ModelRead, ModelsResponse

router = APIRouter(prefix="/models", dependencies=[Depends(verify_token)])


@router.get("", response_model=ModelsResponse)
async def list_models(settings=Depends(get_settings)) -> ModelsResponse:
    """Return the default model id and every model's client-facing metadata."""
    app_config = settings.app_config
    return ModelsResponse(
        default_model=app_config.default_model,
        models=[
            ModelRead(
                id=model.id,
                display_name=model.display_name,
                family=model.family,
                protocol=model.protocol,
                vision=model.vision,
                thinking_effort=model.thinking_effort,
            )
            for model in app_config.models
        ],
    )
