/// 暴露 [BaseUrlStore] 并将其连接到 dio client 使用的 [baseUrlProvider] 的 Riverpod provider。
///
/// `baseUrlStoreProvider` 是 [ChangeNotifierProvider]，因此 base URL 变化时 dio provider 会
/// 自动 rebuild。`baseUrlProvider`（为 backwards compatibility 保留在 `api_client.dart`）
/// 监听此 store，并返回其当前 value。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import 'base_url_store.dart';

/// 整个应用共享的唯一 [BaseUrlStore]。
///
/// 监听 [sharedPreferencesProvider]，使 store 能够持久化 base URL。Store 只创建一次，并在
/// 应用生命周期内复用。`bootstrap()` 会异步加载已保存的 value。
final baseUrlStoreProvider = ChangeNotifierProvider<BaseUrlStore>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final store = BaseUrlStore(prefs);
  // 加载已保存的 base URL。这里采用 fire-and-forget：store 从空状态开始，几毫秒后收到
  // 已保存的 value 时通知 listener。
  store.bootstrap();
  return store;
});
