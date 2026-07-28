"""消息树 endpoint。

消息会在会话中组成一棵树（决策 D18）。这些 endpoint 负责创建 user message、重新生成
assistant reply、在 sibling reply 之间切换可见路径、带 sibling metadata 列出可见路径，
以及删除 subtree。所有 endpoint 都要求共享 bearer token。

实际的 streaming 位于 :mod:`app.api.chat`；这些 endpoint 只创建 stream 要写入的 message，
因此 write path 保持简单，并且无需 live upstream provider 就能测试。
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
    """将 :class:`Message` row 转换为面向客户端的 read model。"""
    return MessageRead(
        id=message.id,
        conversation_id=message.conversation_id,
        parent_id=message.parent_id,
        role=message.role,
        content=message.content,
        reasoning=message.reasoning,
        reasoning_duration_ms=message.reasoning_duration_ms,
        image_url=image_url_for(message.image_path),
        is_complete=message.is_complete,
        created_at=message.created_at,
    )


async def _load_message(session, conversation_id: int, message_id: int) -> Message:
    """获取 message，并确认它属于给定的 conversation。"""
    message = await session.get(Message, message_id)
    if message is None or message.conversation_id != conversation_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "message not found")
    return message


async def _path_from_leaf(session, conversation: Conversation) -> list[Message]:
    """从当前 leaf 沿 ``parent_id`` 回溯到 root。

    返回 root-to-leaf 顺序的 message。空列表表示 conversation 还没有 message。
    """
    if conversation.current_leaf_id is None:
        return []
    chain: list[Message] = []
    current_id = conversation.current_leaf_id
    seen: set[int] = set()
    while current_id is not None:
        if current_id in seen:
            # 防御性处理：cycle 会使循环卡住，因此重复时退出。
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
    """查找与 ``message`` 共享 parent 的所有 message，包括它自身。

    active sibling 就是 ``message``；客户端使用 ``siblings`` 渲染 ``< n / m >`` switcher。
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
    """返回带有每个 node 的 sibling metadata 的可见 message path。"""
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
    """创建 user message 和用于 streaming 的 assistant placeholder。

    如果省略 ``parent_id``，它默认为 conversation 的 current leaf，因此常见的“追加问题”
    不需要 parent id。可选图片以 base64 data URL 提供，经过校验后写入磁盘，数据库只保存
    服务器生成的 filename。

    assistant placeholder 的 ``is_complete=False`` 让客户端可以在 stream 完成前显示
    loading state。conversation 的 ``current_leaf_id`` 会移动到 placeholder，使 path
    立即反映新的 turn。
    """
    conversation = await session.get(Conversation, conversation_id)
    if conversation is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "conversation not found")
    parent_id = body.parent_id if body.parent_id is not None else conversation.current_leaf_id
    if parent_id is not None:
        parent = await _load_message(session, conversation_id, parent_id)
        if parent.role == "user":
            # 连续的两个 user message 会违反 Anthropic 的 alternation rule；提前拒绝，
            # 让客户端获得清晰的错误。
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
    """在已有 assistant message 的 parent 下创建一个 sibling reply 的 assistant placeholder。

    客户端将 ``parent_id`` 指向要重新生成 assistant reply 的 user message。新 placeholder
    会添加到该 parent 下并成为 current leaf，因此 streamed reply 会替换可见版本，而不会
    删除旧版本。
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
    """将 conversation 的可见 path 移动到以 ``leaf_id`` 结尾。

    ``leaf_id`` 必须是该 conversation 中的 message。切换后，返回的 path 会反映新的可见 branch。
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
    """删除 message 及其 subtree。

    如果 conversation 的 current leaf 位于被删除的 subtree 中，leaf 会上移到被删除
    message 的 parent，使 path 仍然以有效 node 结尾。``parent_id`` 上的 ``ON DELETE
    CASCADE`` 会在 database level 删除 descendants。
    """
    conversation = await session.get(Conversation, conversation_id)
    if conversation is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "conversation not found")
    message = await _load_message(session, conversation_id, message_id)
    # 检查可见 path 是否经过待删除的 message。
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
            # 被删除的 message 位于 path 上；将 leaf 重新挂到被删除 message 的 parent，
            # 使 path 仍能解析。
            conversation.current_leaf_id = message.parent_id
            session.add(conversation)
            break
        current_id = node.parent_id
    await session.delete(message)
    await session.commit()
