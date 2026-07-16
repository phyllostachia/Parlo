"""SQLModel entities and API schemas.

The data model has three tables:

* :class:`Profile` — a top-level group of conversations (a "project" or
  "topic area"). Chosen in decision D22 over alternative meanings of
  "profile".
* :class:`Conversation` — a chat thread belonging to a profile. It tracks
  the currently active leaf message so the client can reconstruct the visible
  message path.
* :class:`Message` — a single message in a conversation, linked to its parent
  via ``parent_id`` to form a tree. Sibling messages under the same parent
  are alternative replies; switching between them is done by moving
  ``conversation.current_leaf_id``. This structure is mandated by decision
  D18 because learners need to re-ask and compare answers.

The module also declares lightweight Pydantic request/response models used by
the API layer so that internal fields such as ``reasoning_signature`` are
not exposed to the client.
"""

from __future__ import annotations

from datetime import datetime, timezone
from typing import Literal

from sqlmodel import Field, SQLModel


def _now() -> datetime:
    """Return the current UTC time as a timezone-aware datetime.

    A helper is used instead of ``datetime.utcnow`` because the latter is
    deprecated and returns naive datetimes that are easy to misuse.
    """
    return datetime.now(timezone.utc)


MessageRole = Literal["user", "assistant", "system"]
"""Allowed values for :attr:`Message.role`."""


class Profile(SQLModel, table=True):
    """A named group of conversations."""

    id: int | None = Field(default=None, primary_key=True)
    name: str = Field(index=True)
    created_at: datetime = Field(default_factory=_now)
    updated_at: datetime = Field(default_factory=_now)


class Conversation(SQLModel, table=True):
    """A chat thread inside a profile.

    ``current_leaf_id`` points at the last message on the currently visible
    path. The full path is reconstructed by walking ``parent_id`` from this
    leaf back to the root, which is O(depth) and avoids recursive queries.
    """

    id: int | None = Field(default=None, primary_key=True)
    profile_id: int = Field(foreign_key="profile.id", index=True, ondelete="CASCADE")
    title: str = ""
    model_id: str = ""
    """The model used for every assistant turn in this conversation. Fixed at
    creation time (decision D03); to use a different model, create a new
    conversation. The value is the ``id`` of an entry in ``config.yaml``."""
    thinking_effort: str = ""
    """Thinking-effort level selected for this conversation. Must be one of
    the levels listed in the model's ``thinking_effort`` field. Changeable via
    ``PATCH`` (decision D05/D09)."""
    current_leaf_id: int | None = Field(
        default=None,
        foreign_key="message.id",
        ondelete="SET NULL",
    )
    created_at: datetime = Field(default_factory=_now)
    updated_at: datetime = Field(default_factory=_now)


class Message(SQLModel, table=True):
    """A message node in a conversation tree.

    ``parent_id`` is ``None`` for a root message. Multiple messages can share
    a ``parent_id``; each one is an alternative reply to that parent.
    ``is_complete`` is ``False`` while the server is streaming tokens into the
    message, so the client can show a placeholder and so interrupt recovery
    can tell partial messages from finished ones.

    ``reasoning_signature`` stores Anthropic's thinking-block signature so the
    block can be replayed verbatim when the assistant message is sent back as
    history in a later turn. OpenAI reasoning has no equivalent, so the field
    is ``None`` for OpenAI providers.
    """

    id: int | None = Field(default=None, primary_key=True)
    conversation_id: int = Field(
        foreign_key="conversation.id", index=True, ondelete="CASCADE"
    )
    parent_id: int | None = Field(
        default=None, foreign_key="message.id", index=True, ondelete="CASCADE"
    )
    role: str
    """One of ``user``, ``assistant``, ``system``. Stored as plain text because
    SQLModel cannot map a ``Literal`` to a column type; the read schemas
    re-narrow the value with :data:`MessageRole`."""
    content: str = ""
    reasoning: str | None = None
    reasoning_signature: str | None = None
    image_path: str | None = None
    is_complete: bool = Field(default=True)
    created_at: datetime = Field(default_factory=_now)


