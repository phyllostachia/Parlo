"""Message tree endpoints.

Messages form a tree inside a conversation (decision D18). These endpoints
create user messages, regenerate assistant replies, switch the visible path
between sibling replies, list the visible path with sibling metadata, and
delete subtrees. All require the shared bearer token.

The streaming itself lives in :mod:`app.api.chat`; these endpoints only
create the messages that the stream writes into, so the write path stays
simple and testable without a live upstream provider.
"""

from __future__ import annotations

from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import select

from ..auth import verify_token
from ..config import Settings, get_settings
from ..db import get_session
from ..models import (
    Conversation,
    Message,
    MessageRead,
    MessageRole,
    MessageTreeNode,
    SiblingInfo,
    ConversationPath,
    SendMessageResponse,
    UserMessageCreate,
)
from ..storage import ImageError, image_url_for, save_image, safe_filename

router = APIRouter(dependencies=[Depends(verify_token)])


def _to_message_read(message: Message) -> MessageRead:
    """Convert a :class:`Message` row into the client-facing read model."""
    return MessageRead(
        id=message.id,
        conversation_id=message.conversation_id,
        parent_id=message.parent_id,
        role=message.role,
        content=message.content,
        reasoning=message.reasoning,
        image_url=image_url_for(message.image_path),
        is_complete=message.is_complete,
        created_at=message.created_at,
    )


async def _load_message(session, conversation_id: int, message_id: int) -> Message:
    """Fetch a message and confirm it belongs to the given conversation."""
    message = await session.get(Message, message_id)
    if message is None or message.conversation_id != conversation_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "message not found")
    return message


async def _path_from_leaf(session, conversation: Conversation) -> list[Message]:
    """Walk ``parent_id`` from the current leaf to the root.

    Returns the messages in root-to-leaf order. An empty list means the
    conversation has no messages yet.
    """
    if conversation.current_leaf_id is None:
        return []
    chain: list[Message] = []
    current_id = conversation.current_leaf_id
    seen: set[int] = set()
    while current_id is not None:
        if current_id in seen:
            # Defensive: a cycle would hang the loop, so break on repeat.
            break
        seen.add(current_id)
        message = await session.get(Message, current_id)
        if message is None:
            break
        chain.append(message)
        current_id = message.parent_id
    chain.reverse()
    return chain


async def _siblings_of(session, message: Message) -> SiblingInfo:
    """Find all messages that share ``message``'s parent, including itself.

    The active sibling is ``message`` itself; the client uses ``siblings``
    to render a ``< n / m >`` switcher.
    """
    statement = select(Message.id).where(
        Message.conversation_id == message.conversation_id,
        Message.parent_id == message.parent_id,
    )
    result = await session.execute(statement)
    siblings = [row[0] for row in result.all()]
    return SiblingInfo(siblings=siblings, active_id=message.id)


@router.get(
    "/conversations/{conversation_id}/messages",
    response_model=ConversationPath,
)
async def get_conversation_path(
    conversation_id: int, session=Depends(get_session)
) -> ConversationPath:
    """Return the visible message path with per-node sibling metadata."""
    conversation = await session.get(Conversation, conversation_id)
    if conversation is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "conversation not found")
    chain = await _path_from_leaf(session, conversation)
    nodes: list[MessageTreeNode] = []
    for message in chain:
        siblings = await _siblings_of(session, message)
        nodes.append(MessageTreeNode(message=_to_message_read(message), siblings=siblings))
    return ConversationPath(conversation=conversation, path=nodes)


@router.post(
    "/conversations/{conversation_id}/messages",
    response_model=SendMessageResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_user_message(
    conversation_id: int,
    body: UserMessageCreate,
    session=Depends(get_session),
    settings: Settings = Depends(get_settings),
) -> SendMessageResponse:
    """Create a user message and an assistant placeholder to stream into.

    If ``parent_id`` is omitted it defaults to the conversation's current
    leaf, so the common case of "append a question" needs no parent id at
    all. An optional image, given as a base64 data URL, is validated and
    written to disk; only the server-generated filename is stored.

    The assistant placeholder is created with ``is_complete=False`` so the
    client can show a loading state until the stream finishes. The
    conversation's ``current_leaf_id`` is moved to the placeholder so the
    path immediately reflects the new turn.
    """
    conversation = await session.get(Conversation, conversation_id)
    if conversation is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "conversation not found")
    parent_id = body.parent_id if body.parent_id is not None else conversation.current_leaf_id
    if parent_id is not None:
        parent = await _load_message(session, conversation_id, parent_id)
        if parent.role == "user":
            # Two consecutive user messages break Anthropic's alternation
            # rule; reject early so the client gets a clear error.
            raise HTTPException(
                status.HTTP_400_BAD_REQUEST,
                "parent message must be an assistant or root; consecutive user "
                "messages are not allowed",
            )
    image_path: str | None = None
    if body.image_data:
        try:
            image_path = await save_image(body.image_data, settings)
        except ImageError as exc:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, str(exc))
    user_message = Message(
        conversation_id=conversation_id,
        parent_id=parent_id,
        role="user",
        content=body.text,
        image_path=image_path,
    )
    session.add(user_message)
    await session.flush()
    assistant_placeholder = Message(
        conversation_id=conversation_id,
        parent_id=user_message.id,
        role="assistant",
        content="",
        is_complete=False,
    )
    session.add(assistant_placeholder)
    await session.flush()
    conversation.current_leaf_id = assistant_placeholder.id
    conversation.updated_at = datetime.now(timezone.utc)
    session.add(conversation)
    await session.commit()
    await session.refresh(user_message)
    await session.refresh(assistant_placeholder)
    return SendMessageResponse(
        user_message=_to_message_read(user_message),
        assistant_message=_to_message_read(assistant_placeholder),
    )


