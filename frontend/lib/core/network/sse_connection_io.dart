/// 原生平台的 SSE transport。
///
/// Dio 在非 Web 平台会直接提供逐 chunk 的 response stream，因此无需绕过它。
library;

import 'dart:typed_data';

import 'package:dio/dio.dart';

/// 打开 assistant message 的 SSE byte stream。
///
/// [bearerToken] 和 [onUnauthorized] 仅由 Web Fetch 实现使用；原生 Dio
/// interceptor 已负责注入 token 与处理 401。
Future<Stream<Uint8List>> openSseByteStream({
  required Dio dio,
  required int messageId,
  required String? bearerToken,
  required void Function() onUnauthorized,
}) async {
  final response = await dio.get<ResponseBody>(
    '/api/chat/stream',
    queryParameters: <String, dynamic>{'message_id': messageId},
    options: Options(responseType: ResponseType.stream),
  );
  final body = response.data;
  if (body == null) {
    throw StateError('SSE response body is empty');
  }
  return body.stream;
}
