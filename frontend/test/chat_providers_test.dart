/// Unit tests for the [CurrentConversationNotifier] send / stream state
/// machine.
///
/// These tests mock dio so they run without a backend. They verify the
/// critical path the architecture (Phase 7.1) calls out: sending a message
/// appends the user + assistant placeholder to the local path, the SSE
/// stream fills the assistant message, and the stream state transitions
/// through `streaming` to `done`.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:parlo/core/auth/auth_providers.dart';
import 'package:parlo/core/models/message.dart';
import 'package:parlo/core/network/api_client.dart';
import 'package:parlo/features/chat/chat_providers.dart';

/// A mock Dio used by the notifier tests.
class _MockDio extends Mock implements Dio {}

/// The conversation id used in every test.
const _conversationId = 1;

void main() {
  late _MockDio dio;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();

    dio = _MockDio();
    _registerFallbackValues();

    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        dioProvider.overrideWithValue(dio),
      ],
    );
    addTearDown(container.dispose);
    // Keep the conversation provider alive so autoDispose does not reclaim it
    // between `read` calls in the test body. Without this listener, the family
    // instance disposes as soon as `read` returns, and a later `read` would
    // re-build (showing AsyncLoading) instead of seeing the patched state.
    final sub = container.listen(
      currentConversationProvider(_conversationId),
      (_, _) {},
    );
    addTearDown(sub.close);
  });

  test('send appends user + assistant and streams tokens into the assistant',
      () async {
    _stubPathLoad(dio, empty: true);
    _stubSendMessage(dio);
    _stubStream(
      dio,
      <String>[
        'event: started\ndata: {"message_id":11}\n\n',
        'event: text_delta\ndata: {"content":"Hello"}\n\n',
        'event: text_delta\ndata: {"content":" world"}\n\n',
        'event: done\ndata: {}\n\n',
      ],
    );

    final doneState = Completer<void>();
    container.listen<StreamState>(streamStateProvider, (_, next) {
      if (next == StreamState.done && !doneState.isCompleted) {
        doneState.complete();
      }
    });

    final notifier = container.read(
      currentConversationProvider(_conversationId).notifier,
    );
    await container.read(currentConversationProvider(_conversationId).future);

    await notifier.send(text: 'Hello world');

    await doneState.future.timeout(const Duration(seconds: 5));

    final path = container
        .read(currentConversationProvider(_conversationId))
        .requireValue;

    expect(path.path, hasLength(2));
    expect(path.path[0].message.role, MessageRole.user);
    expect(path.path[0].message.content, 'Hello world');
    expect(path.path[1].message.role, MessageRole.assistant);
    expect(path.path[1].message.content, 'Hello world');
    expect(path.path[1].message.isComplete, isTrue);

    expect(container.read(streamStateProvider), StreamState.done);
  });

  test('stop cancels the stream and marks the assistant message complete',
      () async {
    _stubPathLoad(dio, empty: true);
    _stubSendMessage(dio);

    final streamController = StreamController<Uint8List>();
    _stubStreamFromController(dio, streamController);

    final streamingSeen = Completer<void>();
    container.listen<StreamState>(streamStateProvider, (_, next) {
      if (next == StreamState.streaming && !streamingSeen.isCompleted) {
        streamingSeen.complete();
      }
    });

    final notifier = container.read(
      currentConversationProvider(_conversationId).notifier,
    );
    await container.read(currentConversationProvider(_conversationId).future);

    await notifier.send(text: 'Stop me');

    streamController.add(_encode(
      'event: started\ndata: {"message_id":11}\n\n',
    ));
    streamController.add(_encode(
      'event: text_delta\ndata: {"content":"Hi"}\n\n',
    ));
    await streamingSeen.future.timeout(const Duration(seconds: 5));

    // Give the text_delta a moment to be processed before we cancel.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await notifier.stop();

    final path = container
        .read(currentConversationProvider(_conversationId))
        .requireValue;
    expect(path.path[1].message.content, 'Hi');
    expect(path.path[1].message.isComplete, isTrue);
    expect(container.read(streamStateProvider), StreamState.stopped);

    await streamController.close();
  });

  test('a stream error transitions the stream state to error', () async {
    _stubPathLoad(dio, empty: true);
    _stubSendMessage(dio);
    _stubStream(
      dio,
      <String>[
        'event: started\ndata: {"message_id":11}\n\n',
        'event: error\ndata: {"message":"boom"}\n\n',
      ],
    );

    final errorSeen = Completer<void>();
    container.listen<StreamState>(streamStateProvider, (_, next) {
      if (next == StreamState.error && !errorSeen.isCompleted) {
        errorSeen.complete();
      }
    });

    final notifier = container.read(
      currentConversationProvider(_conversationId).notifier,
    );
    await container.read(currentConversationProvider(_conversationId).future);

    await notifier.send(text: 'Hello');

    await errorSeen.future.timeout(const Duration(seconds: 5));
    expect(container.read(streamStateProvider), StreamState.error);
  });

  test('regenerate replaces the last assistant with a new sibling and streams '
      'into the new placeholder', () async {
    _stubPathLoadWithAssistant(dio);
    _stubRegenerate(dio, newAssistantId: 12, parentId: 10);
    _stubStream(
      dio,
      <String>[
        'event: started\ndata: {"message_id":12}\n\n',
        'event: text_delta\ndata: {"content":"Fresh"}\n\n',
        'event: done\ndata: {}\n\n',
      ],
    );

    final doneState = Completer<void>();
    container.listen<StreamState>(streamStateProvider, (_, next) {
      if (next == StreamState.done && !doneState.isCompleted) {
        doneState.complete();
      }
    });

    final notifier = container.read(
      currentConversationProvider(_conversationId).notifier,
    );
    await container.read(currentConversationProvider(_conversationId).future);

    await notifier.regenerate(assistantMessageId: 11);

    await doneState.future.timeout(const Duration(seconds: 5));

    final path = container
        .read(currentConversationProvider(_conversationId))
        .requireValue;

    // The path still has two nodes: the user message and the new assistant.
    expect(path.path, hasLength(2));
    expect(path.path[0].message.role, MessageRole.user);
    expect(path.path[1].message.role, MessageRole.assistant);
    expect(path.path[1].message.id, 12);
    expect(path.path[1].message.content, 'Fresh');
    expect(path.path[1].message.isComplete, isTrue);
    // The siblings list grew: the old assistant (11) and the new one (12).
    expect(path.path[1].siblings.siblings, containsAll(<int>[11, 12]));
    expect(path.path[1].siblings.activeId, 12);
  });

  test('switchBranch replaces the visible path with the backend response',
      () async {
    _stubPathLoadWithAssistant(dio);
    _stubSwitchBranch(
      dio,
      leafId: 99,
      newAssistantContent: 'Switched reply',
      newSiblingIds: const <int>[11, 99],
    );

    final notifier = container.read(
      currentConversationProvider(_conversationId).notifier,
    );
    await container.read(currentConversationProvider(_conversationId).future);

    await notifier.switchBranch(leafId: 99);

    final path = container
        .read(currentConversationProvider(_conversationId))
        .requireValue;

    expect(path.path.last.message.id, 99);
    expect(path.path.last.message.content, 'Switched reply');
    expect(path.path.last.siblings.siblings, <int>[11, 99]);
    expect(path.path.last.siblings.activeId, 99);
  });
}

