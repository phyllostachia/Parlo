/// Request bodies for the chat endpoints.
///
/// Kept in its own file so the model files stay focused on the wire shapes the
/// frontend reads, rather than the shapes it writes.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'requests.freezed.dart';
part 'requests.g.dart';

/// The body of `POST /api/conversations/{id}/messages`.
///
/// `parentId` defaults to the conversation's current leaf on the server when
/// omitted, which is the common case for appending a new question to the
/// visible path. `imageData` is a base64 data URL; the server decodes and
/// stores it, returning a fetchable URL on the message.
@freezed
class UserMessageCreate with _$UserMessageCreate {
  /// Creates a request body.
  const factory UserMessageCreate({
    /// The parent message id. `null` means "use the conversation's current
    /// leaf".
    int? parentId,

    /// The user's text. Required even if an image is attached.
    required String text,

    /// An optional base64 data URL for an attached image. The frontend builds
    /// this from the picked/pasted/dropped file before sending.
    String? imageData,
  }) = _UserMessageCreate;

  /// Rebuilds a request body from JSON (mostly useful in tests).
  factory UserMessageCreate.fromJson(Map<String, dynamic> json) =>
      _$UserMessageCreateFromJson(json);
}
