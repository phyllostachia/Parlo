/// `SseEvent` sealed class 及其六个 subtype。
///
/// Backend 将 assistant reply 作为 Server-Sent Events streaming（架构第 5 节）。每个 event
/// 在 wire 上由一个 `event: <type>` 和一个 `data: <json>` pair 组成。SSE parser 将这些
/// bytes 转换为六个 subtype 之一；chat notifier 根据它们 switch，以更新正在处理的 assistant
/// message。
///
/// 这是 `sealed` class，因此 compiler 会检查覆盖六个 subtype 的 `switch` expression 是否
/// exhaustiveness。
///
/// 这些 type 由 parser 构造，而不是从 JSON 整体 deserialize，因此此 file 没有 `.g.dart`
/// companion。
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'sse_event.freezed.dart';

/// Backend chat stream endpoint 发出的一个 Server-Sent Event。
@freezed
sealed class SseEvent with _$SseEvent {
  /// 每个 stream 的第一个 event。携带 stream 要写入的 assistant message id。
  const factory SseEvent.started({
    /// 此 stream 正在填充的 assistant placeholder id。
    required int messageId,
  }) = SseStarted;

  /// 一段 assistant body text。追加到 message 的 `content`。
  const factory SseEvent.textDelta({
    /// 要追加的 text。
    required String content,
  }) = SseTextDelta;

  /// 一段 model reasoning（“thinking”）。追加到 message 的 `reasoning`。
  const factory SseEvent.reasoningDelta({
    /// 要追加的 reasoning text。
    required String content,
  }) = SseReasoningDelta;

  /// 允许上游在后续 turn 原样 replay thinking block 的 signature。存储在 message 上，不在
  /// UI 中显示。
  const factory SseEvent.reasoningSignature({
    /// 签名 string。
    required String content,
  }) = SseReasoningSignature;

  /// 来自上游 provider 或 stream 本身的 error。它会停止 stream；UI 显示“connection broken,
  /// retry” button。
  const factory SseEvent.error({
    /// 可读的 error message。
    required String message,
  }) = SseError;

  /// Stream 正常完成。Message 现在已完成。
  const factory SseEvent.done() = SseDone;
}
