"""SQLModel entity 和 API schema。

数据模型包含三张 table：

* :class:`Profile` — 会话的顶层分组（即“project”或“topic area”）。根据决策 D22，
    选择了这个含义，而不是 ``profile`` 的其他含义。
* :class:`Conversation` — 属于某个 profile 的 chat thread。它记录当前 active leaf
    message，使客户端能够重建可见 message path。
* :class:`Message` — conversation 中的一条 message，通过 ``parent_id`` 连接到 parent
    并形成 tree。同一 parent 下的 sibling message 是不同的 reply；在它们之间切换就是
    移动 ``conversation.current_leaf_id``。根据决策 D18，学习者需要重新提问并比较答案，
    因此采用这种结构。

此 module 还声明 API layer 使用的轻量 Pydantic request/response model，使
``reasoning_signature`` 等内部 field 不会暴露给客户端。
"""

from __future__ import annotations

from datetime import datetime, timezone
from typing import Literal

from sqlmodel import Field, SQLModel


def _now() -> datetime:
    """以 timezone-aware datetime 返回当前 UTC time。

    使用 helper 而不是 ``datetime.utcnow``，因为后者已 deprecated，并且返回容易误用的
    naive datetime。
    """
    return datetime.now(timezone.utc)


MessageRole = Literal["user", "assistant", "system"]
"""允许的 :attr:`Message.role` value。"""


class Profile(SQLModel, table=True):
    """一组有名称的 conversation。"""

    id: int | None = Field(default=None, primary_key=True)
    name: str = Field(index=True)
    created_at: datetime = Field(default_factory=_now)
    updated_at: datetime = Field(default_factory=_now)


class Conversation(SQLModel, table=True):
    """profile 中的 chat thread。

    ``current_leaf_id`` 指向当前可见 path 上的最后一条 message。完整 path 通过从该 leaf
    沿 ``parent_id`` 回溯到 root 重建，复杂度为 O(depth)，避免 recursive query。
    """

    id: int | None = Field(default=None, primary_key=True)
    profile_id: int = Field(foreign_key="profile.id", index=True, ondelete="CASCADE")
    title: str = ""
    model_id: str = ""
    """该 conversation 的每个 assistant turn 使用的 model。创建时固定（决策 D03）；如需
    使用其他 model，请创建新 conversation。该 value 是 ``config.yaml`` 中某个 entry 的 ``id``。"""
    thinking_effort: str = ""
    """为该 conversation 选择的 thinking-effort level。必须是 model 的 ``thinking_effort``
    field 中列出的 level 之一。可以通过 ``PATCH`` 修改（决策 D05/D09）。"""
    current_leaf_id: int | None = Field(
        default=None,
        foreign_key="message.id",
        ondelete="SET NULL",
    )
    created_at: datetime = Field(default_factory=_now)
    updated_at: datetime = Field(default_factory=_now)


class Message(SQLModel, table=True):
    """conversation tree 中的一个 message node。

    root message 的 ``parent_id`` 为 ``None``。多条 message 可以共享一个 ``parent_id``，
    每条 message 都是该 parent 的一个 alternative reply。服务器向 message streaming
    token 时 ``is_complete`` 为 ``False``，客户端可以显示 placeholder，interrupt recovery
    也可以据此区分 partial message 和已完成 message。

    ``reasoning_signature`` 保存 Anthropic 的 thinking-block signature，使 assistant message
    在后续 turn 作为 history 发送时可以原样 replay 该 block。OpenAI reasoning 没有对应物，
    因此 OpenAI provider 的该 field 为 ``None``。
    """

    id: int | None = Field(default=None, primary_key=True)
    conversation_id: int = Field(
        foreign_key="conversation.id", index=True, ondelete="CASCADE"
    )
    parent_id: int | None = Field(
        default=None, foreign_key="message.id", index=True, ondelete="CASCADE"
    )
    role: str
    """``user``、``assistant``、``system`` 三者之一。由于 SQLModel 不能将 ``Literal`` 映射
    到 column type，这里存储为 plain text；read schema 使用 :data:`MessageRole` 重新收窄 value。"""
    content: str = ""
    reasoning: str | None = None
    reasoning_signature: str | None = None
    image_path: str | None = None
    is_complete: bool = Field(default=True)
    created_at: datetime = Field(default_factory=_now)


