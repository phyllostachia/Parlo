/// Web 的 SSE transport。
///
/// `dio_web_adapter` 使用 XMLHttpRequest，并在 `onLoad`（即整个 response
/// 已结束）后才构造 `ResponseBody`。这里直接读取 Fetch `ReadableStream`，使
/// 每一个网络 chunk 都能立即交给 SSE parser。
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:web/web.dart' as web;

/// 打开 assistant message 的 SSE byte stream。
///
/// 从 subscription 取消时会同时取消 reader 并 abort Fetch request，因此 chat
/// notifier 的 `stop()` 与页面 dispose 都能关闭底层 HTTP 连接。
Future<Stream<Uint8List>> openSseByteStream({
  required Dio dio,
  required int messageId,
  required String? bearerToken,
  required void Function() onUnauthorized,
}) async {
  final requestOptions = RequestOptions(
    path: '/api/chat/stream',
    baseUrl: dio.options.baseUrl,
    queryParameters: <String, dynamic>{'message_id': messageId},
  );
  final headers = web.Headers()..set('Accept', 'text/event-stream');
  if (bearerToken case final token? when token.isNotEmpty) {
    headers.set('Authorization', 'Bearer $token');
  }

  final abortController = web.AbortController();
  final response = await web.window
      .fetch(
        requestOptions.uri.toString().toJS,
        web.RequestInit(
          method: 'GET',
          headers: headers,
          cache: 'no-store',
          signal: abortController.signal,
        ),
      )
      .toDart;

  if (!response.ok) {
    if (response.status == 401) {
      onUnauthorized();
    }
    throw StateError(
      'SSE request failed with HTTP ${response.status}: ${response.statusText}',
    );
  }

  final body = response.body;
  if (body == null) {
    throw StateError('SSE response body is empty');
  }
  return _readFetchStream(
    web.ReadableStreamDefaultReader(body),
    abortController,
  );
}

/// 将 Fetch reader 桥接为 Dart byte stream。
Stream<Uint8List> _readFetchStream(
  web.ReadableStreamDefaultReader reader,
  web.AbortController abortController,
) {
  late final StreamController<Uint8List> controller;
  var cancelled = false;

  Future<void> cancel() async {
    if (cancelled) return;
    cancelled = true;
    abortController.abort();
    try {
      await reader.cancel().toDart;
    } catch (_) {
      // `abort()` 会使正在进行的 reader request reject；这表示取消已生效。
    }
  }

  Future<void> readChunks() async {
    try {
      while (!cancelled) {
        final result = await reader.read().toDart;
        if (result.done) break;

        final value = result.value;
        if (value == null || !value.isA<JSUint8Array>()) {
          throw StateError('Fetch returned a non-byte SSE chunk');
        }
        final bytes = value as JSUint8Array;
        // 每个 Fetch chunk 都可能由 JavaScript runtime 管理。复制后再 emit，避免下次
        // `read()` 时底层 buffer 的生命周期影响尚未解析完的 SSE data。
        controller.add(Uint8List.fromList(bytes.toDart));
      }
      if (!cancelled) {
        await controller.close();
      }
    } catch (error, stackTrace) {
      if (!cancelled) {
        controller.addError(error, stackTrace);
        await controller.close();
      }
    }
  }

  controller = StreamController<Uint8List>(
    onListen: () => unawaited(readChunks()),
    onCancel: cancel,
  );
  return controller.stream;
}
