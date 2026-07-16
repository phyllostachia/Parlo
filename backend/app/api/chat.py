"""Server-Sent Events streaming endpoint.

The single endpoint ``GET /api/chat/stream`` drives one assistant reply to
completion. The client first creates a user message (and an assistant
placeholder) via the messages endpoint, then opens this SSE connection
pointing at the placeholder. The server reconstructs the conversation history
by walking the placeholder's ancestors, calls the selected provider, and
yields each unified token event to the client as an SSE event while writing
the accumulated content into the placeholder row.

SSE was chosen over WebSocket (decision D11) because the stream is
one-directional: the server pushes tokens, and cancellation is handled by
the client simply closing the connection. The auth dependency accepts the
shared token as a ``token`` query parameter because browser ``EventSource``
cannot set custom headers.
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
    """Format one SSE event as the wire text the client reads."""
    return f"event: {event}\ndata: {json.dumps(data)}\n\n"


async def _build_history(session, assistant_message: Message) -> list[ChatMessage]:
    """Collect the ancestor messages of ``assistant_message`` as the request.

    Walks ``parent_id`` from the assistant placeholder's parent to the root,
    reverses to root-first order, and maps each row to a :class:`ChatMessage`
    carrying text, image, and any reasoning + signature for replay.
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
    """Yield SSE text for one assistant completion.

    The function owns its own database session (not the request's) so a
    long stream does not hold a request-scoped connection from the pool. A
    ``finally`` block persists whatever content arrived, so a client
    disconnect mid-stream still leaves a recoverable, partial message rather
    than an empty placeholder.
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
        request = ChatRequest(
            messages=history,
            model=model.id,
            thinking_effort=conversation.thinking_effort,
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
        except Exception as exc:  # surface unexpected adapter failures to the client
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
    """Stream tokens for the given assistant placeholder as SSE.

    The response uses ``text/event-stream`` and disables proxy buffering
    hints so intermediate reverse proxies forward chunks immediately. Auth
    is enforced by the router-level dependency (token accepted as a query
    parameter for browser ``EventSource`` compatibility).
    """
    return StreamingResponse(
        _event_generator(message_id, settings),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "X-Accel-Buffering": "no",
        },
    )
