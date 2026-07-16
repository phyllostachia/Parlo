"""Provider abstraction layer.

The application talks to upstream model providers only through the
:class:`Provider` protocol and the small set of data structures defined here.
This keeps the rest of the codebase protocol-agnostic; supporting a new
provider means adding a module that implements :class:`Provider`.

Decision D12 fixed the supported protocols at two: the OpenAI Responses API
and the Anthropic Messages API. Decision D13 ruled out agent workflows, so
the abstraction only needs to model "messages in, tokens out" — there is no
tool-call surface, no multi-turn orchestration state, and no retry policy.

Images and thinking history are carried on :class:`ChatMessage` so each
adapter can translate them into its own wire format. The Anthropic adapter
uses ``reasoning_signature`` to replay a previous thinking block; the OpenAI
adapter ignores it.
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
"""The event kinds the unified stream emits.

* ``text_delta`` — a chunk of assistant visible text.
* ``reasoning_delta`` — a chunk of reasoning/thinking text (displayed folded).
* ``reasoning_signature`` — the full signature needed to replay a thinking
  block as history in a later turn (Anthropic only; emitted once per thinking
  block, in ``content``).
* ``done`` — the upstream finished cleanly; no payload.
* ``error`` — the upstream or adapter failed; ``content`` carries the message.
"""


@dataclass
class ChatMessage:
    """A single message in the request history.

    Exactly one of ``text`` or ``image_path`` is normally set for a user
    message; an assistant message has ``text`` and may have ``reasoning``.
    """

    role: Literal["user", "assistant", "system"]
    text: str | None = None
    image_path: str | None = None
    """Server-generated filename of an attached image, if any."""
    reasoning: str | None = None
    """Reasoning/thinking text produced by the model for this assistant turn."""
    reasoning_signature: str | None = None
    """Anthropic thinking-block signature, used only to replay the block."""


@dataclass
class ChatRequest:
    """A request to stream a completion for the given message history.

    ``thinking_effort`` is the level selected for the conversation (one of the
    model's listed levels). It is forwarded to the upstream as
    ``reasoning.effort`` (OpenAI) or ``thinking.effort`` (Anthropic adaptive);
    an empty string means the adapter should send no thinking parameter.
    """

    messages: list[ChatMessage] = field(default_factory=list)
    model: str = ""
    thinking_effort: str = ""


@dataclass
class StreamEvent:
    """One event emitted by a provider's stream."""

    kind: StreamEventKind
    content: str = ""


@runtime_checkable
class Provider(Protocol):
    """A streaming chat-completion adapter for a specific upstream protocol."""

    async def stream(self, request: ChatRequest) -> AsyncIterator[StreamEvent]:
        """Yield :class:`StreamEvent` objects for one completion.

        Implementations are async generators. They must terminate either by
        yielding a ``done`` event or by yielding an ``error`` event, so the
        caller can treat stream end as success or failure unambiguously.
        """
        ...
        yield StreamEvent(kind="done")  # pragma: no cover  (Protocol body)


async def parse_sse_stream(
    response,
) -> AsyncIterator[tuple[str, dict]]:
    """Parse a Server-Sent Events stream into ``(event_type, json_data)`` pairs.

    Accepts both the OpenAI convention (where ``event:`` names the type) and
    streams that omit ``event:`` and rely on a ``type`` field inside the JSON
    payload. Lines that are neither ``event:`` nor ``data:`` (comments, keep
    alives, retry hints) are ignored.
    """
    event_type = ""
    data_parts: list[str] = []
    async for line in response.aiter_lines():
        if line == "":
            # A blank line terminates the current event.
            if data_parts:
                payload = "\n".join(data_parts)
                data_parts = []
                resolved_type = event_type
                try:
                    parsed = json.loads(payload)
                except json.JSONDecodeError:
                    # Skip non-JSON keepalive data; nothing else to recover.
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
    """Construct the provider adapter selected by ``model.protocol``.

    The adapter is bound to a single model (its base URL, resolved API key,
    and output budget all come from :class:`ModelConfig`) but still needs the
    process-wide :class:`Settings` to locate the image upload directory when
    forwarding multimodal messages.

    Imported locally so the base module does not pull in httpx on import,
    which keeps unit tests that only exercise the data structures fast.
    """
    if model.protocol == "openai-response":
        from .openai_response import OpenAIResponseProvider

        return OpenAIResponseProvider(model, settings)
    if model.protocol == "anthropic-message":
        from .anthropic_message import AnthropicMessageProvider

        return AnthropicMessageProvider(model, settings)
    raise ValueError(f"unknown protocol: {model.protocol!r}")
