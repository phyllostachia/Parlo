/// SSE parser 的 unit test。
///
/// Backend 以已知 wire format 发出 Server-Sent Events（参见 `backend/app/api/chat.py`）。
/// 这些 test 固定 parser 对 backend 实际发送 shape 的处理行为，包括一个 event 被拆分到
/// 两个 byte chunk 的复杂情况。
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:parlo/core/models/sse_event.dart';
import 'package:parlo/core/network/sse_parser.dart';

void main() {
  group('parseSseStream', () {
    test('parses a single text_delta event', () async {
      final bytes = _encode(
        'event: text_delta\n'
        'data: {"content":"Hello"}\n\n',
      );
      final events = await parseSseStream(Stream.value(bytes)).toList();

      expect(events, hasLength(1));
      expect(events.first, isA<SseTextDelta>());
      expect((events.first as SseTextDelta).content, 'Hello');
    });

    test('parses multiple events in one chunk', () async {
      final bytes = _encode(
        'event: started\n'
        'data: {"message_id":42}\n\n'
        'event: text_delta\n'
        'data: {"content":"Hi"}\n\n'
        'event: done\n'
        'data: {}\n\n',
      );
      final events = await parseSseStream(Stream.value(bytes)).toList();

      expect(events, hasLength(3));
      expect((events[0] as SseStarted).messageId, 42);
      expect((events[1] as SseTextDelta).content, 'Hi');
      expect(events[2], isA<SseDone>());
    });

    test('reassembles an event split across chunks', () async {
      // 第一个 chunk 在 event 中间截断。Parser 必须 buffer，直到 closing blank line 到达。
      final chunk1 = _encode(
        'event: reasoning_delta\n'
        'data: {"content":"Think',
      );
      final chunk2 = _encode('ing"}\n\n');
      final controller = StreamController<List<int>>();
      final eventsFuture = parseSseStream(controller.stream).toList();

      controller.add(chunk1);
      controller.add(chunk2);
      await controller.close();

      final events = await eventsFuture;
      expect(events, hasLength(1));
      expect((events.first as SseReasoningDelta).content, 'Thinking');
    });

    test('parses every event type the backend sends', () async {
      final bytes = _encode(
        'event: started\n'
        'data: {"message_id":7}\n\n'
        'event: reasoning_delta\n'
        'data: {"content":"thinking"}\n\n'
        'event: reasoning_signature\n'
        'data: {"content":"sig-123"}\n\n'
        'event: text_delta\n'
        'data: {"content":"answer"}\n\n'
        'event: error\n'
        'data: {"message":"boom"}\n\n'
        'event: done\n'
        'data: {}\n\n',
      );
      final events = await parseSseStream(Stream.value(bytes)).toList();

      expect(events, hasLength(6));
      expect((events[0] as SseStarted).messageId, 7);
      expect((events[1] as SseReasoningDelta).content, 'thinking');
      expect((events[2] as SseReasoningSignature).content, 'sig-123');
      expect((events[3] as SseTextDelta).content, 'answer');
      expect((events[4] as SseError).message, 'boom');
      expect(events[5], isA<SseDone>());
    });

    test('emits a trailing event with no closing blank line', () async {
      // Dropped connection 可能在 buffer 中留下没有 trailing `\n\n` 的完整 event。Parser
      // 仍应 emit 它。
      final bytes = _encode(
        'event: text_delta\n'
        'data: {"content":"tail"}\n\n'
        'event: text_delta\n'
        'data: {"content":"no-newline"}',
      );
      final events = await parseSseStream(Stream.value(bytes)).toList();

      expect(events, hasLength(2));
      expect((events[0] as SseTextDelta).content, 'tail');
      expect((events[1] as SseTextDelta).content, 'no-newline');
    });

    test('ignores unknown event types instead of throwing', () async {
      final bytes = _encode(
        'event: some_future_event\n'
        'data: {"foo":"bar"}\n\n'
        'event: text_delta\n'
        'data: {"content":"ok"}\n\n',
      );
      final events = await parseSseStream(Stream.value(bytes)).toList();

      // Unknown event 被丢弃；known event 保留。
      expect(events, hasLength(1));
      expect((events.first as SseTextDelta).content, 'ok');
    });
  });
}

/// 将 string 编码为 UTF-8 byte list，即 dio stream 返回的 shape。
List<int> _encode(String source) => source.codeUnits;
