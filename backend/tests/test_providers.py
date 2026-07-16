"""Tests for the provider adapters' event translation.

The upstream HTTP layer is mocked with ``respx`` so the tests exercise only the
protocol-to-unified-event mapping without network calls. Each test feeds a
canned SSE response and asserts the adapter yields the expected sequence of
:class:`StreamEvent` objects.

Adapters are constructed from a :class:`ModelConfig` (base URL, protocol,
max_tokens, and the env-var name for the API key) plus the process-wide
:class:`Settings` (which carries the image upload directory). The shared
conftest sets ``OPENAI_API_KEY`` / ``ANTHROPIC_API_KEY`` and a throwaway
``config.yaml``, so the constructed models just have to reference those names.
"""

from __future__ import annotations

import httpx
import respx

from app.config import ModelConfig, Settings, get_settings
from app.providers.anthropic_message import AnthropicMessageProvider
from app.providers.base import ChatMessage, ChatRequest
from app.providers.openai_response import OpenAIResponseProvider


def _openai_model() -> ModelConfig:
    return ModelConfig(
        id="gpt-5.6",
        display_name="GPT-5.6",
        api_key="OPENAI_API_KEY",
        base_url="https://api.openai.com/v1",
        family="openai",
        protocol="openai-response",
        vision=True,
        thinking_effort=["medium", "low", "high", "xhigh"],
        max_tokens=32768,
    )


def _anthropic_model() -> ModelConfig:
    return ModelConfig(
        id="claude-sonnet-5",
        display_name="Claude Sonnet 5",
        api_key="ANTHROPIC_API_KEY",
        base_url="https://api.anthropic.com",
        family="anthropic",
        protocol="anthropic-message",
        vision=True,
        thinking_effort=["high", "medium", "low", "xhigh", "max"],
        max_tokens=16384,
    )


def _settings() -> Settings:
    # Reuse the shared test config so image upload dir etc. are consistent.
    return get_settings()


@respx.mock
async def test_openai_translates_text_and_done() -> None:
    """OpenAI text deltas concatenate and the stream ends with ``done``."""
    sse = (
        'event: response.output_text.delta\n'
        'data: {"type":"response.output_text.delta","delta":"Hello"}\n\n'
        'event: response.output_text.delta\n'
        'data: {"type":"response.output_text.delta","delta":" world"}\n\n'
        'event: response.completed\n'
        'data: {"type":"response.completed"}\n\n'
    )
    respx.post("https://api.openai.com/v1/responses").mock(
        return_value=httpx.Response(
            200, text=sse, headers={"content-type": "text/event-stream"}
        )
    )
    provider = OpenAIResponseProvider(_openai_model(), _settings())
    request = ChatRequest(model="gpt-5.6", messages=[ChatMessage(role="user", text="hi")])
    events = [event async for event in provider.stream(request)]
    text = "".join(e.content for e in events if e.kind == "text_delta")
    assert text == "Hello world"
    assert events[-1].kind == "done"


@respx.mock
async def test_openai_translates_reasoning_delta() -> None:
    """Reasoning delta events are surfaced as ``reasoning_delta``."""
    sse = (
        'event: response.reasoning_summary_text.delta\n'
        'data: {"type":"response.reasoning_summary_text.delta","delta":"thinking"}\n\n'
        'event: response.output_text.delta\n'
        'data: {"type":"response.output_text.delta","delta":"answer"}\n\n'
        'event: response.completed\n'
        'data: {"type":"response.completed"}\n\n'
    )
    respx.post("https://api.openai.com/v1/responses").mock(
        return_value=httpx.Response(
            200, text=sse, headers={"content-type": "text/event-stream"}
        )
    )
    provider = OpenAIResponseProvider(_openai_model(), _settings())
    request = ChatRequest(
        model="gpt-5.6",
        messages=[ChatMessage(role="user", text="hi")],
        thinking_effort="high",
    )
    events = [event async for event in provider.stream(request)]
    reasoning = "".join(e.content for e in events if e.kind == "reasoning_delta")
    assert reasoning == "thinking"
    text = "".join(e.content for e in events if e.kind == "text_delta")
    assert text == "answer"


@respx.mock
async def test_openai_surfaces_upstream_error() -> None:
    """A non-200 response becomes a single ``error`` event."""
    respx.post("https://api.openai.com/v1/responses").mock(
        return_value=httpx.Response(
            401, json={"error": {"message": "invalid api key"}}
        )
    )
    provider = OpenAIResponseProvider(_openai_model(), _settings())
    request = ChatRequest(model="gpt-5.6", messages=[ChatMessage(role="user", text="hi")])
    events = [event async for event in provider.stream(request)]
    assert len(events) == 1
    assert events[0].kind == "error"
    assert "invalid api key" in events[0].content


