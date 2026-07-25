/// 应用 shell：在所有 route 中承载 sidebar 和 main content area 的持久布局。
///
/// Sidebar 位于这里（而不是各个 route 中），因此其 state（expand/collapse、scroll position、
/// 未保存的 inline-edit text）会在 conversation 之间的 navigation 中保留。Main area 显示
/// matched child route 构建的内容。
///
/// Sidebar 在所有 window width 下都可见。Wide screen 使用完整的 280px layout，低于
/// responsive breakpoint 时自动切换为 80px icon rail，以匹配 collapsed-sidebar design。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/settings/token_dialog_host.dart';
import '../../features/sidebar/sidebar_screen.dart';

/// 默认显示完整 sidebar 的宽度阈值。
const double _kWideBreakpoint = 800;

/// Parlo single-page app 的根 layout。
///
/// `child` 是 [ShellRoute] 下 matched route 构建的 widget。`currentConversationId` 是 route
/// 中的 conversation id（用户处于 empty state 时为 `null`），使 sidebar 可以高亮 active
/// conversation。
class AppShell extends ConsumerStatefulWidget {
  /// 创建 shell。
  const AppShell({required this.child, this.currentConversationId, super.key});

  /// matched child route 构建并显示在 main area 中的 widget。
  final Widget child;

  /// 当前 route 的 conversation id；位于 `/` 时为 `null`。
  final int? currentConversationId;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  /// wide-screen sidebar 是否以 compact icon-only form 显示。
  bool _isSidebarCollapsed = false;

  /// narrow-screen 用户是否显式展开了 sidebar。
  bool _isNarrowSidebarExpanded = false;

  void _toggleSidebar(bool isWide) {
    setState(() {
      if (isWide) {
        _isSidebarCollapsed = !_isSidebarCollapsed;
      } else {
        _isNarrowSidebarExpanded = !_isNarrowSidebarExpanded;
      }
    });
  }

  void _navigate(String path) => context.go(path);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= _kWideBreakpoint;
          final sidebar = SidebarScreen(
            currentConversationId: widget.currentConversationId,
            onNavigate: _navigate,
            collapsed: isWide ? _isSidebarCollapsed : !_isNarrowSidebarExpanded,
            onToggle: () => _toggleSidebar(isWide),
          );

          return Stack(
            children: [
              Row(
                children: [
                  sidebar,
                  Expanded(child: widget.child),
                ],
              ),
              const TokenDialogHost(),
            ],
          );
        },
      ),
    );
  }
}
