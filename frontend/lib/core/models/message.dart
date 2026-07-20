/// Message tree data models.
///
/// Messages form a tree inside a conversation (architecture decision D18). The
/// visible path is the chain from the root to the conversation's current leaf.
/// Sibling messages under the same parent are alternative replies; switching
/// between them is done by moving the conversation's `current_leaf_id`.
///
/// This file also defines `SendMessageResponse` — the body returned by
/// `POST /api/conversations/{id}/messages`, which bundles the new user message
/// with the freshly-created assistant placeholder that the client then streams
/// tokens into via `GET /api/chat/stream`.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import 'conversation.dart';

part 'message.freezed.dart';
part 'message.g.dart';

/// The role a message plays in a conversation.
///
/// The frontend renders messages differently by role (user messages get a
/// bubble, assistant messages get the markdown block, system is rare). The
/// exhaustiveness check in a `switch` over this enum is real protection, so the
/// role is the one field the architecture chose to make an enum (D4.3).
enum MessageRole {
  /// A message typed by the user.
  user,

  /// A reply produced by the model.
  assistant,

  /// A system-level message. Rare in the UI; included for completeness.
  system,
  ;

  /// Parses the role from the backend string. Falls back to [system] for an
  /// unknown value so the UI never crashes on a future role addition.
  static MessageRole fromString(String value) {
    switch (value) {
      case 'user':
        return MessageRole.user;
      case 'assistant':
        return MessageRole.assistant;
      default:
        return MessageRole.system;
    }
  }
}

/// A single message node in a conversation tree.
///
/// `parentId` is `null` for a root message. `isComplete` is `false` while the
/// server is still streaming tokens into the message, so the UI can show a
/// loading state. `imageUrl` is the path the client can fetch the attached
/// image from, if any.
@freezed
class Message with _$Message {
  /// Creates a message.
  const factory Message({
    /// The server-assigned identifier.
    required int id,

    /// The conversation this message belongs to.
    required int conversationId,

    /// The parent message id, or `null` for a root message.
    required int? parentId,

    /// Who produced this message.
    required MessageRole role,

    /// The text body. Empty while the assistant is still streaming.
    required String content,

    /// The model's reasoning (the "thinking" trace), if any. `null` for user
    /// messages and for assistant messages whose model produced none.
    required String? reasoning,

    /// The URL the client can fetch the attached image from, if any. `null`
    /// means no image.
    required String? imageUrl,

    /// `false` while the server is still streaming tokens into this message.
    /// Note: the backend sets this to `true` in its `finally` block, so a
    /// broken stream also ends with `is_complete = true`. The frontend keeps
    /// its own [StreamState] to tell the difference (architecture §5.4).
    required bool isComplete,

    /// When the message was created.
    required DateTime createdAt,
  }) = _Message;

  /// Rebuilds a message from the JSON returned by the backend.
  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);
}

/// Metadata about the sibling messages of a node on the visible path.
///
/// Lets the client render a `< n / m >` version switcher without fetching the
/// whole tree. `siblings` lists every message sharing this node's `parent_id`
/// (including this node itself); `activeId` is the one the visible path
/// currently descends into.
@freezed
class SiblingInfo with _$SiblingInfo {
  /// Creates sibling metadata.
  const factory SiblingInfo({
    /// All message ids that share this node's parent, including this node.
    @Default(<int>[]) List<int> siblings,

    /// The id of the sibling the visible path currently goes through.
    required int activeId,
  }) = _SiblingInfo;

  /// Rebuilds sibling metadata from JSON.
  factory SiblingInfo.fromJson(Map<String, dynamic> json) =>
      _$SiblingInfoFromJson(json);
}

/// A message on the visible path paired with its sibling metadata.
@freezed
class MessageTreeNode with _$MessageTreeNode {
  /// Creates a tree node.
  const factory MessageTreeNode({
    /// The message at this position on the path.
    required Message message,

    /// The sibling metadata used to render the version switcher.
    required SiblingInfo siblings,
  }) = _MessageTreeNode;

  /// Rebuilds a tree node from JSON.
  factory MessageTreeNode.fromJson(Map<String, dynamic> json) =>
      _$MessageTreeNodeFromJson(json);
}

/// The visible message path of a conversation, ordered root → current leaf.
///
/// This is the single source of truth the chat screen renders from. Every
/// entry is a [MessageTreeNode] so a version switcher can appear at any level
/// of the path, not just at the leaf.
@freezed
class ConversationPath with _$ConversationPath {
  /// Creates a conversation path.
  const factory ConversationPath({
    /// The conversation this path belongs to.
    required Conversation conversation,

    /// The visible messages, from root to the current leaf.
    @Default(<MessageTreeNode>[]) List<MessageTreeNode> path,
  }) = _ConversationPath;

  /// Rebuilds a path from JSON returned by the backend.
  factory ConversationPath.fromJson(Map<String, dynamic> json) =>
      _$ConversationPathFromJson(json);
}

/// The response of `POST /api/conversations/{id}/messages`.
///
/// Bundles the newly-created user message together with the freshly-created
/// assistant placeholder that the client should stream tokens into via
/// `GET /api/chat/stream?message_id=...`.
@freezed
class SendMessageResponse with _$SendMessageResponse {
  /// Creates the response wrapper.
  const factory SendMessageResponse({
    /// The user message that was just persisted.
    required Message userMessage,

    /// The empty assistant placeholder to stream tokens into.
    required Message assistantMessage,
  }) = _SendMessageResponse;

  /// Rebuilds the response wrapper from JSON.
  factory SendMessageResponse.fromJson(Map<String, dynamic> json) =>
      _$SendMessageResponseFromJson(json);
}