@respx.mock
async def test_openai_body_carries_effort_and_max_tokens() -> None:
    """The request body includes ``reasoning.effort`` and
    ``max_output_tokens`` when thinking is requested."""
    captured: dict = {}

    def _capture(request: httpx.Request) -> httpx.Response:
        import json

        captured["body"] = json.loads(request.content)
        return httpx.Response(
            200,
            text='event: response.completed\ndata: {"type":"response.completed"}\n\n',
            headers={"content-type": "text/event-stream"},
        )

    respx.post("https://api.openai.com/v1/responses").mock(side_effect=_capture)
    provider = OpenAIResponseProvider(_openai_model(), _settings())
    request = ChatRequest(
        model="gpt-5.6",
        messages=[ChatMessage(role="user", text="hi")],
        thinking_effort="high",
    )
    _ = [event async for event in provider.stream(request)]
    assert captured["body"]["reasoning"] == {"effort": "high"}
    assert captured["body"]["max_output_tokens"] == 32768
    assert captured["body"]["model"] == "gpt-5.6"


@respx.mock
async def test_anthropic_translates_text_and_done() -> None:
    """Anthropic text deltas and message_stop map to text_delta + done."""
    sse = (
        'event: message_start\n'
        'data: {"type":"message_start","message":{"id":"msg_1"}}\n\n'
        'event: content_block_start\n'
        'data: {"type":"content_block_start","index":0,"content_block":{"type":"text","text":""}}\n\n'
        'event: content_block_delta\n'
        'data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Hi"}}\n\n'
        'event: content_block_stop\n'
        'data: {"type":"content_block_stop","index":0}\n\n'
        'event: message_stop\n'
        'data: {"type":"message_stop"}\n\n'
    )
    respx.post("https://api.anthropic.com/v1/messages").mock(
        return_value=httpx.Response(
            200, text=sse, headers={"content-type": "text/event-stream"}
        )
    )
    provider = AnthropicMessageProvider(_anthropic_model(), _settings())
    request = ChatRequest(
        model="claude-sonnet-5", messages=[ChatMessage(role="user", text="hi")]
    )
    events = [event async for event in provider.stream(request)]
    text = "".join(e.content for e in events if e.kind == "text_delta")
    assert text == "Hi"
    assert events[-1].kind == "done"


@respx.mock
async def test_anthropic_body_carries_adaptive_thinking_and_max_tokens() -> None:
    """The request body uses adaptive thinking with the selected effort and
    the model's ``max_tokens`` (replacing the old hardcoded 8192)."""
    captured: dict = {}

    def _capture(request: httpx.Request) -> httpx.Response:
        import json

        captured["body"] = json.loads(request.content)
        return httpx.Response(
            200,
            text='event: message_stop\ndata: {"type":"message_stop"}\n\n',
            headers={"content-type": "text/event-stream"},
        )

    respx.post("https://api.anthropic.com/v1/messages").mock(side_effect=_capture)
    provider = AnthropicMessageProvider(_anthropic_model(), _settings())
    request = ChatRequest(
        model="claude-sonnet-5",
        messages=[ChatMessage(role="user", text="hi")],
        thinking_effort="high",
    )
    _ = [event async for event in provider.stream(request)]
    assert captured["body"]["thinking"] == {
        "type": "adaptive",
        "effort": "high",
        "display": "summarized",
    }
    assert captured["body"]["max_tokens"] == 16384
    assert captured["body"]["model"] == "claude-sonnet-5"


@respx.mock
async def test_anthropic_translates_thinking_and_signature() -> None:
    """A thinking block yields reasoning deltas and a signature event."""
    sse = (
        'event: content_block_start\n'
        'data: {"type":"content_block_start","index":0,"content_block":{"type":"thinking","thinking":"","signature":""}}\n\n'
        'event: content_block_delta\n'
        'data: {"type":"content_block_delta","index":0,"delta":{"type":"thinking_delta","thinking":"reasoning"}}\n\n'
        'event: content_block_delta\n'
        'data: {"type":"content_block_delta","index":0,"delta":{"type":"signature_delta","signature":"sig-abc"}}\n\n'
        'event: content_block_stop\n'
        'data: {"type":"content_block_stop","index":0}\n\n'
        'event: content_block_start\n'
        'data: {"type":"content_block_start","index":1,"content_block":{"type":"text","text":""}}\n\n'
        'event: content_block_delta\n'
        'data: {"type":"content_block_delta","index":1,"delta":{"type":"text_delta","text":"answer"}}\n\n'
        'event: content_block_stop\n'
        'data: {"type":"content_block_stop","index":1}\n\n'
        'event: message_stop\n'
        'data: {"type":"message_stop"}\n\n'
    )
    respx.post("https://api.anthropic.com/v1/messages").mock(
        return_value=httpx.Response(
            200, text=sse, headers={"content-type": "text/event-stream"}
        )
    )
    provider = AnthropicMessageProvider(_anthropic_model(), _settings())
    request = ChatRequest(
        model="claude-sonnet-5",
        messages=[ChatMessage(role="user", text="hi")],
        thinking_effort="high",
    )
    events = [event async for event in provider.stream(request)]
    reasoning = "".join(e.content for e in events if e.kind == "reasoning_delta")
    assert reasoning == "reasoning"
    signatures = [e.content for e in events if e.kind == "reasoning_signature"]
    assert signatures == ["sig-abc"]
    text = "".join(e.content for e in events if e.kind == "text_delta")
    assert text == "answer"
    assert events[-1].kind == "done"
