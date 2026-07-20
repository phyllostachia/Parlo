/// Unit tests for the SSE parser.
///
/// The backend emits Server-Sent Events with a known wire format (see
/// `backend/app/api/chat.py`). These tests pin down the parser's behavior on
/// the shapes the backend actually sends, including the tricky case where one
/// event is split across two byte chunks.
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
      // The first chunk cuts off mid-event. The parser must buffer until the
      // closing blank line arrives.
      final chunk1 = _encode(
        'event: reasoning_delta\n'
        'data: {"content":"Think',
      );
      final chunk2 = _encode(
        'ing"}\n\n',
      );
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
      // A dropped connection can leave a fully-formed event in the buffer
      // without a trailing `\n\n`. The parser should still emit it.
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

      // The unknown event is dropped; the known one is kept.
      expect(events, hasLength(1));
      expect((events.first as SseTextDelta).content, 'ok');
    });
  });
}

/// Encodes a string to a list of UTF-8 bytes, the shape dio's stream returns.
List<int> _encode(String source) => source.codeUnits;
