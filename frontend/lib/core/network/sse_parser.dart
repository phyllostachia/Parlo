/// Parses Server-Sent Events from the backend's chat stream endpoint into
/// [SseEvent] objects.
///
/// The backend (see `backend/app/api/chat.py`) emits one event per assistant
/// token update. The wire format follows the SSE standard:
///
/// ```
/// event: text_delta
/// data: {"content":"Hello"}
///
/// ```
///
/// An event is one or more field lines, terminated by a blank line. We only
/// care about the `event:` and `data:` fields; `id:`, `retry:`, and comments
/// (lines starting with `:`) are ignored. The `data:` payload is JSON; the
/// event type decides which [SseEvent] subtype we build.
///
/// The parser must handle the case where a single SSE event arrives split
/// across several byte chunks, and the case where one chunk contains several
/// events. We buffer until we see a blank line, then emit.
///
/// Implementation note: we use a [StreamController] with an explicit
/// `onCancel` that cancels the upstream subscription. This makes `stop()`
/// propagate cleanly (closing the underlying HTTP connection) instead of
/// relying on an `async*` generator's `await for` to release, which can hang
/// through a `cast().transform()` chain.
library;

import 'dart:async';
import 'dart:convert';

import '../models/sse_event.dart';

/// Parses a byte stream from `/api/chat/stream` into a stream of [SseEvent].
///
/// Usage:
/// ```dart
/// final response = await dio.get<ResponseBody>(
///   '/api/chat/stream',
///   queryParameters: {'message_id': messageId},
///   options: Options(responseType: ResponseType.stream),
/// );
/// final sub = parseSseStream(response.data!.stream).listen((event) {
///   // handle event
/// });
/// // later:
/// await sub.cancel();  // closes the HTTP connection
/// ```
Stream<SseEvent> parseSseStream(Stream<List<int>> byteStream) {
  // dio's `ResponseBody.stream` is a `Stream<Uint8List>`; `utf8.decoder` is a
  // `StreamTransformer<List<int>, String>`. Cast each chunk to `List<int>` so
  // the transform type-checks at runtime (Uint8List is a List<int>, so the
  // cast is cheap and never fails).
  final stringStream = byteStream.cast<List<int>>().transform(utf8.decoder);

  final controller = StreamController<SseEvent>();
  var buffer = '';

  late StreamSubscription<String> upstreamSub;
  upstreamSub = stringStream.listen(
    (chunk) {
      // Normalize line endings so both `\n` and `\r\n` work.
      buffer = (buffer + chunk)
          .replaceAll('\r\n', '\n')
          .replaceAll('\r', '\n');

      // Emit every complete event in the buffer. A complete event ends with
      // a blank line (`\n\n`).
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
      // If the stream ends without a trailing blank line, emit whatever is
      // left. The backend always ends cleanly, but a dropped connection can
      // leave a partial event in the buffer.
      if (buffer.isNotEmpty) {
        final event = _parseRawEvent(buffer);
        if (event != null) {
          controller.add(event);
        }
      }
      controller.close();
    },
  );

  // When the consumer cancels (e.g. the user presses stop), cancel the
  // upstream subscription so the underlying HTTP connection closes.
  controller.onCancel = () => upstreamSub.cancel();

  return controller.stream;
}

/// Parses one SSE event block (the text between two blank lines) into an
/// [SseEvent], or returns `null` if the block has no `event:` field or an
/// unknown event type.
SseEvent? _parseRawEvent(String raw) {
  String? eventType;
  final dataLines = <String>[];

  for (final line in raw.split('\n')) {
    if (line.isEmpty || line.startsWith(':')) {
      // Empty lines and comment lines are ignored. We should not see empty
      // lines here (they are the event terminator), but being defensive is
      // cheap.
      continue;
    }
    const eventPrefix = 'event:';
    const dataPrefix = 'data:';
    if (line.startsWith(eventPrefix)) {
      // SSE strips one optional leading space after the colon.
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
  // Per the SSE spec, multiple `data:` lines are joined with `\n`. Our backend
  // always sends one `data:` line, but we follow the spec anyway.
  final data = dataLines.join('\n');

  return _buildEvent(eventType, data);
}

/// Builds the right [SseEvent] subtype for the given event type and JSON data.
///
/// Returns `null` for unknown event types so the parser never throws on a
/// future event the backend starts sending.
SseEvent? _buildEvent(String type, String data) {
  // Helper: decode the data as JSON, returning null if it is not a valid
  // object. We are lenient because a corrupted data line should not crash the
  // whole stream.
  Map<String, dynamic> decodeObject() {
    if (data.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(data);
    if (decoded is Map<String, dynamic>) return decoded;
    return <String, dynamic>{};
  }

  // Helper: read a required String field, falling back to '' if missing.
  String readString(Map<String, dynamic> obj, String key) {
    final value = obj[key];
    return value is String ? value : '';
  }

  // Helper: read a required int field, falling back to 0 if missing.
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
      // Unknown event type: ignore rather than crash.
      return null;
  }
}
