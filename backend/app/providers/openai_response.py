"""Adapter for the OpenAI Responses API.

The Responses API replaces the older Chat Completions protocol for new OpenAI
models (decision D12). Its request shape is:

* ``model`` — the model id.
* ``instructions`` — an optional system prompt string.
* ``input`` — an array of message items, each with a ``role`` and a ``content``
  array whose item types distinguish user input (``input_text``,
  ``input_image``) from assistant output (``output_text``).
* ``stream`` — set to ``true`` for SSE token streaming.

Streaming events of interest (every event also carries a ``type`` field that
mirrors the ``event:`` name):

* ``response.output_text.delta`` — a visible-text chunk; payload
  ``{"delta": "..."}``.
* ``response.reasoning_summary_text.delta`` and other ``response.reasoning*``
  delta events — a reasoning-text chunk; same payload shape.
* ``response.completed`` — clean end of stream.
* ``response.failed`` — upstream error with an ``error`` object.

Unknown event types are ignored so the adapter keeps working when OpenAI adds
new intermediate events.
"""

from __future__ import annotations

import json
from collections.abc import AsyncIterator
from typing import Any

import httpx

from ..config import ModelConfig, Settings
from ..storage import read_image_base64
from .base import ChatMessage, ChatRequest, Provider, StreamEvent, parse_sse_stream


class OpenAIResponseProvider:
    """Streaming adapter for the OpenAI Responses API."""

    def __init__(self, model: ModelConfig, settings: Settings) -> None:
        self._model = model
        self._settings = settings
        self._client = httpx.AsyncClient(timeout=httpx.Timeout(60.0, read=None))

    async def stream(self, request: ChatRequest) -> AsyncIterator[StreamEvent]:
        """Translate :class:`ChatRequest` into a Responses API call and yield
        unified :class:`StreamEvent` objects."""
        body = await self._build_body(request)
        url = f"{self._model.base_url}/responses"
        headers = {
            "Authorization": f"Bearer {self._model.resolve_api_key()}",
            "Content-Type": "application/json",
            "Accept": "text/event-stream",
        }
        try:
            async with self._client.stream(
                "POST", url, json=body, headers=headers
            ) as response:
                if response.status_code >= 400:
                    text = await response.aread()
                    yield StreamEvent(kind="error", content=_extract_error(text))
                    return
                async for event_type, data in parse_sse_stream(response):
                    async for evt in self._translate_event(event_type, data):
                        yield evt
        except httpx.HTTPError as exc:
            yield StreamEvent(kind="error", content=f"upstream transport error: {exc}")

    async def _build_body(self, request: ChatRequest) -> dict[str, Any]:
        """Convert the unified message list into the Responses API payload.

        System messages are folded into ``instructions`` (the Responses API
        does not accept a ``system`` role inside ``input``). Assistant turns
        are emitted as ``output_text`` items; OpenAI reasoning is not replayed
        from history, so ``reasoning`` on history messages is ignored.

        ``reasoning.effort`` is set when the conversation selected a thinking
        level; ``max_output_tokens`` caps thinking + visible output (decision
        D08). The Responses API applies reasoning adaptively within the
        chosen effort level.
        """
        instructions_parts: list[str] = []
        input_items: list[dict[str, Any]] = []
        for message in request.messages:
            if message.role == "system":
                if message.text:
                    instructions_parts.append(message.text)
                continue
            content: list[dict[str, Any]] = []
            if message.text:
                kind = "input_text" if message.role == "user" else "output_text"
                content.append({"type": kind, "text": message.text})
            if message.image_path:
                data_url = await self._image_data_url(message.image_path)
                content.append({"type": "input_image", "image_url": data_url})
            if not content:
                continue
            input_items.append({"type": "message", "role": message.role, "content": content})
        body: dict[str, Any] = {
            "model": request.model,
            "input": input_items,
            "stream": True,
            "max_output_tokens": self._model.max_tokens,
        }
        if request.thinking_effort:
            body["reasoning"] = {"effort": request.thinking_effort}
        if instructions_parts:
            body["instructions"] = "\n\n".join(instructions_parts)
        return body

    async def _image_data_url(self, filename: str) -> str:
        """Return a ``data:<media>;base64,<...>`` URL for a stored image."""
        media_type, encoded = await read_image_base64(self._settings, filename)
        return f"data:{media_type};base64,{encoded}"

    async def _translate_event(
        self, event_type: str, data: dict[str, Any]
    ) -> AsyncIterator[StreamEvent]:
        """Map one upstream SSE event onto zero or more unified events."""
        if event_type == "response.output_text.delta":
            yield StreamEvent(kind="text_delta", content=str(data.get("delta", "")))
            return
        if "reasoning" in event_type and event_type.endswith(".delta"):
            yield StreamEvent(kind="reasoning_delta", content=str(data.get("delta", "")))
            return
        if event_type == "response.completed":
            yield StreamEvent(kind="done")
            return
        if event_type in ("response.failed", "error", "response.error"):
            yield StreamEvent(kind="error", content=str(data.get("error", {}).get("message", event_type)))
            return


def _extract_error(body: bytes) -> str:
    """Best-effort extraction of a human-readable message from an error body."""
    try:
        parsed = json.loads(body)
    except json.JSONDecodeError:
        return body.decode("utf-8", errors="replace")[:500]
    if isinstance(parsed, dict):
        error = parsed.get("error")
        if isinstance(error, dict) and "message" in error:
            return str(error["message"])
    return str(parsed)[:500]
