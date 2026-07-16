"""End-to-end tests for the HTTP API.

Covers profile and conversation CRUD, the message-tree operations (create,
path walk, regenerate, switch, delete), and the SSE chat stream with a fake
provider so no network call is made.
"""

from __future__ import annotations

import json

import pytest

from app.providers.base import StreamEvent


class _FakeProvider:
    """A provider that replays a canned list of events for testing."""

    def __init__(self, events: list[StreamEvent]) -> None:
        self._events = events
        self.last_request = None

    async def stream(self, request):
        self.last_request = request
        for event in self._events:
            yield event


def _parse_sse(lines: list[str]) -> list[tuple[str, str]]:
    """Parse SSE lines into ``(event_type, data)`` pairs."""
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
    """The health endpoint responds without a bearer token."""
    response = await client_unauth.get("/api/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


async def test_missing_token_is_rejected(client_unauth) -> None:
    """A request without a token gets a 401."""
    response = await client_unauth.get("/api/profiles")
    assert response.status_code == 401


async def test_profile_crud(client) -> None:
    """Profiles can be listed, created, renamed, and deleted."""
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
    """Conversations are scoped under a profile."""
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
    """Creating a user message also creates an assistant placeholder and
    moves the conversation leaf to the placeholder."""
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
    # The conversation leaf now points at the placeholder.
    conv = (await client.get(f"/api/conversations/{cid}")).json()
    assert conv["current_leaf_id"] == body["assistant_message"]["id"]


async def test_conversation_path_lists_visible_messages(client) -> None:
    """The path endpoint returns both the user message and the placeholder."""
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
    """``GET /api/models`` returns the default model and the full registry
    without leaking ``api_key`` or ``base_url``."""
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
    assert openai["thinking_effort"] == ["medium", "low", "high", "xhigh"]
    # Secrets are never exposed.
    assert "api_key" not in openai
    assert "base_url" not in openai


async def test_create_conversation_defaults_effort_to_first(client) -> None:
    """Omitting ``thinking_effort`` uses the model's first listed level."""
    pid = await _create_profile(client)
    response = await client.post(
        f"/api/profiles/{pid}/conversations",
        json={"model_id": "test-openai"},
    )
    assert response.status_code == 201
    assert response.json()["thinking_effort"] == "medium"
    assert response.json()["model_id"] == "test-openai"


async def test_create_conversation_rejects_unknown_model(client) -> None:
    """A model id not in the registry is rejected with a 400."""
    pid = await _create_profile(client)
    response = await client.post(
        f"/api/profiles/{pid}/conversations",
        json={"model_id": "no-such-model"},
    )
    assert response.status_code == 400


async def test_create_conversation_rejects_unsupported_effort(client) -> None:
    """An effort level not listed for the model is rejected with a 400."""
    pid = await _create_profile(client)
    response = await client.post(
        f"/api/profiles/{pid}/conversations",
        json={"model_id": "test-openai", "thinking_effort": "max"},
    )
    assert response.status_code == 400


async def test_patch_conversation_changes_effort(client) -> None:
    """``thinking_effort`` can be changed after creation; ``model_id`` cannot."""
    pid = await _create_profile(client)
    cid = await _create_conversation(client, pid)
    response = await client.patch(
        f"/api/conversations/{cid}", json={"thinking_effort": "high"}
    )
    assert response.status_code == 200
    assert response.json()["thinking_effort"] == "high"


async def test_patch_conversation_rejects_unsupported_effort(client) -> None:
    """Patching to a level the model does not support is a 400."""
    pid = await _create_profile(client)
    cid = await _create_conversation(client, pid)
    response = await client.patch(
        f"/api/conversations/{cid}", json={"thinking_effort": "max"}
    )
    assert response.status_code == 400


async def test_chat_stream_writes_tokens_to_placeholder(
    client, monkeypatch
) -> None:
    """The SSE stream writes accumulated content into the assistant message
    and marks it complete on ``done``."""
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

    # The assistant message now contains the streamed text and is complete.
    path = (await client.get(f"/api/conversations/{cid}/messages")).json()
    assistant = path["path"][-1]["message"]
    assert assistant["content"] == "Hello world"
    assert assistant["is_complete"] is True


async def test_chat_stream_persists_reasoning_and_signature(
    client, monkeypatch
) -> None:
    """Reasoning deltas and the signature event are stored on the message."""
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

    # The fake provider received the user message in the request history.
    assert fake.last_request is not None
    assert fake.last_request.messages[-1].role == "user"
    assert fake.last_request.messages[-1].text == "hi"
    # The thinking-effort level was forwarded from the conversation.
    assert fake.last_request.thinking_effort == "medium"


async def test_regenerate_creates_sibling_placeholder(client, monkeypatch) -> None:
    """Regenerating creates a new assistant placeholder under the same parent."""
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
    # The conversation leaf moved to the new placeholder.
    conv = (await client.get(f"/api/conversations/{cid}")).json()
    assert conv["current_leaf_id"] == new_placeholder["id"]


async def test_switch_leaf_changes_visible_path(
    client, monkeypatch
) -> None:
    """Switching the leaf changes which sibling the visible path descends."""
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

    # Stream into the first placeholder so it has content.
    async with client.stream(
        "GET", f"/api/chat/stream?message_id={first_assistant}"
    ) as response:
        _ = [line async for line in response.aiter_lines()]

    # Regenerate to get a second sibling.
    regen = await client.post(
        f"/api/conversations/{cid}/messages/{user_id}/regenerate"
    )
    second_assistant = regen.json()["id"]

    # The current path ends at the second assistant.
    path = (await client.get(f"/api/conversations/{cid}/messages")).json()
    assert path["path"][-1]["message"]["id"] == second_assistant

    # The assistant node's siblings include both versions.
    assistant_node = path["path"][-1]
    assert set(assistant_node["siblings"]["siblings"]) == {first_assistant, second_assistant}
    assert assistant_node["siblings"]["active_id"] == second_assistant

    # Switch back to the first assistant.
    switched = await client.post(
        f"/api/conversations/{cid}/messages/{first_assistant}/switch"
    )
    assert switched.json()["path"][-1]["message"]["id"] == first_assistant


async def test_delete_message_reparents_leaf(client, monkeypatch) -> None:
    """Deleting the current leaf moves the conversation leaf to its parent."""
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

    # Delete the assistant placeholder; the leaf should become the user msg.
    response = await client.delete(
        f"/api/conversations/{cid}/messages/{assistant_id}"
    )
    assert response.status_code == 204
    conv = (await client.get(f"/api/conversations/{cid}")).json()
    assert conv["current_leaf_id"] == user_id

    # The path now contains only the user message.
    path = (await client.get(f"/api/conversations/{cid}/messages")).json()
    assert len(path["path"]) == 1
    assert path["path"][0]["message"]["role"] == "user"


async def test_consecutive_user_messages_rejected(client) -> None:
    """Attaching a user message under another user message is rejected so
    Anthropic's role-alternation rule is not violated."""
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
