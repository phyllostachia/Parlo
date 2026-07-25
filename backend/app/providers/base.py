"""Provider abstraction layer。

应用只通过这里定义的 :class:`Provider` protocol 和少量 data structure 与上游 model
provider 通信。这样代码库的其他部分不依赖具体 protocol；支持新 provider 只需要添加
实现 :class:`Provider` 的 module。

决策 D12 将支持的 protocol 固定为两个：OpenAI Responses API 和 Anthropic Messages API。
决策 D13 排除了 agent workflow，因此 abstraction 只需表达“messages in，tokens out”，
不需要 tool-call surface、multi-turn orchestration state 或 retry policy。

图片和 thinking history 都携带在 :class:`ChatMessage` 中，使每个 adapter 可以将它们
转换为自己的 wire format。Anthropic adapter 使用 ``reasoning_signature`` replay 之前的
thinking block；OpenAI adapter 会忽略它。
"""

from __future__ import annotations

import json
from collections.abc import AsyncIterator
from dataclasses import dataclass, field
from typing import Literal, Protocol, runtime_checkable

from ..config import ModelConfig, Settings


StreamEventKind = Literal[
    "text_delta",
    "reasoning_delta",
    "reasoning_signature",
    "done",
    "error",
]
"""统一 stream 发出的 event kind。

* ``text_delta`` — 一段 assistant 可见文本。
* ``reasoning_delta`` — 一段 reasoning/thinking 文本（折叠显示）。
* ``reasoning_signature`` — 后续 turn 将 thinking block 作为 history replay 所需的完整
    signature（仅 Anthropic；每个 thinking block 在 ``content`` 中发送一次）。
* ``done`` — 上游正常完成；没有 payload。
* ``error`` — 上游或 adapter 失败；``content`` 携带错误 message。
"""


@dataclass
class ChatMessage:
    """request history 中的一条 message。

    对 user message，通常只设置 ``text`` 或 ``image_path`` 其中之一；assistant message
    有 ``text``，并且可能有 ``reasoning``。
    """

    role: Literal["user", "assistant", "system"]
    text: str | None = None
    image_path: str | None = None
    """附加图片的 server-generated filename（如果存在）。"""
    reasoning: str | None = None
    """model 为该 assistant turn 生成的 reasoning/thinking text。"""
    reasoning_signature: str | None = None
    """Anthropic thinking-block signature，仅用于 replay 该 block。"""


@dataclass
class ChatRequest:
    """针对给定 message history 请求 streaming completion。

    ``thinking_effort`` 是会话选择的 level（model 列出的 level 之一）。它会以
    ``reasoning.effort``（OpenAI）或 ``thinking.effort``（Anthropic adaptive）的形式
    转发给上游；空 string 表示 adapter 不应发送 thinking parameter。
    """

    messages: list[ChatMessage] = field(default_factory=list)
    model: str = ""
    thinking_effort: str = ""


@dataclass
class StreamEvent:
    """provider stream 发出的一个 event。"""

    kind: StreamEventKind
    content: str = ""


@runtime_checkable
class Provider(Protocol):
    """针对特定上游 protocol 的 streaming chat-completion adapter。"""

    async def stream(self, request: ChatRequest) -> AsyncIterator[StreamEvent]:
        """为一次 completion 生成 :class:`StreamEvent` object。

        实现是 async generator，必须通过生成 ``done`` event 或 ``error`` event 之一结束，
        使调用方能够明确判断 stream 结束是成功还是失败。
        """
        ...
        yield StreamEvent(kind="done")  # pragma: no cover  (Protocol body)


async def parse_sse_stream(
    response,
) -> AsyncIterator[tuple[str, dict]]:
    """将 Server-Sent Events stream 解析为 ``(event_type, json_data)`` pair。

    同时接受 OpenAI convention（由 ``event:`` 命名 type）和省略 ``event:``、依赖 JSON
    payload 中 ``type`` field 的 stream。既不是 ``event:`` 也不是 ``data:`` 的 line
    （comment、keep-alive、retry hint）会被忽略。
    """
    event_type = ""
    data_parts: list[str] = []
    async for line in response.aiter_lines():
        if line == "":
            # 空行表示当前 event 结束。
            if data_parts:
                payload = "\n".join(data_parts)
                data_parts = []
                resolved_type = event_type
                try:
                    parsed = json.loads(payload)
                except json.JSONDecodeError:
                    # 跳过非 JSON keepalive data；没有其他内容可恢复。
                    event_type = ""
                    continue
                if not resolved_type and isinstance(parsed, dict):
                    resolved_type = str(parsed.get("type", ""))
                if resolved_type:
                    yield resolved_type, parsed if isinstance(parsed, dict) else {}
            event_type = ""
            continue
        if line.startswith("event:"):
            event_type = line[len("event:"):].strip()
        elif line.startswith("data:"):
            data_parts.append(line[len("data:"):].strip())


def get_provider(model: ModelConfig, settings: Settings) -> Provider:
    """构建由 ``model.protocol`` 选择的 provider adapter。

    adapter 绑定到单个 model（base URL、resolved API key 和 output budget 都来自
    :class:`ModelConfig`），但仍需要 process-wide :class:`Settings`，以便转发 multimodal
    message 时定位 image upload directory。

    这里采用 local import，使 base module 在 import 时不加载 httpx，从而让只测试 data
    structure 的 unit test 保持快速。
    """
    if model.protocol == "openai-response":
        from .openai_response import OpenAIResponseProvider

        return OpenAIResponseProvider(model, settings)
    if model.protocol == "anthropic-message":
        from .anthropic_message import AnthropicMessageProvider

        return AnthropicMessageProvider(model, settings)
    raise ValueError(f"unknown protocol: {model.protocol!r}")