/// Registers fallback values so `any(named: ...)` works for dio's arguments.
void _registerFallbackValues() {
  registerFallbackValue(Options());
  registerFallbackValue(<String, dynamic>{});
}

/// Encodes a string to UTF-8 bytes as a [Uint8List], the shape dio's stream
/// returns.
Uint8List _encode(String source) => Uint8List.fromList(utf8.encode(source));

/// The shared conversation JSON used by every path-load stub.
Map<String, dynamic> _conversationJson() {
  return <String, dynamic>{
    'id': 1,
    'profile_id': 1,
    'title': 'Test',
    'model_id': 'm1',
    'thinking_effort': 'low',
    'current_leaf_id': null,
    'created_at': '2026-07-01T00:00:00Z',
    'updated_at': '2026-07-01T00:00:00Z',
  };
}

/// Stubs `GET /api/conversations/1/messages` to return an empty (or one-node)
/// path.
void _stubPathLoad(_MockDio dio, {required bool empty}) {
  final data = <String, dynamic>{
    'conversation': _conversationJson(),
    'path': <dynamic>[
      if (!empty)
        {
          'message': {
            'id': 5,
            'conversation_id': 1,
            'parent_id': null,
            'role': 'user',
            'content': 'earlier',
            'reasoning': null,
            'image_url': null,
            'is_complete': true,
            'created_at': '2026-07-01T00:00:00Z',
          },
          'siblings': {'siblings': <int>[5], 'active_id': 5},
        },
    ],
  };
  when(() => dio.get<Map<String, dynamic>>('/api/conversations/1/messages'))
      .thenAnswer((_) async => Response<Map<String, dynamic>>(
            data: data,
            requestOptions:
                RequestOptions(path: '/api/conversations/1/messages'),
          ));}

