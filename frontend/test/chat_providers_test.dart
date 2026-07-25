/// [CurrentConversationNotifier] send / stream state machine 的 unit test。
///
/// 这些 test mock dio，因此无需 backend 即可运行。它们验证架构（阶段 7.1）强调的关键
/// path：发送 message 会将 user + assistant placeholder 追加到 local path，SSE stream
/// 填充 assistant message，stream state 从 `streaming` 过渡到 `done`。
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

/// Notifier test 使用的 mock Dio。
class _MockDio extends Mock implements Dio {}

/// 每个 test 使用的 conversation id。
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
    // 保持 conversation provider 存活，避免 autoDispose 在 test body 的 `read` call 之间回收
    // 它。没有此 listener 时，family instance 会在 `read` 返回后立即 dispose，后续 `read`
    // 会重新 build（显示 AsyncLoading），而不是看到 patched state。
    final sub = container.listen(
      currentConversationProvider(_conversationId),
      (_, _) {},
    );
    addTearDown(sub.close);
  });

  test(
    'send appends user + assistant and streams tokens into the assistant',
    () async {
      _stubPathLoad(dio, empty: true);
      _stubSendMessage(dio);
      _stubStream(dio, <String>[
        'event: started\ndata: {"message_id":11}\n\n',
        'event: text_delta\ndata: {"content":"Hello"}\n\n',
        'event: text_delta\ndata: {"content":" world"}\n\n',
        'event: done\ndata: {}\n\n',
      ]);

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
    },
  );

  test(
    'stop cancels the stream and marks the assistant message complete',
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

      streamController.add(
        _encode('event: started\ndata: {"message_id":11}\n\n'),
      );
      streamController.add(
        _encode('event: text_delta\ndata: {"content":"Hi"}\n\n'),
      );
      await streamingSeen.future.timeout(const Duration(seconds: 5));

      // 给 text_delta 一点处理时间，再执行 cancel。
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await notifier.stop();

      final path = container
          .read(currentConversationProvider(_conversationId))
          .requireValue;
      expect(path.path[1].message.content, 'Hi');
      expect(path.path[1].message.isComplete, isTrue);
      expect(container.read(streamStateProvider), StreamState.stopped);

      await streamController.close();
    },
  );

  test('a stream error transitions the stream state to error', () async {
    _stubPathLoad(dio, empty: true);
    _stubSendMessage(dio);
    _stubStream(dio, <String>[
      'event: started\ndata: {"message_id":11}\n\n',
      'event: error\ndata: {"message":"boom"}\n\n',
    ]);

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
    _stubStream(dio, <String>[
      'event: started\ndata: {"message_id":12}\n\n',
      'event: text_delta\ndata: {"content":"Fresh"}\n\n',
      'event: done\ndata: {}\n\n',
    ]);

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

    // Path 仍有两个 node：user message 和新的 assistant。
    expect(path.path, hasLength(2));
    expect(path.path[0].message.role, MessageRole.user);
    expect(path.path[1].message.role, MessageRole.assistant);
    expect(path.path[1].message.id, 12);
    expect(path.path[1].message.content, 'Fresh');
    expect(path.path[1].message.isComplete, isTrue);
    // Siblings list 已增长：旧 assistant（11）和新的 assistant（12）。
    expect(path.path[1].siblings.siblings, containsAll(<int>[11, 12]));
    expect(path.path[1].siblings.activeId, 12);
  });

  test(
    'switchBranch replaces the visible path with the backend response',
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
    },
  );
}

/// 注册 fallback value，使 `any(named: ...)` 能用于 dio argument。
void _registerFallbackValues() {
  registerFallbackValue(Options());
  registerFallbackValue(<String, dynamic>{});
}

/// 将 string 编码为 UTF-8 bytes，并作为 [Uint8List] 返回，即 dio stream 返回的 shape。
Uint8List _encode(String source) => Uint8List.fromList(utf8.encode(source));

/// 每个 path-load stub 共用的 conversation JSON。
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

/// Stub `GET /api/conversations/1/messages`，返回 empty（或 one-node）path。
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
          'siblings': {
            'siblings': <int>[5],
            'active_id': 5,
          },
        },
    ],
  };
  when(
    () => dio.get<Map<String, dynamic>>('/api/conversations/1/messages'),
  ).thenAnswer(
    (_) async => Response<Map<String, dynamic>>(
      data: data,
      requestOptions: RequestOptions(path: '/api/conversations/1/messages'),
    ),
  );
}

/// Stub `POST /api/conversations/1/messages`，返回 user message 和 assistant placeholder。
/// User message 的 `content` 会回显调用方发送的 text（真实 backend 也是这样），因此检查
/// rendered user bubble 的 test 能得到正确 value。
void _stubSendMessage(_MockDio dio, {int assistantId = 11}) {
  when(
    () => dio.post<Map<String, dynamic>>(
      '/api/conversations/1/messages',
      data: any(named: 'data'),
    ),
  ).thenAnswer((invocation) async {
    final body =
        invocation.namedArguments[const Symbol('data')] as Map<String, dynamic>;
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
      requestOptions: RequestOptions(path: '/api/conversations/1/messages'),
    );
  });
}

/// Stub `GET /api/chat/stream`，使其 emit 给定的 SSE byte chunk。
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
  when(
    () => dio.get<ResponseBody>(
      '/api/chat/stream',
      queryParameters: any(named: 'queryParameters'),
      options: any(named: 'options'),
    ),
  ).thenAnswer(
    (_) async => Response<ResponseBody>(
      data: body,
      requestOptions: RequestOptions(path: '/api/chat/stream'),
    ),
  );
}

/// Stub `GET /api/chat/stream`，返回由 test 控制的 controller 发出的 bytes。
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
  when(
    () => dio.get<ResponseBody>(
      '/api/chat/stream',
      queryParameters: any(named: 'queryParameters'),
      options: any(named: 'options'),
    ),
  ).thenAnswer(
    (_) async => Response<ResponseBody>(
      data: body,
      requestOptions: RequestOptions(path: '/api/chat/stream'),
    ),
  );
}

/// Stub `GET /api/conversations/1/messages`，返回包含一条 user message 和一条 complete
/// assistant message 的 path。供 regenerate 和 switchBranch test 使用，因为它们需要已有
/// assistant 作为操作目标。
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
  when(
    () => dio.get<Map<String, dynamic>>('/api/conversations/1/messages'),
  ).thenAnswer(
    (_) async => Response<Map<String, dynamic>>(
      data: data,
      requestOptions: RequestOptions(path: '/api/conversations/1/messages'),
    ),
  );
}

/// Stub `POST /api/conversations/1/messages/{parentId}/regenerate`，返回具有给定 id 的新空
/// assistant placeholder。
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
  when(
    () => dio.post<Map<String, dynamic>>(
      '/api/conversations/1/messages/$parentId/regenerate',
    ),
  ).thenAnswer(
    (_) async => Response<Map<String, dynamic>>(
      data: data,
      requestOptions: RequestOptions(
        path: '/api/conversations/1/messages/$parentId/regenerate',
      ),
    ),
  );
}

/// Stub `POST /api/conversations/1/messages/{leafId}/switch`，返回新的 conversation path，
/// 其最后一条 assistant 具有给定 content 和 sibling id。
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
  when(
    () => dio.post<Map<String, dynamic>>(
      '/api/conversations/1/messages/$leafId/switch',
    ),
  ).thenAnswer(
    (_) async => Response<Map<String, dynamic>>(
      data: data,
      requestOptions: RequestOptions(
        path: '/api/conversations/1/messages/$leafId/switch',
      ),
    ),
  );
}
