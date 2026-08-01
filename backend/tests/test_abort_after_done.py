"""验证客户端在收到 done 后立即断开时，后端仍能保存完整内容。

复现场景：ASGI transport 在 response 消费中途取消 task，模拟真实浏览器
``AbortController.abort()`` 的行为。Starlette 的 ``StreamingResponse`` 在取消发生时
会向 generator 抛出 ``GeneratorExit``/``CancelledError``；如果 generator 的
``finally`` block 在 cancellation 期间执行 ``await``（例如 ``session.commit()``），
该 ``await`` 会再次被取消，保存丢失。

修复：收到 ``done``/``error`` 后、向客户端 ``yield`` 之前，先用 ``asyncio.shield``
把内容持久化；``finally`` 兜底也 shield，且只在尚未保存时才执行。
"""

from __future__ import annotations

import asyncio

import pytest
from httpx import ASGITransport, AsyncClient

from app.main import app
from app.providers.base import StreamEvent


class _FakeProvider:
    def __init__(self, events: list[StreamEvent]) -> None:
        self._events = events

    async def stream(self, request):
        for event in self._events:
            yield event


async def _create_profile(client, name: str = "Test") -> int:
    response = await client.post("/api/profiles", params={"name": name})
    assert response.status_code == 201, response.text
    return response.json()["id"]


async def _create_conversation(client, profile_id: int, model_id: str = "test-openai") -> int:
    response = await client.post(
        f"/api/profiles/{profile_id}/conversations",
        json={"model_id": model_id, "title": "T"},
    )
    assert response.status_code == 201, response.text
    return response.json()["id"]


async def test_full_content_saved_when_client_aborts_after_done(client, monkeypatch) -> None:
    """客户端读到 ``done`` 后立即中断连接，数据库中的 assistant 消息仍应保存完整内容。"""
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
    create = await client.post(
        f"/api/conversations/{cid}/messages", json={"text": "hi"}
    )
    assistant_id = create.json()["assistant_message"]["id"]

    # 读取到 done 后立即关闭 response（模拟前端 abort）。
    async with client.stream(
        "GET", f"/api/chat/stream?message_id={assistant_id}"
    ) as response:
        async for line in response.aiter_lines():
            if line.startswith("event: done"):
                break

    # 给后端 task 一点时间完成持久化。
    await asyncio.sleep(0.2)

    path = (await client.get(f"/api/conversations/{cid}/messages")).json()
    assistant = path["path"][-1]["message"]
    assert assistant["content"] == "Hello world"
    assert assistant["is_complete"] is True
