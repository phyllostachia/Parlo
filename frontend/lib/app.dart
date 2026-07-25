/// Parlo 应用的根 widget。
///
/// 这是一个挂载 `appRouterProvider` 提供的 go_router 的 [MaterialApp.router]。Router 会
/// 构建 [AppShell]（sidebar + main area），并随着 URL 变化在 empty state 和 conversation
/// screen 之间切换 main area。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// Parlo 应用的顶层 widget。
class ParloApp extends ConsumerWidget {
  /// 创建根 widget。
  const ParloApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Parlo',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: router,
    );
  }
}