@router.post(
    "/conversations/{conversation_id}/messages/{parent_id}/regenerate",
    response_model=MessageRead,
    status_code=status.HTTP_201_CREATED,
)
async def regenerate_assistant(
    conversation_id: int,
    parent_id: int,
    session=Depends(get_session),
) -> MessageRead:
    """Create a new assistant placeholder as a sibling reply to an existing
    assistant message's parent.

    The client points ``parent_id`` at the user message whose assistant reply
    it wants re-generated. A new placeholder is added under that parent and
    becomes the current leaf, so the streamed reply replaces the visible
    one without deleting the old version.
    """
    conversation = await session.get(Conversation, conversation_id)
    if conversation is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "conversation not found")
    parent = await _load_message(session, conversation_id, parent_id)
    if parent.role != "user":
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "can only regenerate an assistant reply to a user message",
        )
    placeholder = Message(
        conversation_id=conversation_id,
        parent_id=parent_id,
        role="assistant",
        content="",
        is_complete=False,
    )
    session.add(placeholder)
    await session.flush()
    conversation.current_leaf_id = placeholder.id
    conversation.updated_at = datetime.now(timezone.utc)
    session.add(conversation)
    await session.commit()
    await session.refresh(placeholder)
    return _to_message_read(placeholder)


@router.post(
    "/conversations/{conversation_id}/messages/{leaf_id}/switch",
    response_model=ConversationPath,
)
async def switch_leaf(
    conversation_id: int,
    leaf_id: int,
    session=Depends(get_session),
) -> ConversationPath:
    """Move the conversation's visible path to end at ``leaf_id``.

    ``leaf_id`` must be a message in the conversation. After the switch the
    returned path reflects the new visible branch.
    """
    conversation = await session.get(Conversation, conversation_id)
    if conversation is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "conversation not found")
    target = await _load_message(session, conversation_id, leaf_id)
    conversation.current_leaf_id = target.id
    conversation.updated_at = datetime.now(timezone.utc)
    session.add(conversation)
    await session.commit()
    await session.refresh(conversation)
    chain = await _path_from_leaf(session, conversation)
    nodes = []
    for message in chain:
        siblings = await _siblings_of(session, message)
        nodes.append(MessageTreeNode(message=_to_message_read(message), siblings=siblings))
    return ConversationPath(conversation=conversation, path=nodes)


@router.delete(
    "/conversations/{conversation_id}/messages/{message_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def delete_message(
    conversation_id: int,
    message_id: int,
    session=Depends(get_session),
) -> None:
    """Delete a message and its subtree.

    If the conversation's current leaf is inside the deleted subtree, the
    leaf is moved up to the deleted message's parent so the path still ends
    at a valid node. The ``ON DELETE CASCADE`` on ``parent_id`` removes
    descendants at the database level.
    """
    conversation = await session.get(Conversation, conversation_id)
    if conversation is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "conversation not found")
    message = await _load_message(session, conversation_id, message_id)
    # Detect whether the visible path passes through the doomed message.
    path_ids: set[int] = set()
    current_id = conversation.current_leaf_id
    while current_id is not None:
        if current_id in path_ids:
            break
        path_ids.add(current_id)
        node = await session.get(Message, current_id)
        if node is None:
            break
        if node.id == message_id:
            # The deleted message is on the path; reparent the leaf to the
            # deleted message's parent so the path still resolves.
            conversation.current_leaf_id = message.parent_id
            session.add(conversation)
            break
        current_id = node.parent_id
    await session.delete(message)
    await session.commit()