/// Stubs `POST /api/conversations/1/messages` to return a user message and an
/// assistant placeholder. The user message's `content` echoes the text the
/// caller sent (the real backend does the same), so tests that check the
/// rendered user bubble get the right value.
void _stubSendMessage(_MockDio dio, {int assistantId = 11}) {
  when(() => dio.post<Map<String, dynamic>>(
        '/api/conversations/1/messages',
        data: any(named: 'data'),
      )).thenAnswer((invocation) async {
    final body = invocation.namedArguments[const Symbol('data')]
        as Map<String, dynamic>;
    final text = (body['text'] as String?) ?? '';
    final data = <String, dynamic>{
      'user_message': <String, dynamic>{
        'id': 10,
        'conversation_id': 1,
        'parent_id': null,
        'role': 'user',
        'content': text,
        'reasoning': null,
        'image_url': null,
        'is_complete': true,
        'created_at': '2026-07-01T00:00:00Z',
      },
      'assistant_message': <String, dynamic>{
        'id': assistantId,
        'conversation_id': 1,
        'parent_id': 10,
        'role': 'assistant',
        'content': '',
        'reasoning': null,
        'image_url': null,
        'is_complete': false,
        'created_at': '2026-07-01T00:00:00Z',
      },
    };
    return Response<Map<String, dynamic>>(
      data: data,
      requestOptions:
          RequestOptions(path: '/api/conversations/1/messages'),
    );
  });
}

/// Stubs `GET /api/chat/stream` to emit the given SSE byte chunks.
void _stubStream(_MockDio dio, List<String> chunks) {
  final bytes = <int>[];
  for (final chunk in chunks) {
    bytes.addAll(_encode(chunk));
  }
  final uint8 = Uint8List.fromList(bytes);
  final body = ResponseBody(
    Stream<Uint8List>.value(uint8),
    200,
    headers: const <String, List<String>>{
      'content-type': <String>['text/event-stream'],
    },
  );
  when(() => dio.get<ResponseBody>(
        '/api/chat/stream',
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      )).thenAnswer((_) async => Response<ResponseBody>(
        data: body,
        requestOptions: RequestOptions(path: '/api/chat/stream'),
      ));
}

/// Stubs `GET /api/chat/stream` to return bytes from a controller the test
/// controls.
void _stubStreamFromController(
  _MockDio dio,
  StreamController<Uint8List> controller,
) {
  final body = ResponseBody(
    controller.stream,
    200,
    headers: const <String, List<String>>{
      'content-type': <String>['text/event-stream'],
    },
  );
  when(() => dio.get<ResponseBody>(
        '/api/chat/stream',
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      )).thenAnswer((_) async => Response<ResponseBody>(
        data: body,
        requestOptions: RequestOptions(path: '/api/chat/stream'),
      ));
}

