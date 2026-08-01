/// 多轮对话测试，验证发送第二条消息时历史记录正确。
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tan/core/auth/auth_providers.dart';
import 'package:tan/core/models/message.dart';
import 'package:tan/core/network/api_client.dart';
import 'package:tan/features/chat/chat_providers.dart';

class _MockDio extends Mock implements Dio {}

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
    final sub = container.listen(
      currentConversationProvider(_conversationId),
      (_, _) {},
    );
    addTearDown(sub.close);
  });

  test('second message sends with correct parent and history', () async {
    // 第一轮对话
    _stubPathLoad(
      dio,
      messages: [
        _createMessageJson(id: 1, role: 'user', content: 'Question1'),
        _createMessageJson(
          id: 2,
          role: 'assistant',
          content: 'Answer1',
          parentId: 1,
        ),
      ],
    );
    _stubSendMessage(dio, userId: 3, assistantId: 4, parentId: 2);
    _stubStream(dio, <String>[
      'event: started\ndata: {"message_id":4}\n\n',
      'event: text_delta\ndata: {"content":"Answer2"}\n\n',
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

    // 验证初始状态有两条消息
    var path = container
        .read(currentConversationProvider(_conversationId))
        .requireValue;
    expect(path.path, hasLength(2));

    // 发送第二条消息
    await notifier.send(text: 'Question2');
    await doneState.future.timeout(const Duration(seconds: 5));

    // 验证最终状态有四条消息
    path = container
        .read(currentConversationProvider(_conversationId))
        .requireValue;
    expect(path.path, hasLength(4));
    expect(path.path[0].message.content, 'Question1');
    expect(path.path[1].message.content, 'Answer1');
    expect(path.path[2].message.content, 'Question2');
    expect(path.path[3].message.content, 'Answer2');
  });
}

void _registerFallbackValues() {
  registerFallbackValue(Options());
  registerFallbackValue(<String, dynamic>{});
}

Uint8List _encode(String source) => Uint8List.fromList(utf8.encode(source));

Map<String, dynamic> _conversationJson() {
  return <String, dynamic>{
    'id': 1,
    'profile_id': 1,
    'title': 'Test',
    'model_id': 'm1',
    'thinking_enabled': false,
    'current_leaf_id': null,
    'created_at': '2026-07-01T00:00:00Z',
    'updated_at': '2026-07-01T00:00:00Z',
  };
}

Map<String, dynamic> _createMessageJson({
  required int id,
  required String role,
  required String content,
  int? parentId,
}) {
  return <String, dynamic>{
    'id': id,
    'conversation_id': 1,
    'parent_id': parentId,
    'role': role,
    'content': content,
    'reasoning': null,
    'image_url': null,
    'is_complete': true,
    'created_at': '2026-07-01T00:00:00Z',
  };
}

void _stubPathLoad(
  _MockDio dio, {
  required List<Map<String, dynamic>> messages,
}) {
  final pathItems = messages.map((msg) {
    return <String, dynamic>{
      'message': msg,
      'siblings': <String, dynamic>{
        'siblings': <int>[msg['id'] as int],
        'active_id': msg['id'] as int,
      },
    };
  }).toList();

  final data = <String, dynamic>{
    'conversation': _conversationJson(),
    'path': pathItems,
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

void _stubSendMessage(
  _MockDio dio, {
  required int userId,
  required int assistantId,
  int? parentId,
}) {
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
        'id': userId,
        'conversation_id': 1,
        'parent_id': parentId,
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
        'parent_id': userId,
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
