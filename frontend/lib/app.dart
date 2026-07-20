/// The root widget for the Parlo app.
///
/// This is a [MaterialApp.router] that mounts the go_router from
/// `appRouterProvider`. The router builds an [AppShell] (sidebar + main
/// area) and swaps the main area between the empty state and the conversation
/// screen as the URL changes.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// The top-level widget for the Parlo application.
class ParloApp extends ConsumerWidget {
  /// Creates the root widget.
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
