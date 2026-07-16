"""Conversation endpoints.

Conversations belong to a profile and own a message tree. Each conversation
is bound to a single model (decision D03): the ``model_id`` and
``thinking_effort`` are set at creation and only ``thinking_effort`` (and the
``title``) may be changed afterwards (decision D09).

List and create are scoped under ``/profiles/{profile_id}/conversations`;
single-conversation read, update, and delete are under
``/conversations/{conversation_id}``. All endpoints require the shared bearer
token.
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
    """Return the thinking-effort level to use for a new or patched
    conversation.

    If ``requested`` is ``None``, the model's first listed level is used as
    the default (decision D05). If given, it must be one of the model's
    listed levels; otherwise a 400 is raised.
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
    """Return the conversations in a profile, newest first."""
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
    """Create a conversation in the given profile bound to the given model.

    ``thinking_effort`` defaults to the model's first listed level when
    omitted. The model is fixed for the lifetime of the conversation.
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
    """Return a single conversation by id."""
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
    """Update a conversation's title and/or thinking_effort.

    ``model_id`` is not changeable here (decision D09); to use a different
    model, create a new conversation. ``thinking_effort`` is validated against
    the model's supported levels.
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
    """Delete a conversation. Messages are removed by the ``ON DELETE
    CASCADE`` rule on ``message.conversation_id``."""
    conversation = await session.get(Conversation, conversation_id)
    if conversation is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "conversation not found")
    await session.delete(conversation)
    await session.commit()
