"""验证客户端断开连接时后端保存内容的测试。"""

from __future__ import annotations

import asyncio

import pytest

from app.providers.base import StreamEvent


class _SlowFakeProvider:
    """模拟慢速 provider，用于测试客户端断开连接的情况。"""

    def __init__(self) -> None:
        self.last_request = None
        self._cancelled = False

    async def stream(self, request):
        self.last_request = request
        yield StreamEvent(kind="text_delta", content="Partial")
        # 模拟慢速响应，给客户端时间断开连接
        await asyncio.sleep(0.1)
        if not self._cancelled:
            yield StreamEvent(kind="text_delta", content=" content")
            yield StreamEvent(kind="done")


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


async def test_stream_saves_partial_content_on_client_disconnect(
    client, monkeypatch
) -> None:
    """验证客户端断开连接时，后端保存已接收的部分内容。"""
    fake = _SlowFakeProvider()
    monkeypatch.setattr("app.api.chat.get_provider", lambda model, settings: fake)

    pid = await _create_profile(client)
    cid = await _create_conversation(client, pid)

    create = await client.post(
        f"/api/conversations/{cid}/messages", json={"text": "Hi"}
    )
    assistant_id = create.json()["assistant_message"]["id"]

    # 启动 SSE 流但立即断开连接
    async with client.stream(
        "GET", f"/api/chat/stream?message_id={assistant_id}"
    ) as response:
        # 只读取第一个事件就断开
        async for line in response.aiter_lines():
            if "text_delta" in line:
                break

    # 给后端一些时间保存内容
    await asyncio.sleep(0.2)

    # 验证数据库中的内容
    path = (await client.get(f"/api/conversations/{cid}/messages")).json()
    assistant = path["path"][-1]["message"]
    # 后端应该保存了部分内容
    assert assistant["is_complete"] is True
    # 内容可能是 "Partial" 或 "Partial content"，取决于断开时机
    assert "Partial" in assistant["content"]
