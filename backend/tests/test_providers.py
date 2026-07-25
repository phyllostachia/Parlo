"""Provider adapter event translation 的测试。

上游 HTTP layer 使用 ``respx`` mock，因此测试只验证 protocol-to-unified-event mapping，
不会发起 network call。每个 test 提供预设 SSE response，并断言 adapter 生成预期顺序的
:class:`StreamEvent` object。

Adapter 根据 :class:`ModelConfig`（base URL、protocol、max_tokens 和 API key 的 env-var
name）以及 process-wide :class:`Settings`（携带 image upload directory）构造。共享的
conftest 设置 ``OPENAI_API_KEY`` / ``ANTHROPIC_API_KEY`` 和临时 ``config.yaml``，因此
构造的 model 只需要引用这些 name。
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
    # 复用共享 test config，使 image upload dir 等配置保持一致。
    return get_settings()


@respx.mock
async def test_openai_translates_text_and_done() -> None:
    """OpenAI text delta 会拼接，stream 以 ``done`` 结束。"""
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
    """Reasoning delta event 会作为 ``reasoning_delta`` 暴露。"""
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
    """非 200 response 会变成单个 ``error`` event。"""
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
    """请求 body 在请求 thinking 时包含 ``reasoning.effort`` 和 ``max_output_tokens``。"""
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
    """Anthropic text delta 和 message_stop 会映射为 text_delta + done。"""
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
    """请求 body 使用选定 effort 的 adaptive thinking，以及 model 的 ``max_tokens``（替代旧的 hardcoded 8192）。"""
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
    """Thinking block 会生成 reasoning delta 和 signature event。"""
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
