/// The `SseEvent` sealed class and its six subtypes.
///
/// The backend streams assistant replies as Server-Sent Events (architecture
/// section 5). Each event is a single `event: <type>` plus a `data: <json>`
/// pair on the wire. The SSE parser turns those bytes into one of these six
/// subtypes; the chat notifier switches over them to update the in-flight
/// assistant message.
///
/// This is a `sealed` class so `switch` expressions over the six subtypes are
/// checked for exhaustiveness by the compiler.
///
/// These types are constructed by the parser, not deserialized wholesale from
/// JSON, so this file has no `.g.dart` companion.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'sse_event.freezed.dart';

/// One Server-Sent Event emitted by the backend's chat stream endpoint.
@freezed
sealed class SseEvent with _$SseEvent {
  /// The first event of every stream. Carries the assistant message id that the
  /// stream writes into.
  const factory SseEvent.started({
    /// The id of the assistant placeholder this stream is filling.
    required int messageId,
  }) = SseStarted;

  /// A chunk of assistant body text. Append to the message's `content`.
  const factory SseEvent.textDelta({
    /// The text to append.
    required String content,
  }) = SseTextDelta;

  /// A chunk of model reasoning ("thinking"). Append to the message's
  /// `reasoning`.
  const factory SseEvent.reasoningDelta({
    /// The reasoning text to append.
    required String content,
  }) = SseReasoningDelta;

  /// A signature that lets the upstream replay the thinking block verbatim on
  /// a later turn. Stored on the message; not shown in the UI.
  const factory SseEvent.reasoningSignature({
    /// The signature string.
    required String content,
  }) = SseReasoningSignature;

  /// An error from the upstream provider or the stream itself. Stops the
  /// stream; the UI shows a "connection broken, retry" button.
  const factory SseEvent.error({
    /// A human-readable error message.
    required String message,
  }) = SseError;

  /// The stream finished cleanly. The message is now complete.
  const factory SseEvent.done() = SseDone;
}