# Request schemas (no table=True) used by the API layer.

class ConversationCreate(SQLModel):
    """Body of a create-conversation request.

    ``model_id`` selects the model for this conversation (decision D03). It
    must match an entry in ``config.yaml``; the endpoint validates that.

    ``thinking_effort`` defaults to the first level of the model's
    ``thinking_effort`` list when omitted (decision D05). If given, it must be
    one of the model's listed levels.
    """

    model_id: str
    title: str = ""
    thinking_effort: str | None = None


class ConversationUpdate(SQLModel):
    """Body of a PATCH conversation request.

    Only ``thinking_effort`` (and ``title``) may be changed after creation;
    ``model_id`` is fixed (decision D09). Both fields are optional and only
    the provided ones are applied.
    """

    title: str | None = None
    thinking_effort: str | None = None



class UserMessageCreate(SQLModel):
    """Body of a create-user-message request.

    ``parent_id`` defaults to the conversation's current leaf when omitted,
    which is the common case for appending a new question to the visible
    path.
    """
    parent_id: int | None = None
    text: str
    image_data: str | None = None
    """Optional base64 data URL for an image attached to the message.

    The image is decoded and stored on disk by :mod:`app.storage`; only the
    resulting path is persisted on the message.
    """


# Response schemas (no table=True) returned to the client.

class ProfileRead(SQLModel):
    id: int
    name: str
    created_at: datetime
    updated_at: datetime


class ConversationRead(SQLModel):
    id: int
    profile_id: int
    title: str
    model_id: str
    thinking_effort: str
    current_leaf_id: int | None
    created_at: datetime
    updated_at: datetime


class MessageRead(SQLModel):
    id: int
    conversation_id: int
    parent_id: int | None
    role: MessageRole
    content: str
    reasoning: str | None
    image_url: str | None = None
    """URL the client can use to fetch the attached image, if any."""
    is_complete: bool
    created_at: datetime


class SiblingInfo(SQLModel):
    """Metadata about the sibling messages of a node on the visible path.

    Lets the client render ``< 2 / 3 >`` version switchers without fetching
    the whole tree.
    """
    siblings: list[int] = []
    """IDs of all messages sharing this node's ``parent_id`` (including it)."""
    active_id: int
    """ID of the sibling that the visible path currently descends into."""


class MessageTreeNode(SQLModel):
    """A message on the visible path plus its sibling metadata."""
    message: MessageRead
    siblings: SiblingInfo


class ConversationPath(SQLModel):
    """The visible message path of a conversation.

    Ordered from root to the current leaf. Each entry is a
    :class:`MessageTreeNode` so the client can render version switchers at
    every level.
    """
    conversation: ConversationRead
    path: list[MessageTreeNode]


class SendMessageResponse(SQLModel):
    """Returned when a user message is created.

    Bundles the new user message together with the freshly-created assistant
    placeholder that the client should stream tokens into via
    ``GET /api/chat/stream``.
    """
    user_message: MessageRead
    assistant_message: MessageRead


class ModelRead(SQLModel):
    """Client-facing view of a model definition from ``config.yaml``.

    Deliberately omits ``api_key`` (a secret reference) and ``base_url`` (not
    useful to the client). ``max_tokens`` is also omitted: it is an upstream
    output budget, not something the client renders.
    """

    id: str
    display_name: str
    family: str
    protocol: str
    vision: bool
    thinking_effort: list[str]


class ModelsResponse(SQLModel):
    """Response of ``GET /api/models``.

    Carries the configured default model id and the list of available models
    so the client can render its model and thinking-effort selectors without
    any hardcoded protocol knowledge.
    """

    default_model: str
    models: list[ModelRead]

