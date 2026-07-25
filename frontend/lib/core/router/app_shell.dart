/// The app shell — the persistent layout that hosts the sidebar and the main
/// content area across all routes.
///
/// The sidebar lives here (not on individual routes) so its state (expand /
/// collapse, scroll position, unsaved inline-edit text) survives navigation
/// between conversations. The main area shows whatever the matched child
/// route builds.
///
/// The sidebar stays visible at every window width. It uses the full 280px
/// layout on wide screens and automatically switches to the 80px icon rail
/// below the responsive breakpoint, matching the collapsed-sidebar design.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/settings/token_dialog_host.dart';
import '../../features/sidebar/sidebar_screen.dart';

/// The width above which the full sidebar is shown by default.
const double _kWideBreakpoint = 800;

/// The root layout for the Parlo single-page app.
///
/// `child` is the widget built by the matched route under the [ShellRoute].
/// `currentConversationId` is the conversation id from the route (or `null`
/// when the user is on the empty state) so the sidebar can highlight the
/// active conversation.
class AppShell extends ConsumerStatefulWidget {
  /// Creates the shell.
  const AppShell({required this.child, this.currentConversationId, super.key});

  /// The widget built by the matched child route, shown in the main area.
  final Widget child;

  /// The conversation id from the current route, or `null` when on `/`.
  final int? currentConversationId;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  /// Whether the wide-screen sidebar is shown in its compact icon-only form.
  bool _isSidebarCollapsed = false;

  /// Whether a narrow-screen user has explicitly expanded the sidebar.
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
