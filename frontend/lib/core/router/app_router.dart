/// go_router 配置及其 Riverpod provider。
///
/// Router 使用 [ShellRoute]，使 sidebar（位于 [AppShell] 中）在 `/`（empty state）和
/// `/c/:id`（conversation）route 之间保持挂载。切换 conversation 不会 rebuild sidebar，
/// 因此其 state（expand/collapse、scroll position、inline-edit text）会保留。
///
/// `redirect` 会强制检查 auth 和 backend address：如果 auth store 没有 token、backend 将
/// 当前 token 标记为 401，或 base URL store 为空，则所有 route 都 redirect 到 `/`，并在
/// 那里弹出 token dialog。`refreshListenable` hook 会在任一 store 变化时重新运行 `redirect`，
/// 因此 session 中途收到 401 或 address 被清除时，用户会立即回到 `/`。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_providers.dart';
import '../network/base_url_providers.dart';
import '../../features/chat/chat_screen.dart';
import '../../features/chat/empty_state.dart';
import 'app_shell.dart';

/// 应用使用的 go_router instance。
///
/// 使用 [Provider]（而不是 autoDispose），使 router 在整个 app session 内存活并保留
/// navigation history。使用 `ref.read` 读取 store，使 router 只构建一次；
/// `refreshListenable` hook 负责让 router 响应 store change。
final appRouterProvider = Provider<GoRouter>((ref) {
  final authStore = ref.read(authStoreProvider);
  final baseUrlStore = ref.read(baseUrlStoreProvider);
  return GoRouter(
    // 任一 store 通知时重新计算 `redirect`（token written、token cleared、401 flagged、
    // base URL written、base URL cleared）。这样 session 中途的 401 或被清除的 address
    // 可以在不手动 navigation 的情况下将用户带回 `/`。
    refreshListenable: Listenable.merge([authStore, baseUrlStore]),
    initialLocation: '/',
    redirect: (context, state) {
      final hasToken = authStore.hasToken;
      final isUnauthorized = authStore.isUnauthorized;
      final hasBaseUrl = baseUrlStore.hasValue;
      final path = state.uri.path;

      // token 缺失、已知无效或 backend address 未设置时，强制所有 route 回到 `/`。Token
      // dialog 会在 `/` 上弹出（阶段 5）。
      if (!hasToken || isUnauthorized || !hasBaseUrl) {
        return path == '/' ? null : '/';
      }
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          // 从匹配的 route 取出 conversation id（如果存在），使 sidebar 可以高亮 active
          // conversation。ShellRoute 的 state 携带匹配 child 的 path parameter。
          final idParam = state.pathParameters['id'];
          final conversationId = idParam == null ? null : int.tryParse(idParam);
          return AppShell(currentConversationId: conversationId, child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                EmptyState(onNavigate: (path) => context.go(path)),
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
