/// Tan 应用在 mobile（Android 和 iOS）上的 entry point。
///
/// 使用 `flutter run -t lib/main_mobile.dart` 启动带有 mobile platform capabilities 的应用。
/// 可以将 mobile build system（`android/` 和 `ios/`）配置为指向此 entry point，使设备上
/// 普通的 `flutter run` 自动使用它。
///
/// 此文件对应 [main.dart]（Web entry point），并增加一个 override：将
/// [platformCapabilitiesProvider] 替换为 [MobilePlatformCapabilities]，使应用其余部分
/// 获得 mobile behavior（不支持 drag-and-drop，message action 始终可见），而不需要修改
/// feature code。
///
/// 所有 platform 都由 token dialog 和 settings panel 收集 backend address，因此不需要为
/// 它增加 capability flag。Base URL provider 从持久化 store 读取，所以 dio client 会自动
/// 使用新的 host。
///
/// 注意：此 entry point 可以通过分析并编译，但本次 session 尚未运行 device build
///（Android APK / iOS IPA）。验证 mobile build 需要连接 device 或 emulator，留待专门的
/// mobile verification pass。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/auth/auth_providers.dart';
import 'core/platform/mobile_capabilities.dart';
import 'core/platform/platform_providers.dart';

/// 使用 mobile platform capabilities 启动 Tan 应用。
Future<void> main() async {
  // 在触碰 platform channel 的任何 async work（包括 `SharedPreferences.getInstance()`）
  // 之前都必须调用。
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        // 将真实的 preferences instance 交给应用其余部分。
        sharedPreferencesProvider.overrideWithValue(prefs),
        // 换入 mobile capabilities，使 UI 隐藏 drag zone 并保持 message action 可见。
        platformCapabilitiesProvider.overrideWithValue(
          const MobilePlatformCapabilities(),
        ),
      ],
      child: const TanApp(),
    ),
  );
}
