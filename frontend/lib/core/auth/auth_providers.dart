/// 向应用其余部分提供 [AuthStore] 和持久化 `SharedPreferences` 的 Riverpod provider。
///
/// `sharedPreferencesProvider` 会在 `main.dart` 中被真实 instance override，使应用其余
/// 部分可以同步读取。`authStoreProvider` 是 [ChangeNotifierProvider]，因此 token 变化时
/// go_router 和 token dialog 会自动 rebuild。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_store.dart';

/// 应用的 `shared_preferences` instance。
///
/// 在 `main.dart` 中使用 `SharedPreferences.getInstance()` 得到的 instance 进行 override，
/// 使应用其余部分可以同步读取。Bearer token 和 base URL 都保存在这里。
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  // default factory 会抛出异常，因此缺少 override 时可以尽早发现，而不是在应用深处
  // 静默地产生 null value。
  throw StateError(
    'sharedPreferencesProvider must be overridden in main() with the '
    'instance from SharedPreferences.getInstance()',
  );
});

/// 整个应用共享的唯一 [AuthStore]。
///
/// 监听 [sharedPreferencesProvider]，使 store 能够持久化 token。Store 只创建一次，并在
/// 应用生命周期内复用。
final authStoreProvider = ChangeNotifierProvider<AuthStore>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final store = AuthStore(prefs);
  // 加载已保存的 token。这里采用 fire-and-forget：store 从空状态开始，几毫秒后收到已
  // 保存的 token 时通知 listener。
  store.bootstrap();
  return store;
});
