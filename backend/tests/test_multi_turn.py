"""多轮对话历史的专门测试。

验证第二个用户消息发送时，backend 能将完整历史（user1, assistant1, user2）传给 provider。
"""

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


async def test_second_turn_sends_full_history(client, monkeypatch) -> None:
    """第二轮对话时，provider 应收到完整历史：user1, assistant1, user2。"""
    fake = _FakeProvider(
        [
            StreamEvent(kind="text_delta", content="Answer1"),
            StreamEvent(kind="done"),
        ]
    )
    monkeypatch.setattr("app.api.chat.get_provider", lambda model, settings: fake)

    pid = await _create_profile(client)
    cid = await _create_conversation(client, pid)

    # 第一轮：发送 user1
    create1 = await client.post(
        f"/api/conversations/{cid}/messages", json={"text": "Question1"}
    )
    assistant1_id = create1.json()["assistant_message"]["id"]

    # 流式完成第一轮
    async with client.stream(
        "GET", f"/api/chat/stream?message_id={assistant1_id}"
    ) as response:
        _ = [line async for line in response.aiter_lines()]

    # 验证第一轮历史
    assert fake.last_request is not None
    assert len(fake.last_request.messages) == 1
    assert fake.last_request.messages[0].role == "user"
    assert fake.last_request.messages[0].text == "Question1"

    # 第二轮：发送 user2
    create2 = await client.post(
        f"/api/conversations/{cid}/messages", json={"text": "Question2"}
    )
    assistant2_id = create2.json()["assistant_message"]["id"]

    # 流式完成第二轮
    async with client.stream(
        "GET", f"/api/chat/stream?message_id={assistant2_id}"
    ) as response:
        _ = [line async for line in response.aiter_lines()]

    # 验证第二轮历史：应包含 user1, assistant1, user2
    assert fake.last_request is not None
    assert len(fake.last_request.messages) == 3
    assert fake.last_request.messages[0].role == "user"
    assert fake.last_request.messages[0].text == "Question1"
    assert fake.last_request.messages[1].role == "assistant"
    assert fake.last_request.messages[1].text == "Answer1"
    assert fake.last_request.messages[2].role == "user"
    assert fake.last_request.messages[2].text == "Question2"
