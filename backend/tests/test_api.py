"""HTTP API 的端到端测试。

覆盖 profile 和 conversation CRUD、message-tree operation（create、path walk、regenerate、
switch、delete），以及使用 fake provider 的 SSE chat stream，因此不会发起 network call。
"""

from __future__ import annotations

import json

import pytest

from app.providers.base import StreamEvent


class _FakeProvider:
    """用于测试、重放预设 event list 的 provider。"""

    def __init__(self, events: list[StreamEvent]) -> None:
        self._events = events
        self.last_request = None

    async def stream(self, request):
        self.last_request = request
        for event in self._events:
            yield event


def _parse_sse(lines: list[str]) -> list[tuple[str, str]]:
    """将 SSE line 解析为 ``(event_type, data)`` pair。"""
    events: list[tuple[str, str]] = []
    current_event: str | None = None
    current_data: list[str] = []
    for line in lines:
        if line == "":
            if current_event is not None:
                events.append((current_event, "\n".join(current_data)))
            current_event = None
            current_data = []
        elif line.startswith("event:"):
            current_event = line[len("event:"):].strip()
        elif line.startswith("data:"):
            current_data.append(line[len("data:"):].strip())
    return events


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


async def test_health_is_unauthenticated(client_unauth) -> None:
    """health endpoint 无需 bearer token 即可响应。"""
    response = await client_unauth.get("/api/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


async def test_missing_token_is_rejected(client_unauth) -> None:
    """没有 token 的 request 会得到 401。"""
    response = await client_unauth.get("/api/profiles")
    assert response.status_code == 401


async def test_profile_crud(client) -> None:
    """Profile 可以被列出、创建、重命名和删除。"""
    assert (await client.get("/api/profiles")).json() == []
    pid = await _create_profile(client, "Learning")
    profiles = (await client.get("/api/profiles")).json()
    assert len(profiles) == 1
    assert profiles[0]["name"] == "Learning"
    response = await client.patch(f"/api/profiles/{pid}", params={"name": "Rust"})
    assert response.json()["name"] == "Rust"
    assert (await client.delete(f"/api/profiles/{pid}")).status_code == 204
    assert (await client.get("/api/profiles")).json() == []


async def test_conversation_crud(client) -> None:
    """Conversation 的 scope 位于 profile 下。"""
    pid = await _create_profile(client)
    cid = await _create_conversation(client, pid, "First chat")
    response = await client.get(f"/api/profiles/{pid}/conversations")
    assert response.json()[0]["title"] == "First chat"
    response = await client.patch(
        f"/api/conversations/{cid}", json={"title": "Renamed"}
    )
    assert response.json()["title"] == "Renamed"
    assert (await client.delete(f"/api/conversations/{cid}")).status_code == 204


async def test_create_user_message_adds_assistant_placeholder(client) -> None:
    """创建 user message 也会创建 assistant placeholder，并将 conversation leaf 移动到该 placeholder。"""
    pid = await _create_profile(client)
    cid = await _create_conversation(client, pid)
    response = await client.post(
        f"/api/conversations/{cid}/messages",
        json={"text": "What is 2+2?"},
    )
    assert response.status_code == 201, response.text
    body = response.json()
    assert body["user_message"]["role"] == "user"
    assert body["user_message"]["content"] == "What is 2+2?"
    assert body["assistant_message"]["role"] == "assistant"
    assert body["assistant_message"]["is_complete"] is False
    # conversation leaf 现在指向 placeholder。
    conv = (await client.get(f"/api/conversations/{cid}")).json()
    assert conv["current_leaf_id"] == body["assistant_message"]["id"]


async def test_explicit_null_parent_creates_root_sibling(client) -> None:
    """显式 ``parent_id: null`` 用于编辑首条 prompt，而不是追加到 current leaf。"""
    pid = await _create_profile(client)
    cid = await _create_conversation(client, pid)
    first = await client.post(
        f"/api/conversations/{cid}/messages", json={"text": "Original"}
    )
    first_user_id = first.json()["user_message"]["id"]

    second = await client.post(
        f"/api/conversations/{cid}/messages",
        json={"parent_id": None, "text": "Revised"},
    )
    assert second.status_code == 201, second.text
    body = second.json()
    assert body["user_message"]["parent_id"] is None
    assert body["user_message"]["content"] == "Revised"

    path = (await client.get(f"/api/conversations/{cid}/messages")).json()
    assert [item["message"]["id"] for item in path["path"]] == [
        body["user_message"]["id"],
        body["assistant_message"]["id"],
    ]
    assert set(path["path"][0]["siblings"]["siblings"]) == {
        first_user_id,
        body["user_message"]["id"],
    }


async def test_conversation_path_lists_visible_messages(client) -> None:
    """path endpoint 同时返回 user message 和 placeholder。"""
    pid = await _create_profile(client)
    cid = await _create_conversation(client, pid)
    create = await client.post(
        f"/api/conversations/{cid}/messages", json={"text": "hello"}
    )
    assistant_id = create.json()["assistant_message"]["id"]
    path = (await client.get(f"/api/conversations/{cid}/messages")).json()
    assert len(path["path"]) == 2
    assert path["path"][0]["message"]["role"] == "user"


async def test_list_models_returns_registry_and_default(client) -> None:
    """``GET /api/models`` 返回 default model 和完整 registry，但不会泄露 ``api_key`` 或 ``base_url``。"""
    response = await client.get("/api/models")
    assert response.status_code == 200
    body = response.json()
    assert body["default_model"] == "test-openai"
    ids = [m["id"] for m in body["models"]]
    assert ids == ["test-openai", "test-anthropic"]
    openai = body["models"][0]
    assert openai["family"] == "openai"
    assert openai["protocol"] == "openai-response"
    assert openai["vision"] is True
    # secret 永远不会暴露。
    assert "api_key" not in openai
    assert "base_url" not in openai
    assert "thinking_off_effort" not in openai
    assert "thinking_on_effort" not in openai


async def test_create_conversation_defaults_thinking_to_off(client) -> None:
    """省略 ``thinking_enabled`` 时默认关闭深度思考。"""
    pid = await _create_profile(client)
    response = await client.post(
        f"/api/profiles/{pid}/conversations",
        json={"model_id": "test-openai"},
    )
    assert response.status_code == 201
    assert response.json()["thinking_enabled"] is False
    assert response.json()["model_id"] == "test-openai"


async def test_create_conversation_rejects_unknown_model(client) -> None:
    """不在 registry 中的 model id 会被拒绝并返回 400。"""
    pid = await _create_profile(client)
    response = await client.post(
        f"/api/profiles/{pid}/conversations",
        json={"model_id": "no-such-model"},
    )
    assert response.status_code == 400


async def test_create_conversation_persists_thinking_toggle(client) -> None:
    """创建时可以直接保存用户选择的深度思考开关。"""
    pid = await _create_profile(client)
    response = await client.post(
        f"/api/profiles/{pid}/conversations",
        json={"model_id": "test-openai", "thinking_enabled": True},
    )
    assert response.status_code == 201
    assert response.json()["thinking_enabled"] is True


async def test_create_conversation_rejects_deprecated_effort(client) -> None:
    """已废弃的 ``thinking_effort`` 字段不会被静默忽略。"""
    pid = await _create_profile(client)
    response = await client.post(
        f"/api/profiles/{pid}/conversations",
        json={"model_id": "test-openai", "thinking_effort": "xhigh"},
    )
    assert response.status_code == 422


async def test_patch_conversation_changes_thinking_toggle(client) -> None:
    """创建后可以修改 ``thinking_enabled``，但不能修改 ``model_id``。"""
    pid = await _create_profile(client)
    cid = await _create_conversation(client, pid)
    response = await client.patch(
        f"/api/conversations/{cid}", json={"thinking_enabled": True}
    )
    assert response.status_code == 200
    assert response.json()["thinking_enabled"] is True


async def test_chat_stream_writes_tokens_to_placeholder(
    client, monkeypatch
) -> None:
    """SSE stream 会将累计内容写入 assistant message，并在 ``done`` 时将其标记为完成。"""
    events = [
        StreamEvent(kind="text_delta", content="Hello"),
        StreamEvent(kind="text_delta", content=" world"),
        StreamEvent(kind="done"),
    ]
    fake = _FakeProvider(events)
    monkeypatch.setattr("app.api.chat.get_provider", lambda model, settings: fake)

    pid = await _create_profile(client)
    cid = await _create_conversation(client, pid)
    create = await client.post(
        f"/api/conversations/{cid}/messages", json={"text": "hi"}
    )
    assistant_id = create.json()["assistant_message"]["id"]

    async with client.stream(
        "GET", f"/api/chat/stream?message_id={assistant_id}"
    ) as response:
        assert response.status_code == 200
        lines = [line async for line in response.aiter_lines()]
    parsed = _parse_sse(lines)
    types = [event_type for event_type, _ in parsed]
    assert "started" in types
    assert types.count("text_delta") == 2
    assert types[-1] == "done"

    # assistant message 现在包含 streamed text，并且已完成。
    path = (await client.get(f"/api/conversations/{cid}/messages")).json()
    assistant = path["path"][-1]["message"]
    assert assistant["content"] == "Hello world"
    assert assistant["is_complete"] is True


async def test_chat_stream_persists_reasoning_and_signature(
    client, monkeypatch
) -> None:
    """Reasoning delta 和 signature event 会存储在 message 上。"""
    events = [
        StreamEvent(kind="reasoning_delta", content="thinking"),
        StreamEvent(kind="reasoning_signature", content="sig-123"),
        StreamEvent(kind="text_delta", content="answer"),
        StreamEvent(kind="done"),
    ]
    fake = _FakeProvider(events)
    monkeypatch.setattr("app.api.chat.get_provider", lambda model, settings: fake)

    pid = await _create_profile(client)
    cid = await _create_conversation(client, pid)
    create = await client.post(
        f"/api/conversations/{cid}/messages", json={"text": "hi"}
    )
    assistant_id = create.json()["assistant_message"]["id"]

    async with client.stream(
        "GET", f"/api/chat/stream?message_id={assistant_id}"
    ) as response:
        lines = [line async for line in response.aiter_lines()]
    parsed = _parse_sse(lines)
    types = [event_type for event_type, _ in parsed]
    assert "reasoning_delta" in types
    assert "reasoning_signature" in types
    done_payload = next(data for event_type, data in parsed if event_type == "done")
    assert isinstance(json.loads(done_payload)["reasoning_duration_ms"], int)

    # fake provider 在 request history 中收到了 user message。
    assert fake.last_request is not None
    assert fake.last_request.messages[-1].role == "user"
    assert fake.last_request.messages[-1].text == "hi"
    # 关闭深度思考时，使用 model 配置的 off effort。
    assert fake.last_request.thinking_effort == "medium"

    path = (await client.get(f"/api/conversations/{cid}/messages")).json()
    assistant = path["path"][-1]["message"]
    assert isinstance(assistant["reasoning_duration_ms"], int)
    assert assistant["reasoning_duration_ms"] >= 1


async def test_chat_stream_uses_thinking_on_effort(client, monkeypatch) -> None:
    """开启深度思考后，stream 会转发 model 配置的 on effort。"""
    fake = _FakeProvider([StreamEvent(kind="done")])
    monkeypatch.setattr("app.api.chat.get_provider", lambda model, settings: fake)

    pid = await _create_profile(client)
    create_conversation = await client.post(
        f"/api/profiles/{pid}/conversations",
        json={"model_id": "test-openai", "thinking_enabled": True},
    )
    cid = create_conversation.json()["id"]
    create_message = await client.post(
        f"/api/conversations/{cid}/messages", json={"text": "hi"}
    )
    assistant_id = create_message.json()["assistant_message"]["id"]

    async with client.stream(
        "GET", f"/api/chat/stream?message_id={assistant_id}"
    ) as response:
        _ = [line async for line in response.aiter_lines()]

    assert fake.last_request is not None
    assert fake.last_request.thinking_effort == "xhigh"


async def test_regenerate_creates_sibling_placeholder(client, monkeypatch) -> None:
    """Regenerate 会在相同 parent 下创建新的 assistant placeholder。"""
    monkeypatch.setattr(
        "app.api.chat.get_provider",
        lambda model, settings: _FakeProvider([StreamEvent(kind="done")]),
    )
    pid = await _create_profile(client)
    cid = await _create_conversation(client, pid)
    create = await client.post(
        f"/api/conversations/{cid}/messages", json={"text": "first"}
    )
    user_id = create.json()["user_message"]["id"]

    regen = await client.post(
        f"/api/conversations/{cid}/messages/{user_id}/regenerate"
    )
    assert regen.status_code == 201
    new_placeholder = regen.json()
    assert new_placeholder["parent_id"] == user_id
    assert new_placeholder["is_complete"] is False
    # conversation leaf 已移动到新的 placeholder。
    conv = (await client.get(f"/api/conversations/{cid}")).json()
    assert conv["current_leaf_id"] == new_placeholder["id"]


async def test_switch_leaf_changes_visible_path(
    client, monkeypatch
) -> None:
    """切换 leaf 会改变可见 path 进入的 sibling。"""
    monkeypatch.setattr(
        "app.api.chat.get_provider",
        lambda model, settings: _FakeProvider([StreamEvent(kind="done")]),
    )
    pid = await _create_profile(client)
    cid = await _create_conversation(client, pid)
    create = await client.post(
        f"/api/conversations/{cid}/messages", json={"text": "q"}
    )
    user_id = create.json()["user_message"]["id"]
    first_assistant = create.json()["assistant_message"]["id"]

    # 向第一个 placeholder stream，使它拥有 content。
    async with client.stream(
        "GET", f"/api/chat/stream?message_id={first_assistant}"
    ) as response:
        _ = [line async for line in response.aiter_lines()]

    # Regenerate 以获得第二个 sibling。
    regen = await client.post(
        f"/api/conversations/{cid}/messages/{user_id}/regenerate"
    )
    second_assistant = regen.json()["id"]

    # 当前 path 以第二个 assistant 结尾。
    path = (await client.get(f"/api/conversations/{cid}/messages")).json()
    assert path["path"][-1]["message"]["id"] == second_assistant

    # assistant node 的 sibling 包含两个 version。
    assistant_node = path["path"][-1]
    assert set(assistant_node["siblings"]["siblings"]) == {first_assistant, second_assistant}
    assert assistant_node["siblings"]["active_id"] == second_assistant

    # 切回第一个 assistant。
    switched = await client.post(
        f"/api/conversations/{cid}/messages/{first_assistant}/switch"
    )
    assert switched.json()["path"][-1]["message"]["id"] == first_assistant


async def test_delete_message_reparents_leaf(client, monkeypatch) -> None:
    """删除 current leaf 会将 conversation leaf 移动到其 parent。"""
    monkeypatch.setattr(
        "app.api.chat.get_provider",
        lambda model, settings: _FakeProvider([StreamEvent(kind="done")]),
    )
    pid = await _create_profile(client)
    cid = await _create_conversation(client, pid)
    create = await client.post(
        f"/api/conversations/{cid}/messages", json={"text": "q"}
    )
    user_id = create.json()["user_message"]["id"]
    assistant_id = create.json()["assistant_message"]["id"]

    # 删除 assistant placeholder；leaf 应变为 user message。
    response = await client.delete(
        f"/api/conversations/{cid}/messages/{assistant_id}"
    )
    assert response.status_code == 204
    conv = (await client.get(f"/api/conversations/{cid}")).json()
    assert conv["current_leaf_id"] == user_id

    # path 现在只包含 user message。
    path = (await client.get(f"/api/conversations/{cid}/messages")).json()
    assert len(path["path"]) == 1
    assert path["path"][0]["message"]["role"] == "user"


async def test_consecutive_user_messages_rejected(client) -> None:
    """将 user message 挂到另一个 user message 下会被拒绝，以免违反 Anthropic 的 role-alternation rule。"""
    pid = await _create_profile(client)
    cid = await _create_conversation(client, pid)
    create = await client.post(
        f"/api/conversations/{cid}/messages", json={"text": "first"}
    )
    user_id = create.json()["user_message"]["id"]
    response = await client.post(
        f"/api/conversations/{cid}/messages",
        json={"parent_id": user_id, "text": "second"},
    )
    assert response.status_code == 400
