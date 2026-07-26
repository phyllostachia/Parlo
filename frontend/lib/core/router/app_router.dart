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

/// 主内容页面切换的总时长。前半段淡出当前页面，后半段再淡入目标页面。
const _kContentTransitionDuration = Duration(milliseconds: 240);

/// 为主内容 route 创建不重叠的淡出、淡入过渡。
///
/// 旧 route 的 [secondaryAnimation] 在前半段从不透明变为透明；新 route 的 [animation]
/// 在后半段才从透明变为不透明。因此两个页面之间会短暂留出空白，而不会让新旧内容叠在
/// 一起。使用完整 path 作为 key，确保 `/c/1` 与 `/c/2` 是不同页面，能触发过渡并完整
/// 重建会话相关 state。
CustomTransitionPage<void> _contentTransitionPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: ValueKey<String>(state.uri.path),
    transitionDuration: _kContentTransitionDuration,
    reverseTransitionDuration: _kContentTransitionDuration,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final incomingOpacity = CurvedAnimation(
        parent: animation,
        curve: const Interval(0.5, 1, curve: Curves.easeOut),
      );
      final outgoingOpacity = Tween<double>(begin: 1, end: 0).animate(
        CurvedAnimation(
          parent: secondaryAnimation,
          curve: const Interval(0, 0.5, curve: Curves.easeIn),
        ),
      );
      return FadeTransition(
        opacity: outgoingOpacity,
        child: FadeTransition(opacity: incomingOpacity, child: child),
      );
    },
  );
}

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
            pageBuilder: (context, state) => _contentTransitionPage(
              state: state,
              child: EmptyState(onNavigate: (path) => context.go(path)),
            ),
          ),
          GoRoute(
            path: '/c/:id',
            pageBuilder: (context, state) {
              final idParam = state.pathParameters['id'] ?? '';
              final conversationId = int.tryParse(idParam);
              return _contentTransitionPage(
                state: state,
                child: conversationId == null
                    ? const Center(child: Text('Invalid conversation id.'))
                    : ChatScreen(conversationId: conversationId),
              );
            },
          ),
        ],
      ),
    ],
  );
});
