"""验证 SSE 流式传输和内容保存的端到端测试。"""

from __future__ import annotations

import pytest

from app.providers.base import StreamEvent


class _FakeProvider:
    """记录收到的 request 的 fake provider。"""

    def __init__(self, events: list[StreamEvent]) -> None:
        self._events = events
        self.last_request = None

    async def stream(self, request):
        self.last_request = request
        for event in self._events:
            yield event


async def _create_profile(client, name: str = "Test") -> int:
    response = await client.post("/api/profiles", params={"name": name})
    assert response.status_code == 201, response.text
    return response.json()["id"]


async def _create_conversation(
    client, profile_id: int, title: str = "Conv", model_id: str = "test-openai"
) -> int:
    response = await client.post(
        f"/api/profiles/{profile_id}/conversations",
        json={"model_id": model_id, "title": title},
    )
    assert response.status_code == 201, response.text
    return response.json()["id"]


async def test_stream_saves_content_to_database(client, monkeypatch) -> None:
    """验证 SSE 流式传输后，assistant 消息的内容被正确保存到数据库。"""
    fake = _FakeProvider(
        [
            StreamEvent(kind="text_delta", content="Hello"),
            StreamEvent(kind="text_delta", content=" world"),
            StreamEvent(kind="done"),
        ]
    )
    monkeypatch.setattr("app.api.chat.get_provider", lambda model, settings: fake)

    pid = await _create_profile(client)
    cid = await _create_conversation(client, pid)

    # 创建 user message 和 assistant placeholder
    create = await client.post(
        f"/api/conversations/{cid}/messages", json={"text": "Hi"}
    )
    assistant_id = create.json()["assistant_message"]["id"]

    # 通过 SSE 流式传输
    async with client.stream(
        "GET", f"/api/chat/stream?message_id={assistant_id}"
    ) as response:
        lines = [line async for line in response.aiter_lines()]

    # 验证 SSE 事件
    assert any("event: text_delta" in line for line in lines)
    assert any("event: done" in line for line in lines)

    # 验证数据库中的内容
    path = (await client.get(f"/api/conversations/{cid}/messages")).json()
    assistant = path["path"][-1]["message"]
    assert assistant["content"] == "Hello world", f"Expected 'Hello world', got '{assistant['content']}'"
    assert assistant["is_complete"] is True


async def test_stream_saves_content_on_second_turn(client, monkeypatch) -> None:
    """验证第二轮对话时，assistant 消息的内容被正确保存。"""
    fake = _FakeProvider(
        [
            StreamEvent(kind="text_delta", content="Answer1"),
            StreamEvent(kind="done"),
        ]
    )
    monkeypatch.setattr("app.api.chat.get_provider", lambda model, settings: fake)

    pid = await _create_profile(client)
    cid = await _create_conversation(client, pid)

    # 第一轮
    create1 = await client.post(
        f"/api/conversations/{cid}/messages", json={"text": "Question1"}
    )
    assistant1_id = create1.json()["assistant_message"]["id"]
    async with client.stream(
        "GET", f"/api/chat/stream?message_id={assistant1_id}"
    ) as response:
        _ = [line async for line in response.aiter_lines()]

    # 验证第一轮内容已保存
    path1 = (await client.get(f"/api/conversations/{cid}/messages")).json()
    assert path1["path"][-1]["message"]["content"] == "Answer1"

    # 第二轮 - 更换 provider 以返回不同内容
    fake2 = _FakeProvider(
        [
            StreamEvent(kind="text_delta", content="Answer2"),
            StreamEvent(kind="done"),
        ]
    )
    monkeypatch.setattr("app.api.chat.get_provider", lambda model, settings: fake2)

    create2 = await client.post(
        f"/api/conversations/{cid}/messages", json={"text": "Question2"}
    )
    assistant2_id = create2.json()["assistant_message"]["id"]
    async with client.stream(
        "GET", f"/api/chat/stream?message_id={assistant2_id}"
    ) as response:
        _ = [line async for line in response.aiter_lines()]

    # 验证第二轮内容已保存
    path2 = (await client.get(f"/api/conversations/{cid}/messages")).json()
    assert path2["path"][-1]["message"]["content"] == "Answer2"

    # 验证第二轮请求包含了完整历史
    assert fake2.last_request is not None
    assert len(fake2.last_request.messages) == 3
    assert fake2.last_request.messages[0].text == "Question1"
    assert fake2.last_request.messages[1].text == "Answer1"
    assert fake2.last_request.messages[2].text == "Question2"
