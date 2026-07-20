/// The go_router configuration and its Riverpod provider.
///
/// The router uses a [ShellRoute] so the sidebar (in [AppShell]) stays mounted
/// across the `/` (empty state) and `/c/:id` (conversation) routes. Switching
/// conversations does not rebuild the sidebar, so its state (expand/collapse,
/// scroll position, inline-edit text) is preserved.
///
/// Auth is enforced in `redirect`: if the auth store has no token, or the
/// backend has flagged the current token as a 401, every route is redirected
/// to `/`, where the token dialog pops up. The `refreshListenable` hook
/// re-runs `redirect` whenever the auth store changes, so a 401 mid-session
/// bounces the user back to `/` immediately.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_providers.dart';
import '../../features/chat/chat_screen.dart';
import '../../features/chat/empty_state.dart';
import 'app_shell.dart';

/// The go_router instance for the app.
///
/// We use [Provider] (not autoDispose) so the router lives for the whole app
/// session and keeps its navigation history. We read the auth store with
/// `ref.read` so the router is built exactly once; the `refreshListenable`
/// hook is what makes the router react to auth changes.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authStore = ref.read(authStoreProvider);
  return GoRouter(
    // Re-evaluate `redirect` whenever the auth store notifies (token written,
    // token cleared, 401 flagged). This is what makes a mid-session 401 bounce
    // the user back to `/` without a manual navigation.
    refreshListenable: authStore,
    initialLocation: '/',
    redirect: (context, state) {
      final hasToken = authStore.hasToken;
      final isUnauthorized = authStore.isUnauthorized;
      final path = state.uri.path;

      // While the token is missing or known-invalid, force every route back to
      // `/`. The token dialog pops up over `/` (Phase 5).
      if (!hasToken || isUnauthorized) {
        return path == '/' ? null : '/';
      }
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          // Pull the conversation id (if any) off the matched route so the
          // sidebar can highlight the active conversation. The ShellRoute's
          // state carries the matched child's path parameters.
          final idParam = state.pathParameters['id'];
          final conversationId =
              idParam == null ? null : int.tryParse(idParam);
          return AppShell(
            currentConversationId: conversationId,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => EmptyState(
              onNavigate: (path) => context.go(path),
            ),
          ),
          GoRoute(
            path: '/c/:id',
            builder: (context, state) {
              final idParam = state.pathParameters['id'] ?? '';
              final conversationId = int.tryParse(idParam);
              if (conversationId == null) {
                return const Center(child: Text('Invalid conversation id.'));
              }
              return ChatScreen(conversationId: conversationId);
            },
          ),
        ],
      ),
    ],
  );
});

