"""模型注册表 endpoint。

``GET /api/models`` 返回 ``config.yaml`` 中声明的模型列表和已配置的默认模型，使客户端
无需内置 protocol knowledge 就能填充 model 和 thinking-effort selector。该 endpoint
与其他 API route 一样需要鉴权；响应不包含密钥（会移除 ``api_key`` 和 ``base_url``）。
"""

from __future__ import annotations

from fastapi import APIRouter, Depends

from ..auth import verify_token
from ..config import get_settings
from ..models import ModelRead, ModelsResponse

router = APIRouter(prefix="/models", dependencies=[Depends(verify_token)])


@router.get("", response_model=ModelsResponse)
async def list_models(settings=Depends(get_settings)) -> ModelsResponse:
    """返回默认 model id 和每个模型面向客户端的 metadata。"""
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
