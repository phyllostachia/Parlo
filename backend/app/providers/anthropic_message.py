"""Adapter for the Anthropic Messages API.

The Messages API is Anthropic's native protocol (decision D12). The endpoint
is ``<base_url>/v1/messages`` — the ``/v1`` segment is appended here so the
``base_url`` in ``config.yaml`` follows the Anthropic SDK convention of
naming the host without the version (for example
``https://api.anthropic.com`` or ``https://api.ofox.io/anthropic``).

Its request shape:

* ``model`` — the model id.
* ``max_tokens`` — required upper bound on output tokens.
* ``system`` — optional system prompt string at the top level (not inside
  ``messages``).
* ``messages`` — alternating ``user``/``assistant`` entries. Each ``content``
  is an array of typed blocks: ``text``, ``image`` (base64 source), or
  ``thinking`` (with a ``signature`` for replay).
* ``stream`` — set to ``true`` for SSE token streaming.

Streaming events of interest:

* ``content_block_start`` — opens a block; ``content_block.type`` is
  ``"text"`` or ``"thinking"``. The thinking block may carry an initial
  ``signature``.
* ``content_block_delta`` — carries a ``delta`` whose ``type`` is
  ``text_delta``, ``thinking_delta``, or ``signature_delta``.
* ``content_block_stop`` — closes a block; the thinking block's final
  signature is emitted as a unified ``reasoning_signature`` event.
* ``message_stop`` — clean end of stream.
* ``error`` — upstream error.

Reasoning replay matters because Anthropic requires a thinking block to be
echoed back, with its original signature, when the assistant turn is sent as
history in a later request. Without it the API rejects the continuation.
"""

from __future__ import annotations

import json
from collections.abc import AsyncIterator
from typing import Any

import httpx

from ..config import ModelConfig, Settings
from ..storage import read_image_base64
from .base import ChatMessage, ChatRequest, Provider, StreamEvent, parse_sse_stream

ANTHROPIC_VERSION = "2023-06-01"
"""API version header required by Anthropic on every request."""


class AnthropicMessageProvider:
    """Streaming adapter for the Anthropic Messages API."""

    def __init__(self, model: ModelConfig, settings: Settings) -> None:
        self._model = model
        self._settings = settings
        self._client = httpx.AsyncClient(timeout=httpx.Timeout(60.0, read=None))
        self._current_block_type: str | None = None
        self._thinking_buffer: str = ""
        self._signature_buffer: str = ""

    async def stream(self, request: ChatRequest) -> AsyncIterator[StreamEvent]:
        """Translate :class:`ChatRequest` into a Messages API call and yield
        unified :class:`StreamEvent` objects."""
        self._current_block_type = None
        self._thinking_buffer = ""
        self._signature_buffer = ""
        body = await self._build_body(request)
        url = f"{self._model.base_url}/v1/messages"
        headers = {
            "x-api-key": self._model.resolve_api_key(),
            "anthropic-version": ANTHROPIC_VERSION,
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
        """Convert the unified message list into the Messages API payload.

        System messages move to the top-level ``system`` string. Assistant
        turns with both ``reasoning`` and ``reasoning_signature`` emit a
        thinking block so the conversation can be continued; otherwise only
        the text block is emitted.

        ``thinking.type: "adaptive"`` is set with the selected effort level
        when the conversation requested thinking; ``display: "summarized"`` is
        always set so the client sees the reasoning summary (decision D06;
        newer Anthropic models default to ``omitted`` otherwise). ``max_tokens``
        caps thinking + visible output (decision D08) and replaces the old
        hardcoded 8192.
        """
        system_parts: list[str] = []
        messages: list[dict[str, Any]] = []
        for message in request.messages:
            if message.role == "system":
                if message.text:
                    system_parts.append(message.text)
                continue
            content = await self._build_content(message)
            if not content:
                continue
            messages.append({"role": message.role, "content": content})
        body: dict[str, Any] = {
            "model": request.model,
            "max_tokens": self._model.max_tokens,
            "messages": messages,
            "stream": True,
        }
        if request.thinking_effort:
            body["thinking"] = {
                "type": "adaptive",
                "effort": request.thinking_effort,
                "display": "summarized",
            }
        if system_parts:
            body["system"] = "\n\n".join(system_parts)
        return body

    async def _build_content(self, message: ChatMessage) -> list[dict[str, Any]]:
        """Return the typed content blocks for a single message."""
        blocks: list[dict[str, Any]] = []
        if message.role == "assistant":
            if message.reasoning and message.reasoning_signature:
                blocks.append(
                    {
                        "type": "thinking",
                        "thinking": message.reasoning,
                        "signature": message.reasoning_signature,
                    }
                )
            if message.text:
                blocks.append({"type": "text", "text": message.text})
            return blocks
        # user message
        if message.text:
            blocks.append({"type": "text", "text": message.text})
        if message.image_path:
            media_type, encoded = await read_image_base64(self._settings, message.image_path)
            blocks.append(
                {
                    "type": "image",
                    "source": {
                        "type": "base64",
                        "media_type": media_type,
                        "data": encoded,
                    },
                }
            )
        return blocks

    async def _translate_event(
        self, event_type: str, data: dict[str, Any]
    ) -> AsyncIterator[StreamEvent]:
        """Map one upstream SSE event onto zero or more unified events.

        Tracks the current block type so deltas are routed to the right
        stream, and accumulates the thinking-block signature from both
        ``content_block_start`` and ``signature_delta`` events so it can be
        replayed later.
        """
        if event_type == "content_block_start":
            block = data.get("content_block", {})
            self._current_block_type = block.get("type")
            if self._current_block_type == "thinking":
                self._thinking_buffer = ""
                self._signature_buffer = str(block.get("signature", ""))
            return
        if event_type == "content_block_delta":
            delta = data.get("delta", {})
            delta_type = delta.get("type")
            if delta_type == "text_delta":
                yield StreamEvent(kind="text_delta", content=str(delta.get("text", "")))
                return
            if delta_type == "thinking_delta":
                chunk = str(delta.get("thinking", ""))
                self._thinking_buffer += chunk
                yield StreamEvent(kind="reasoning_delta", content=chunk)
                return
            if delta_type == "signature_delta":
                self._signature_buffer += str(delta.get("signature", ""))
                return
            return
        if event_type == "content_block_stop":
            if self._current_block_type == "thinking" and self._signature_buffer:
                yield StreamEvent(kind="reasoning_signature", content=self._signature_buffer)
            self._current_block_type = None
            return
        if event_type == "message_stop":
            yield StreamEvent(kind="done")
            return
        if event_type == "error":
            error = data.get("error", {})
            yield StreamEvent(
                kind="error",
                content=str(error.get("message", error.get("type", "upstream error"))),
            )
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
