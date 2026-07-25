/// dio HTTP client 和 base URL provider。
///
/// dio 是应用唯一的 HTTP client。架构选择它而不是 `package:http`，因为 Flutter Web 上的
/// `package:http` 会 buffer response，使 Server-Sent Events 无法工作（架构 §5.1）。dio
/// 在 Web 上使用 fetch + ReadableStream，在 native 上使用 IOClient，因此同一份 code 可以
/// 在所有 platform 上 streaming。
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import 'base_url_providers.dart';

/// 添加到每个 API request 前的 base URL。
///
/// 从 [baseUrlStoreProvider] 读取当前 value。Base URL 是 required value：用户必须在 token
/// dialog 或 settings panel 中输入 backend host（domain + port），应用才能发出 request。
/// 在存储非空 value 之前，router 会将用户留在 `/`，token dialog host 会弹出 dialog。
///
/// 监听 store（而不是只读取一次）使 base URL 变化时能够 rebuild dio。
final baseUrlProvider = Provider<String>((ref) {
  return ref.watch(baseUrlStoreProvider).read();
});

/// 应用配置好的 dio instance。
///
/// 监听 [baseUrlProvider]，使新 base URL 能够 rebuild dio。Interceptor 会在每个 request
/// 注入 bearer token，并标记 401 response，使 router 可以 redirect 到 token dialog。
///
/// 在 interceptor 内部，我们有意对 [authStoreProvider] 使用 `ref.read`（而不是 `ref.watch`）。
/// Interceptor 会在 request time 读取 *current* token，因此 token 变化时不需要 rebuild dio；
/// 每次写入 token 都 rebuild dio 还会丢弃 pending request，并使 connection pool 频繁变化。
final dioProvider = Provider<Dio>((ref) {
  final baseUrl = ref.watch(baseUrlProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      // 使用较宽松的 timeout：SSE stream 通过 token 自带 heartbeat，但 model 较慢时，
      // 普通 JSON request 可能需要较长时间。
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 10),
      sendTimeout: const Duration(seconds: 30),
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final authStore = ref.read(authStoreProvider);
        final token = authStore.read();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        // 401 表示 backend 拒绝了 token。标记它，使 router redirect 到 empty state 并弹出
        // token dialog。仍然转发 error，使调用方 notifier 能看到它（并为非 auth failure
        // 显示自己的 error UI）。
        if (error.response?.statusCode == 401) {
          ref.read(authStoreProvider).markUnauthorized();
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});
