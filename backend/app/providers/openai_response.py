"""OpenAI Responses API 的 adapter。

Responses API 替代了新 OpenAI model 使用的旧 Chat Completions protocol（决策 D12）。
Request shape 如下：

* ``model`` — model id。
* ``instructions`` — 可选的 system prompt string。
* ``input`` — message item array。每个 item 有 ``role`` 和 ``content`` array，其 item
    type 区分 user input（``input_text``、``input_image``）与 assistant output（``output_text``）。
* ``stream`` — 设置为 ``true`` 以启用 SSE token streaming。

需要关注的 streaming event（每个 event 也携带一个与 ``event:`` name 对应的 ``type`` field）：

* ``response.output_text.delta`` — 一段 visible text；payload 为 ``{"delta": "..."}``。
* ``response.reasoning_summary_text.delta`` 及其他 ``response.reasoning*`` delta event
    — 一段 reasoning text；payload shape 相同。
* ``response.completed`` — stream 正常结束。
* ``response.failed`` — 带有 ``error`` object 的上游 error。

未知 event type 会被忽略，使 adapter 在 OpenAI 添加新的 intermediate event 后仍能继续工作。
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
    """OpenAI Responses API 的 streaming adapter。"""

    def __init__(self, model: ModelConfig, settings: Settings) -> None:
        self._model = model
        self._settings = settings
        self._client = httpx.AsyncClient(timeout=httpx.Timeout(60.0, read=None))

    async def stream(self, request: ChatRequest) -> AsyncIterator[StreamEvent]:
        """将 :class:`ChatRequest` 转换为 Responses API call，并生成统一的 :class:`StreamEvent`。"""
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
        """将统一的 message list 转换为 Responses API payload。

        System message 会合并到 ``instructions``（Responses API 不接受 ``input`` 内的
        ``system`` role）。Assistant turn 会作为 ``output_text`` item 发送；OpenAI reasoning
        不会从 history replay，因此会忽略 history message 上的 ``reasoning``。

        backend 根据 conversation 的深度思考开关解析出的 effort 会设置为
        ``reasoning.effort``；
        ``max_output_tokens`` 限制 thinking + visible output（决策 D08）。Responses API 会
        在选择的 effort level 内自适应处理 reasoning。
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
        """为已存储的图片返回 ``data:<media>;base64,<...>`` URL。"""
        media_type, encoded = await read_image_base64(self._settings, filename)
        return f"data:{media_type};base64,{encoded}"

    async def _translate_event(
        self, event_type: str, data: dict[str, Any]
    ) -> AsyncIterator[StreamEvent]:
        """将一个上游 SSE event 映射为零个或多个统一 event。"""
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
