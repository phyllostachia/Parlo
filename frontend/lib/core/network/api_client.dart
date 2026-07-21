/// The dio HTTP client and the base URL provider.
///
/// dio is the only HTTP client in the app. The architecture chose it over
/// `package:http` because `package:http` buffers responses on Flutter Web,
/// which would make Server-Sent Events impossible (architecture §5.1). dio
/// uses fetch + ReadableStream on web and IOClient on native, so the same
/// code streams on every platform.
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import 'base_url_providers.dart';

/// The base URL prepended to every API request.
///
/// Reads the current value from [baseUrlStoreProvider]. The base URL is a
/// required value — the user must enter the backend host (domain + port) in
/// the token dialog or the settings panel before the app can make any
/// request. The router keeps the user on `/` and the token dialog host pops
/// up the dialog until a non-empty value is stored.
///
/// Watching the store (instead of reading once) is what makes a base URL
/// change rebuild dio.
final baseUrlProvider = Provider<String>((ref) {
  return ref.watch(baseUrlStoreProvider).read();
});

/// The configured dio instance for the app.
///
/// Watches [baseUrlProvider] so a new base URL rebuilds dio. The interceptor
/// injects the bearer token on every request and flags 401 responses so the
/// router can redirect to the token dialog.
///
/// We deliberately use `ref.read` (not `ref.watch`) for [authStoreProvider]
/// inside the interceptor. The interceptor reads the *current* token at
/// request time, so dio does not need to be rebuilt when the token changes —
/// rebuilding dio on every token write would also drop pending requests and
/// churn the connection pool.
final dioProvider = Provider<Dio>((ref) {
  final baseUrl = ref.watch(baseUrlProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      // Generous timeouts: the SSE stream has its own heartbeat via tokens,
      // but regular JSON requests can take a while when the model is slow.
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
        // A 401 means the backend rejected the token. Flag it so the router
        // redirects to the empty state and the token dialog pops up. We still
        // forward the error so the calling notifier sees it (and can show its
        // own error UI for non-auth failures).
        if (error.response?.statusCode == 401) {
          ref.read(authStoreProvider).markUnauthorized();
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});
