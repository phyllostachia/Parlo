/// Parlo Flutter 前端的 entry point。
///
/// 应用包裹在 [ProviderScope] 中，使每个 Riverpod provider 都有可用的 container。字体
/// 在 `pubspec.yaml` 中声明，并由 Flutter 自动注册，因此这里不需要手动注册字体。
///
/// 在 `runApp` 前主动加载 [SharedPreferences]，并用该 instance override
/// `sharedPreferencesProvider`。之后 auth store 可以同步读取它，因此首次绘制时无需
/// async wait 就能恢复 token。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/auth/auth_providers.dart';

/// 启动 Parlo 应用。
///
/// 保持 `main` 简短可以让应用更容易测试：test 可以直接构造 [ParloApp] widget 并 pump，
/// 而不需要运行 `main`。
Future<void> main() async {
  // 在触碰 platform channel 的任何 async work（包括 `SharedPreferences.getInstance()`）
  // 之前都必须调用。
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        // 将真实的 preferences instance 交给应用其余部分。`auth_providers.dart` 中的
        // default factory 会抛出异常，因此忘记这个 override 会明确失败。
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const ParloApp(),
    ),
  );
}