/// Stubs `GET /api/conversations/1/messages` to return a path with one user
/// message and one complete assistant message. Used by the regenerate and
/// switchBranch tests, which need an existing assistant to act on.
void _stubPathLoadWithAssistant(_MockDio dio) {
  final data = <String, dynamic>{
    'conversation': _conversationJson(),
    'path': <dynamic>[
      {
        'message': <String, dynamic>{
          'id': 10,
          'conversation_id': 1,
          'parent_id': null,
          'role': 'user',
          'content': 'Hi',
          'reasoning': null,
          'image_url': null,
          'is_complete': true,
          'created_at': '2026-07-01T00:00:00Z',
        },
        'siblings': <String, dynamic>{
          'siblings': <int>[10],
          'active_id': 10,
        },
      },
      {
        'message': <String, dynamic>{
          'id': 11,
          'conversation_id': 1,
          'parent_id': 10,
          'role': 'assistant',
          'content': 'Old reply',
          'reasoning': null,
          'image_url': null,
          'is_complete': true,
          'created_at': '2026-07-01T00:00:00Z',
        },
        'siblings': <String, dynamic>{
          'siblings': <int>[11],
          'active_id': 11,
        },
      },
    ],
  };
  when(() => dio.get<Map<String, dynamic>>('/api/conversations/1/messages'))
      .thenAnswer((_) async => Response<Map<String, dynamic>>(
            data: data,
            requestOptions:
                RequestOptions(path: '/api/conversations/1/messages'),
          ));
}

/// Stubs `POST /api/conversations/1/messages/{parentId}/regenerate` to
/// return a new empty assistant placeholder with the given id.
void _stubRegenerate(
  _MockDio dio, {
  required int newAssistantId,
  required int parentId,
}) {
  final data = <String, dynamic>{
    'id': newAssistantId,
    'conversation_id': 1,
    'parent_id': parentId,
    'role': 'assistant',
    'content': '',
    'reasoning': null,
    'image_url': null,
    'is_complete': false,
    'created_at': '2026-07-01T00:00:00Z',
  };
  when(() => dio.post<Map<String, dynamic>>(
        '/api/conversations/1/messages/$parentId/regenerate',
      )).thenAnswer((_) async => Response<Map<String, dynamic>>(
        data: data,
        requestOptions: RequestOptions(
          path: '/api/conversations/1/messages/$parentId/regenerate',
        ),
      ));
}

/// Stubs `POST /api/conversations/1/messages/{leafId}/switch` to return a
/// new conversation path whose last assistant has the given content and
/// sibling ids.
void _stubSwitchBranch(
  _MockDio dio, {
  required int leafId,
  required String newAssistantContent,
  required List<int> newSiblingIds,
}) {
  final data = <String, dynamic>{
    'conversation': _conversationJson(),
    'path': <dynamic>[
      {
        'message': <String, dynamic>{
          'id': 10,
          'conversation_id': 1,
          'parent_id': null,
          'role': 'user',
          'content': 'Hi',
          'reasoning': null,
          'image_url': null,
          'is_complete': true,
          'created_at': '2026-07-01T00:00:00Z',
        },
        'siblings': <String, dynamic>{
          'siblings': <int>[10],
          'active_id': 10,
        },
      },
      {
        'message': <String, dynamic>{
          'id': leafId,
          'conversation_id': 1,
          'parent_id': 10,
          'role': 'assistant',
          'content': newAssistantContent,
          'reasoning': null,
          'image_url': null,
          'is_complete': true,
          'created_at': '2026-07-01T00:00:00Z',
        },
        'siblings': <String, dynamic>{
          'siblings': newSiblingIds,
          'active_id': leafId,
        },
      },
    ],
  };
  when(() => dio.post<Map<String, dynamic>>(
        '/api/conversations/1/messages/$leafId/switch',
      )).thenAnswer((_) async => Response<Map<String, dynamic>>(
        data: data,
        requestOptions: RequestOptions(
          path: '/api/conversations/1/messages/$leafId/switch',
        ),
      ));
}