# API layer 使用的 request schema（不带 table=True）。

class ConversationCreate(SQLModel):
    """create-conversation request 的 body。

    ``model_id`` 选择该 conversation 使用的 model（决策 D03），必须匹配 ``config.yaml``
    中的 entry，endpoint 会进行校验。

    省略 ``thinking_effort`` 时，默认使用 model 的 ``thinking_effort`` list 中的第一个
    level（决策 D05）。如果提供了值，则必须是 model 列出的 level 之一。
    """

    model_id: str
    title: str = ""
    thinking_effort: str | None = None


class ConversationUpdate(SQLModel):
    """PATCH conversation request 的 body。

    创建后只能修改 ``thinking_effort`` 和 ``title``；``model_id`` 固定不变（决策 D09）。
    两个 field 都是 optional，只有提供的 field 会被应用。
    """

    title: str | None = None
    thinking_effort: str | None = None



class UserMessageCreate(SQLModel):
    """create-user-message request 的 body。

    省略 ``parent_id`` 时，默认为 conversation 的 current leaf，这是向可见 path 追加新问题
    的常见情况。
    """
    parent_id: int | None = None
    text: str
    image_data: str | None = None
    """附加到 message 的图片的可选 base64 data URL。

    图片由 :mod:`app.storage` 解码并存储到磁盘，message 只持久化最终 path。
    """


# 返回给客户端的 response schema（不带 table=True）。

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
    """客户端可以用来获取附加图片的 URL；没有图片时为 ``None``。"""
    is_complete: bool
    created_at: datetime


class SiblingInfo(SQLModel):
    """可见 path 上某个 node 的 sibling message metadata。

    客户端无需获取整棵 tree，就能据此渲染 ``< 2 / 3 >`` version switcher。
    """
    siblings: list[int] = []
    """与该 node 共享 ``parent_id`` 的所有 message ID（包括该 node）。"""
    active_id: int
    """当前可见 path 进入的 sibling ID。"""


class MessageTreeNode(SQLModel):
    """可见 path 上的一条 message 及其 sibling metadata。"""
    message: MessageRead
    siblings: SiblingInfo


class ConversationPath(SQLModel):
    """conversation 的可见 message path。

    按 root 到 current leaf 排序。每个 entry 都是 :class:`MessageTreeNode`，因此客户端
    可以在每一层渲染 version switcher。
    """
    conversation: ConversationRead
    path: list[MessageTreeNode]


class SendMessageResponse(SQLModel):
    """创建 user message 时返回的 response。

    它将新的 user message 与刚创建的 assistant placeholder 组合在一起，客户端应通过
    ``GET /api/chat/stream`` 将 token streaming 到该 placeholder。
    """
    user_message: MessageRead
    assistant_message: MessageRead


class ModelRead(SQLModel):
    """``config.yaml`` 中 model definition 的 client-facing view。

    有意省略 ``api_key``（secret reference）和 ``base_url``（客户端不需要）。
    ``max_tokens`` 也被省略，因为它是上游 output budget，不是客户端要渲染的内容。
    """

    id: str
    display_name: str
    family: str
    protocol: str
    vision: bool
    thinking_effort: list[str]


class ModelsResponse(SQLModel):
    """``GET /api/models`` 的 response。

    携带已配置的 default model id 和可用 model list，使客户端无需 hardcoded protocol
    knowledge 就能渲染 model 和 thinking-effort selector。
    """

    default_model: str
    models: list[ModelRead]

