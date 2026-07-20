/// The `Conversation` data model and its create/update request bodies.
///
/// A conversation is a chat thread that belongs to one profile and is bound to
/// a single model for its whole lifetime (architecture decision D03). Only the
/// title and the thinking-effort level can be changed after creation.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'conversation.freezed.dart';
part 'conversation.g.dart';

/// A chat thread inside a profile, bound to a single model.
///
/// `currentLeafId` points at the last message on the visible path; the path is
/// reconstructed on the server by walking `parent_id` from this leaf back to the
/// root. `null` means the conversation has no messages yet.
@freezed
class Conversation with _$Conversation {
  /// Creates a conversation.
  const factory Conversation({
    /// The server-assigned identifier, used in the `/c/{id}` URL.
    required int id,

    /// The profile this conversation belongs to.
    required int profileId,

    /// The human-readable title. Empty until the first message is sent.
    required String title,

    /// The model id from `config.yaml`. Fixed at creation; to use another
    /// model, create a new conversation.
    required String modelId,

    /// The thinking-effort level for this conversation. One of the levels
    /// listed in the bound model's `thinking_effort` field. Changeable via
    /// `PATCH`.
    required String thinkingEffort,

    /// The id of the last message on the visible path, or `null` if the
    /// conversation has no messages yet.
    required int? currentLeafId,

    /// When the conversation was created.
    required DateTime createdAt,

    /// When the conversation was last updated. Used for sidebar sorting.
    required DateTime updatedAt,
  }) = _Conversation;

  /// Rebuilds a conversation from the JSON returned by the backend.
  factory Conversation.fromJson(Map<String, dynamic> json) =>
      _$ConversationFromJson(json);
}

/// The body of a `POST /api/profiles/{id}/conversations` request.
///
/// `thinkingEffort` is optional; when omitted, the backend defaults to the
/// first level in the model's `thinking_effort` list (decision D05).
@freezed
class ConversationCreate with _$ConversationCreate {
  /// Creates a request body.
  const factory ConversationCreate({
    /// The model id to bind to this conversation.
    required String modelId,

    /// An optional starting title. Usually left empty until the first turn.
    @Default('') String title,

    /// An optional thinking-effort level. Must be one of the model's listed
    /// levels; `null` means "use the model's default".
    String? thinkingEffort,
  }) = _ConversationCreate;

  /// Rebuilds a request body from JSON (mostly useful in tests).
  factory ConversationCreate.fromJson(Map<String, dynamic> json) =>
      _$ConversationCreateFromJson(json);
}

/// The body of a `PATCH /api/conversations/{id}` request.
///
/// Both fields are optional. Only the provided ones are applied on the server.
/// `modelId` is intentionally absent: the model is fixed for the conversation's
/// lifetime (decision D09).
@freezed
class ConversationUpdate with _$ConversationUpdate {
  /// Creates a request body.
  const factory ConversationUpdate({
    /// The new title, if changing it.
    String? title,

    /// The new thinking-effort level, if changing it. Must be one of the
    /// model's supported levels.
    String? thinkingEffort,
  }) = _ConversationUpdate;

  /// Rebuilds a request body from JSON (mostly useful in tests).
  factory ConversationUpdate.fromJson(Map<String, dynamic> json) =>
      _$ConversationUpdateFromJson(json);
}
