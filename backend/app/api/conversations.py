"""会话 endpoint。

会话属于一个 profile，并拥有一棵 message tree。每个会话只绑定一个 model（决策 D03）：
创建时设置 ``model_id`` 和 ``thinking_effort``，之后只能修改 ``thinking_effort`` 和
``title``（决策 D09）。

列表和创建操作位于 ``/profiles/{profile_id}/conversations`` 下；单个会话的读取、更新
和删除位于 ``/conversations/{conversation_id}`` 下。所有 endpoint 都要求共享 bearer
token。
"""

from __future__ import annotations

from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import select

from ..auth import verify_token
from ..config import get_settings
from ..db import get_session
from ..models import Conversation, ConversationCreate, ConversationRead, ConversationUpdate, Profile

router = APIRouter(dependencies=[Depends(verify_token)])


def _resolve_thinking_effort(
    model_id: str, requested: str | None, settings
) -> str:
    """返回新建或 patch 会话要使用的 thinking-effort 级别。

    如果 ``requested`` 为 ``None``，则使用模型列表中的第一个级别作为默认值（决策
    D05）。如果提供了值，则它必须属于模型支持的级别，否则会抛出 400。
    """
    model = settings.app_config.get_model(model_id)
    if model is None:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            f"unknown model id: {model_id!r}",
        )
    if requested is None:
        return model.thinking_effort[0]
    if requested not in model.thinking_effort:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            f"thinking_effort {requested!r} is not supported by model "
            f"{model_id!r}; supported levels: {model.thinking_effort}",
        )
    return requested


@router.get(
    "/profiles/{profile_id}/conversations",
    response_model=list[ConversationRead],
)
async def list_conversations(
    profile_id: int, session=Depends(get_session)
) -> list[Conversation]:
    """按最新更新时间优先返回 profile 中的会话。"""
    profile = await session.get(Profile, profile_id)
    if profile is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "profile not found")
    statement = (
        select(Conversation)
        .where(Conversation.profile_id == profile_id)
        .order_by(Conversation.updated_at.desc())
    )
    result = await session.execute(statement)
    return list(result.scalars())


@router.post(
    "/profiles/{profile_id}/conversations",
    response_model=ConversationRead,
    status_code=status.HTTP_201_CREATED,
)
async def create_conversation(
    profile_id: int,
    body: ConversationCreate,
    session=Depends(get_session),
    settings=Depends(get_settings),
) -> Conversation:
    """在给定 profile 中创建并绑定到指定 model 的会话。

    如果省略 ``thinking_effort``，则使用模型列表中的第一个级别。会话存续期间不会
    更换其绑定的 model。
    """
    profile = await session.get(Profile, profile_id)
    if profile is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "profile not found")
    if settings.app_config.get_model(body.model_id) is None:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            f"unknown model id: {body.model_id!r}",
        )
    thinking_effort = _resolve_thinking_effort(body.model_id, body.thinking_effort, settings)
    conversation = Conversation(
        profile_id=profile_id,
        title=body.title.strip(),
        model_id=body.model_id,
        thinking_effort=thinking_effort,
    )
    session.add(conversation)
    await session.commit()
    await session.refresh(conversation)
    return conversation


@router.get("/conversations/{conversation_id}", response_model=ConversationRead)
async def get_conversation(
    conversation_id: int, session=Depends(get_session)
) -> Conversation:
    """按 id 返回单个会话。"""
    conversation = await session.get(Conversation, conversation_id)
    if conversation is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "conversation not found")
    return conversation


@router.patch("/conversations/{conversation_id}", response_model=ConversationRead)
async def update_conversation(
    conversation_id: int,
    body: ConversationUpdate,
    session=Depends(get_session),
    settings=Depends(get_settings),
) -> Conversation:
    """更新会话的 title 和/或 thinking_effort。

    这里不能修改 ``model_id``（决策 D09）；如果要使用其他 model，请创建新会话。
    ``thinking_effort`` 会根据模型支持的级别进行校验。
    """
    conversation = await session.get(Conversation, conversation_id)
    if conversation is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "conversation not found")
    if body.title is not None:
        conversation.title = body.title.strip()
    if body.thinking_effort is not None:
        conversation.thinking_effort = _resolve_thinking_effort(
            conversation.model_id, body.thinking_effort, settings
        )
    conversation.updated_at = datetime.now(timezone.utc)
    session.add(conversation)
    await session.commit()
    await session.refresh(conversation)
    return conversation


@router.delete(
    "/conversations/{conversation_id}", status_code=status.HTTP_204_NO_CONTENT
)
async def delete_conversation(
    conversation_id: int, session=Depends(get_session)
) -> None:
    """删除会话。``message.conversation_id`` 上的 ``ON DELETE CASCADE`` rule 会删除消息。"""
    conversation = await session.get(Conversation, conversation_id)
    if conversation is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "conversation not found")
    await session.delete(conversation)
    await session.commit()
