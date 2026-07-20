/// The app shell — the persistent layout that hosts the sidebar and the main
/// content area across all routes.
///
/// The sidebar lives here (not on individual routes) so its state (expand /
/// collapse, scroll position, unsaved inline-edit text) survives navigation
/// between conversations. The main area shows whatever the matched child
/// route builds.
///
/// Phase 6 adds responsive behavior (product.md §5.4):
/// - On wide screens the sidebar is always visible next to the main area.
/// - On narrow screens the sidebar collapses; a hamburger button at the top
///   of the main area opens it as an overlay drawer with a scrim, so the
///   main area is not squeezed. Tapping the scrim or a conversation closes
///   the drawer.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../../features/settings/token_dialog_host.dart';
import '../../features/sidebar/sidebar_screen.dart';

/// The width above which the sidebar is always visible. Below this width the
/// sidebar collapses into an overlay drawer.
const double _kWideBreakpoint = 800;

/// The root layout for the Parlo single-page app.
///
/// `child` is the widget built by the matched route under the [ShellRoute].
/// `currentConversationId` is the conversation id from the route (or `null`
/// when the user is on the empty state) so the sidebar can highlight the
/// active conversation.
class AppShell extends ConsumerStatefulWidget {
  /// Creates the shell.
  const AppShell({
    required this.child,
    this.currentConversationId,
    super.key,
  });

  /// The widget built by the matched child route, shown in the main area.
  final Widget child;

  /// The conversation id from the current route, or `null` when on `/`.
  final int? currentConversationId;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  /// Whether the narrow-screen overlay drawer is currently open.
  bool _isDrawerOpen = false;

  void _closeDrawer() => setState(() => _isDrawerOpen = false);

  void _openDrawer() => setState(() => _isDrawerOpen = true);

  void _navigate(String path) {
    _closeDrawer();
    context.go(path);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ParloColors>()!;
    final spacing = Theme.of(context).extension<ParloSpacing>()!;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= _kWideBreakpoint;
          final sidebar = SidebarScreen(
            currentConversationId: widget.currentConversationId,
            onNavigate: _navigate,
          );
          final divider = Container(
            width: 1,
            color: colors.mist,
            margin: EdgeInsets.symmetric(vertical: spacing.s16),
          );

          if (isWide) {
            return Stack(
              children: [
                Row(
                  children: [
                    sidebar,
                    divider,
                    Expanded(child: widget.child),
                  ],
                ),
                const TokenDialogHost(),
              ],
            );
          }

          // Narrow layout: the main area takes the full width; the sidebar
          // is an overlay drawer opened by the hamburger button.
          return Stack(
            children: [
              Column(
                children: [
                  _NarrowTopBar(
                    onMenu: _openDrawer,
                  ),
                  Expanded(child: widget.child),
                ],
              ),
              if (_isDrawerOpen) _DrawerScrim(onTap: _closeDrawer),
              if (_isDrawerOpen)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Material(
                    color: colors.boneParchment,
                    elevation: 4,
                    child: sidebar,
                  ),
                ),
              const TokenDialogHost(),
            ],
          );
        },
      ),
    );
  }
}

/// The slim top bar shown on narrow screens, carrying the hamburger button.
class _NarrowTopBar extends StatelessWidget {
  const _NarrowTopBar({required this.onMenu});

  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ParloColors>()!;
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: colors.boneParchment,
        border: Border(
          bottom: BorderSide(color: colors.mist, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Menu',
            icon: const Icon(Icons.menu),
            onPressed: onMenu,
          ),
          const SizedBox(width: 8),
          Text(
            'Parlo',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

/// The semi-transparent scrim behind the narrow-screen drawer. Tapping it
/// closes the drawer.
class _DrawerScrim extends StatelessWidget {
  const _DrawerScrim({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.black.withValues(alpha: 0.32),
      ),
    );
  }
}
