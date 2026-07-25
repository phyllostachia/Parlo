/// 将 backend chat stream endpoint 的 Server-Sent Events 解析为 [SseEvent] object。
///
/// Backend（参见 `backend/app/api/chat.py`）每次 assistant token update 发出一个 event。
/// Wire format 遵循 SSE standard：
///
/// ```
/// event: text_delta
/// data: {"content":"Hello"}
///
/// ```
///
/// 一个 event 由一条或多条 field line 组成，并以空行结束。我们只关心 `event:` 和 `data:`
/// field；`id:`、`retry:` 和 comment（以 `:` 开头的 line）会被忽略。`data:` payload 是
/// JSON，event type 决定要构建哪个 [SseEvent] subtype。
///
/// Parser 必须处理一个 SSE event 被拆分到多个 byte chunk 中的情况，也必须处理一个 chunk
/// 包含多个 event 的情况。我们持续 buffer，直到看到空行后再 emit。
///
/// 实现注意：使用带有显式 `onCancel` 的 [StreamController]，在取消时取消 upstream
/// subscription。这样 `stop()` 可以正确传递并关闭底层 HTTP connection，而不依赖
/// `async*` generator 的 `await for` 释放；后者可能在 `cast().transform()` chain 中卡住。
library;

import 'dart:async';
import 'dart:convert';

import '../models/sse_event.dart';

/// 将 `/api/chat/stream` 的 byte stream 解析为 [SseEvent] stream。
///
/// 用法：
/// ```dart
/// final response = await dio.get<ResponseBody>(
///   '/api/chat/stream',
///   queryParameters: {'message_id': messageId},
///   options: Options(responseType: ResponseType.stream),
/// );
/// final sub = parseSseStream(response.data!.stream).listen((event) {
///   // 处理 event
/// });
/// // 稍后：
/// await sub.cancel();  // 关闭 HTTP connection
/// ```
Stream<SseEvent> parseSseStream(Stream<List<int>> byteStream) {
  // dio 的 `ResponseBody.stream` 是 `Stream<Uint8List>`；`utf8.decoder` 是
  // `StreamTransformer<List<int>, String>`。将每个 chunk cast 为 `List<int>`，使 transform
  // 在 runtime 通过 type check（Uint8List 是 List<int>，因此 cast 成本低且不会失败）。
  final stringStream = byteStream.cast<List<int>>().transform(utf8.decoder);

  final controller = StreamController<SseEvent>();
  var buffer = '';

  late StreamSubscription<String> upstreamSub;
  upstreamSub = stringStream.listen(
    (chunk) {
      // 统一 line ending，使 `\n` 和 `\r\n` 都能工作。
      buffer = (buffer + chunk).replaceAll('\r\n', '\n').replaceAll('\r', '\n');

      // Emit buffer 中的每个完整 event。完整 event 以空行（`\n\n`）结尾。
      while (true) {
        final sep = buffer.indexOf('\n\n');
        if (sep == -1) break;
        final rawEvent = buffer.substring(0, sep);
        buffer = buffer.substring(sep + 2);
        final event = _parseRawEvent(rawEvent);
        if (event != null) {
          controller.add(event);
        }
      }
    },
    onError: controller.addError,
    onDone: () {
      // 如果 stream 结束时没有 trailing blank line，则 emit 剩余内容。Backend 通常会正常
      // 结束，但 dropped connection 可能在 buffer 中留下 partial event。
      if (buffer.isNotEmpty) {
        final event = _parseRawEvent(buffer);
        if (event != null) {
          controller.add(event);
        }
      }
      controller.close();
    },
  );

  // consumer 取消时（例如用户按下 stop），取消 upstream subscription，使底层 HTTP
  // connection 关闭。
  controller.onCancel = () => upstreamSub.cancel();

  return controller.stream;
}

/// 将一个 SSE event block（两个空行之间的 text）解析为 [SseEvent]；如果 block 没有
/// `event:` field 或 event type 未知，则返回 `null`。
SseEvent? _parseRawEvent(String raw) {
  String? eventType;
  final dataLines = <String>[];

  for (final line in raw.split('\n')) {
    if (line.isEmpty || line.startsWith(':')) {
      // 忽略空行和 comment line。这里通常不会看到空行（它们是 event terminator），但
      // 防御性处理成本很低。
      continue;
    }
    const eventPrefix = 'event:';
    const dataPrefix = 'data:';
    if (line.startsWith(eventPrefix)) {
      // SSE 会去除冒号后的一个可选 leading space。
      eventType = line.substring(eventPrefix.length).trim();
    } else if (line.startsWith(dataPrefix)) {
      var value = line.substring(dataPrefix.length);
      if (value.startsWith(' ')) {
        value = value.substring(1);
      }
      dataLines.add(value);
    }
  }

  if (eventType == null) {
    return null;
  }
  // 根据 SSE spec，多条 `data:` line 使用 `\n` 连接。Backend 总是发送一条 `data:` line，
  // 但这里仍遵循 spec。
  final data = dataLines.join('\n');

  return _buildEvent(eventType, data);
}

/// 根据给定的 event type 和 JSON data 构建正确的 [SseEvent] subtype。
///
/// 未知 event type 返回 `null`，使 parser 不会因 backend 将来发送的新 event 而抛出异常。
SseEvent? _buildEvent(String type, String data) {
  // Helper：将 data 解码为 JSON；不是有效 object 时返回 null。这里保持宽容，因为损坏的
  // data line 不应导致整个 stream 崩溃。
  Map<String, dynamic> decodeObject() {
    if (data.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(data);
    if (decoded is Map<String, dynamic>) return decoded;
    return <String, dynamic>{};
  }

  // Helper：读取 required String field；缺失时回退为 ''。
  String readString(Map<String, dynamic> obj, String key) {
    final value = obj[key];
    return value is String ? value : '';
  }

  // Helper：读取 required int field；缺失时回退为 0。
  int readInt(Map<String, dynamic> obj, String key) {
    final value = obj[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  switch (type) {
    case 'started':
      final obj = decodeObject();
      return SseEvent.started(messageId: readInt(obj, 'message_id'));
    case 'text_delta':
      final obj = decodeObject();
      return SseEvent.textDelta(content: readString(obj, 'content'));
    case 'reasoning_delta':
      final obj = decodeObject();
      return SseEvent.reasoningDelta(content: readString(obj, 'content'));
    case 'reasoning_signature':
      final obj = decodeObject();
      return SseEvent.reasoningSignature(content: readString(obj, 'content'));
    case 'error':
      final obj = decodeObject();
      return SseEvent.error(message: readString(obj, 'message'));
    case 'done':
      return const SseEvent.done();
    default:
      // 未知 event type：忽略，而不是崩溃。
      return null;
  }
}
