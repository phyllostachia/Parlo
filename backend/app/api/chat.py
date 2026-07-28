"""Server-Sent Events 流式 endpoint。

唯一的 endpoint ``GET /api/chat/stream`` 会驱动一条 assistant 回复直到完成。客户端先
通过 messages endpoint 创建 user 消息和 assistant 占位消息，再连接指向该占位消息的
SSE。服务器沿占位消息的祖先节点回溯并重建会话历史，调用选定的 provider，同时将每个
统一 token event 作为 SSE event 发送给客户端，并把累计内容写入占位消息记录。

根据决策 D11，这里选择 SSE 而不是 WebSocket，因为该 stream 是单向的：服务器推送
token，客户端只需关闭连接即可取消。由于浏览器的 ``EventSource`` 无法设置 custom
header，auth dependency 接受 ``token`` query parameter 中的共享 token。
"""

from __future__ import annotations

import json
from collections.abc import AsyncIterator
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, status
from fastapi.responses import StreamingResponse
from sqlmodel import select

from ..auth import verify_token
from ..config import Settings, get_settings
from ..db import async_session_maker
from ..models import Conversation, Message
from ..providers.base import ChatMessage, ChatRequest, Provider, get_provider

router = APIRouter(prefix="/chat", dependencies=[Depends(verify_token)])


def _sse(event: str, data: dict) -> str:
    """将一个 SSE event 格式化为客户端读取的 wire text。"""
    return f"event: {event}\ndata: {json.dumps(data)}\n\n"


async def _build_history(session, assistant_message: Message) -> list[ChatMessage]:
    """收集 ``assistant_message`` 的祖先消息并组成请求历史。

    从 assistant 占位消息的 parent 沿 ``parent_id`` 走到根节点，再反转为从根到叶的
    顺序，并将每条记录映射为包含 text、image 以及可 replay 的 reasoning 和 signature
    的 :class:`ChatMessage`。
    """
    chain: list[Message] = []
    current_id = assistant_message.parent_id
    seen: set[int] = set()
    while current_id is not None:
        if current_id in seen:
            break
        seen.add(current_id)
        node = await session.get(Message, current_id)
        if node is None:
            break
        chain.append(node)
        current_id = node.parent_id
    chain.reverse()
    return [
        ChatMessage(
            role=node.role,
            text=node.content or None,
            image_path=node.image_path,
            reasoning=node.reasoning,
            reasoning_signature=node.reasoning_signature,
        )
        for node in chain
    ]


async def _event_generator(message_id: int, settings: Settings) -> AsyncIterator[str]:
    """为一条 assistant completion 生成 SSE text。

    函数使用独立的 database session，而不是 request session，因此长 stream 不会一直
    占用连接池中的 request-scoped connection。``finally`` block 会持久化已经收到的
    内容，所以客户端在 stream 中途断开后仍会留下可恢复的 partial message，而不是空的
    占位消息。
    """
    async with async_session_maker() as session:
        message = await session.get(Message, message_id)
        if message is None or message.role != "assistant":
            yield _sse("error", {"message": "message not found or not an assistant message"})
            return
        conversation = await session.get(Conversation, message.conversation_id)
        if conversation is None:
            yield _sse("error", {"message": "conversation not found"})
            return
        history = await _build_history(session, message)
        model = settings.app_config.get_model(conversation.model_id)
        if model is None:
            yield _sse(
                "error",
                {
                    "message": (
                        f"model {conversation.model_id!r} is no longer "
                        "available; ask the operator to restore it in "
                        "config.yaml or use a different conversation"
                    )
                },
            )
            return
        thinking_effort = (
            model.thinking_on_effort
            if conversation.thinking_enabled
            else model.thinking_off_effort
        )
        request = ChatRequest(
            messages=history,
            model=model.id,
            thinking_effort=thinking_effort,
        )
        provider = get_provider(model, settings)
        content_buffer = ""
        reasoning_buffer = ""
        signature: str | None = None
        finished_cleanly = False
        yield _sse("started", {"message_id": message_id})
        try:
            async for event in provider.stream(request):
                if event.kind == "text_delta":
                    content_buffer += event.content
                    yield _sse("text_delta", {"content": event.content})
                elif event.kind == "reasoning_delta":
                    reasoning_buffer += event.content
                    yield _sse("reasoning_delta", {"content": event.content})
                elif event.kind == "reasoning_signature":
                    signature = event.content
                    yield _sse("reasoning_signature", {"content": event.content})
                elif event.kind == "error":
                    yield _sse("error", {"message": event.content})
                    break
                elif event.kind == "done":
                    finished_cleanly = True
                    yield _sse("done", {})
                    break
        except Exception as exc:  # 将未预期的 adapter failure 返回给客户端
            yield _sse("error", {"message": f"stream failed: {exc}"})
        finally:
            message.content = content_buffer
            message.reasoning = reasoning_buffer or None
            message.reasoning_signature = signature
            message.is_complete = True
            conversation.updated_at = datetime.now(timezone.utc)
            if finished_cleanly:
                conversation.current_leaf_id = message.id
            session.add(message)
            session.add(conversation)
            await session.commit()


@router.get("/stream")
async def stream_chat(
    message_id: int = Query(..., description="Assistant placeholder message id to stream into"),
    settings: Settings = Depends(get_settings),
) -> StreamingResponse:
    """将给定 assistant 占位消息的 token 作为 SSE stream 发送。

    响应使用 ``text/event-stream``，并通过关闭 proxy buffering 的提示，让中间 reverse
    proxy 立即转发 chunk。鉴权由 router-level dependency 执行；为兼容浏览器
    ``EventSource``，token 也接受 query parameter 形式。
    """
    return StreamingResponse(
        _event_generator(message_id, settings),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "X-Accel-Buffering": "no",
        },
    )
