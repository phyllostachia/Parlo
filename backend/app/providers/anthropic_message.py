"""Anthropic Messages API 的 adapter。

Messages API 是 Anthropic 的 native protocol（决策 D12）。Endpoint 为
``<base_url>/v1/messages``；这里追加 ``/v1``，使 ``config.yaml`` 中的 ``base_url``
遵循 Anthropic SDK 只填写不带 version 的 host 的约定（例如 ``https://api.anthropic.com``
或 ``https://api.ofox.io/anthropic``）。

Request shape 如下：

* ``model`` — model id。
* ``max_tokens`` — output token 的 required upper bound。
* ``system`` — top-level 的可选 system prompt string（不在 ``messages`` 中）。
* ``messages`` — 交替排列的 ``user``/``assistant`` entry。每个 ``content`` 都是 typed
    block array：``text``、``image``（base64 source）或 ``thinking``（带有用于 replay 的
    ``signature``）。
* ``stream`` — 设置为 ``true`` 以启用 SSE token streaming。

需要关注的 streaming event：

* ``content_block_start`` — 打开一个 block；``content_block.type`` 是 ``"text"`` 或
    ``"thinking"``。thinking block 可能携带初始 ``signature``。
* ``content_block_delta`` — 携带一个 ``delta``，其 ``type`` 可以是 ``text_delta``、
    ``thinking_delta`` 或 ``signature_delta``。
* ``content_block_stop`` — 关闭一个 block；thinking block 的最终 signature 会作为统一
    的 ``reasoning_signature`` event 发出。
* ``message_stop`` — stream 正常结束。
* ``error`` — 上游 error。

Reasoning replay 很重要，因为 Anthropic 要求在后续 request 将 assistant turn 作为 history
发回时，同时回显带有原始 signature 的 thinking block。缺少它时，API 会拒绝 continuation。
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
"""Anthropic 要求每个 request 携带的 API version header。"""


class AnthropicMessageProvider:
    """Anthropic Messages API 的 streaming adapter。"""

    def __init__(self, model: ModelConfig, settings: Settings) -> None:
        self._model = model
        self._settings = settings
        self._client = httpx.AsyncClient(timeout=httpx.Timeout(60.0, read=None))
        self._current_block_type: str | None = None
        self._thinking_buffer: str = ""
        self._signature_buffer: str = ""

    async def stream(self, request: ChatRequest) -> AsyncIterator[StreamEvent]:
        """将 :class:`ChatRequest` 转换为 Messages API call，并生成统一的 :class:`StreamEvent`。"""
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
        """将统一的 message list 转换为 Messages API payload。

        System message 会移动到 top-level ``system`` string。同时具有 ``reasoning`` 和
        ``reasoning_signature`` 的 assistant turn 会生成 thinking block，使 conversation
        能够继续；否则只生成 text block。

        backend 根据 conversation 的深度思考开关解析出的 effort 会设置到
        ``thinking.type: "adaptive"``；始终设置 ``display: "summarized"``，使客户端能看到
        reasoning summary（决策 D06；否则较新的 Anthropic model 默认使用 ``omitted``）。
        ``max_tokens`` 限制 thinking + visible output（决策 D08），替代旧的 hardcoded 8192。
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
        """返回单条 message 的 typed content block。"""
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
        """将一个上游 SSE event 映射为零个或多个统一 event。

        函数跟踪当前 block type，使 delta 被路由到正确的 stream，并从
        ``content_block_start`` 和 ``signature_delta`` event 累积 thinking-block signature，
        以便稍后 replay。
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
    """尽力从 error body 中提取可读的 message。"""
    try:
        parsed = json.loads(body)
    except json.JSONDecodeError:
        return body.decode("utf-8", errors="replace")[:500]
    if isinstance(parsed, dict):
        error = parsed.get("error")
        if isinstance(error, dict) and "message" in error:
            return str(error["message"])
    return str(parsed)[:500]
