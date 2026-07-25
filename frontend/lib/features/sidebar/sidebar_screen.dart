/// The sidebar — the persistent left column of the app.
///
/// Layout follows `product.md` §5:
/// - Top: buttons to create a new profile and a new conversation.
/// - Middle: the profile folder tree (Phase 2's `ProfileTree`).
/// - Bottom: a gear button that opens the settings panel.
///
/// The sidebar is constant across routes; only its highlighted conversation
/// changes when `currentConversationId` changes.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/colors.dart';
import 'profile_tree.dart';
import 'settings_panel.dart';
import 'sidebar_providers.dart';

/// The full sidebar widget.
class SidebarScreen extends ConsumerWidget {
  /// Creates the sidebar.
  const SidebarScreen({
    required this.currentConversationId,
    required this.onNavigate,
    this.collapsed = false,
    this.onToggle,
    super.key,
  });

  /// The conversation id shown in the main area, or `null` on the empty state.
  /// Used to highlight the active conversation in the tree.
  final int? currentConversationId;

  /// Called when the user picks a conversation. The argument is a path like
  /// `/c/123`. Kept as a callback (rather than the sidebar reaching into the
  /// router directly) so the shell owns navigation.
  final void Function(String path) onNavigate;

  /// Whether to render the 80px icon-only sidebar used on narrow screens and
  /// after manually collapsing the wide sidebar.
  final bool collapsed;

  /// Toggles between the full sidebar and the compact icon-only sidebar.
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<ParloColors>()!;
    final contentWidth = collapsed ? 56.0 : 248.0;

    // Design "Sidebar": 280px wide when expanded and 80px when collapsed,
    // with a soft-stone fill, 16px padding, 16px gap between the three
    // sections (top / tree / settings row), and a hairline chalk border.
    return AnimatedContainer(
      width: collapsed ? 80 : 280,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOutCubic,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: colors.softStone,
        border: Border(right: BorderSide(color: colors.chalk, width: 1)),
      ),
      padding: collapsed
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 16)
          : const EdgeInsets.all(16),
      child: OverflowBox(
        alignment: Alignment.topLeft,
        minWidth: contentWidth,
        maxWidth: contentWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SidebarHeader(
              collapsed: collapsed,
              onNewProfile: () => _promptForProfileName(context, ref),
              onNewConversation: () => onNavigate('/'),
              onToggle: onToggle,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ProfileTree(
                currentConversationId: currentConversationId,
                onNavigate: onNavigate,
                collapsed: collapsed,
                onExpand: collapsed ? onToggle : null,
              ),
            ),
            const SizedBox(height: 16),
            _SidebarFooter(
              collapsed: collapsed,
              onSettings: () => _openSettingsPanel(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _promptForProfileName(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final name = await _showNameDialog(
      context: context,
      title: 'New folder',
      labelText: 'Folder name',
      initialText: 'New folder',
      confirmText: 'Create',
    );
    if (name == null || name.trim().isEmpty) return;
    // Fire-and-forget; the AsyncNotifier state will reflect the refetch.
    // Errors surface via the AsyncValue in the tree.
    await ref.read(profilesProvider.notifier).createProfile(name.trim());
  }

  Future<void> _openSettingsPanel(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => const SettingsPanelDialog(),
    );
  }
}

/// The sidebar's top section: the brand row (serif wordmark + collapse icon)
/// and two full-width action buttons ("新建对话" and "新建分组").
class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({
    required this.collapsed,
    required this.onNewProfile,
    required this.onNewConversation,
    required this.onToggle,
  });

  final bool collapsed;
  final VoidCallback onNewProfile;
  final VoidCallback onNewConversation;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ParloColors>()!;
    if (collapsed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SidebarIconButton(
            icon: const _SidebarToggleIcon(collapsed: true),
            tooltip: '展开侧栏',
            onTap: onToggle,
          ),
          const SizedBox(height: 8),
          _SidebarActionButton(
            icon: Icons.edit_outlined,
            label: '新建对话',
            onTap: onNewConversation,
            collapsed: true,
          ),
          const SizedBox(height: 4),
          _SidebarActionButton(
            icon: Icons.create_new_folder_outlined,
            label: '新建分组',
            onTap: onNewProfile,
            collapsed: true,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Design "Brand Row": 20px serif wordmark on the left, an 18px
        // panel-left-close icon on the right, 4px padding.
        Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Parlo',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: 20,
                    color: colors.carbonInk,
                  ),
                ),
              ),
              if (onToggle != null)
                IconButton(
                  icon: const _SidebarToggleIcon(collapsed: false),
                  color: colors.ashen,
                  tooltip: '收起侧栏',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: onToggle,
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Design "New Actions Row": two full-width ghost buttons, 4px apart.
        _SidebarActionButton(
          icon: Icons.edit_outlined,
          label: '新建对话',
          onTap: onNewConversation,
        ),
        const SizedBox(height: 4),
        _SidebarActionButton(
          icon: Icons.create_new_folder_outlined,
          label: '新建分组',
          onTap: onNewProfile,
        ),
      ],
    );
  }
}

/// A full-width ghost button used for the sidebar's action rows
/// ("新建对话" / "新建分组") and the settings row at the bottom.
///
/// Matches the design: 16px icon + 14px medium label, 10px gap, padding
/// 8x10, 8px corner radius, transparent fill that lightens on hover.
class _SidebarActionButton extends StatefulWidget {
  const _SidebarActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.collapsed = false,
    this.topBorder = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Whether to show only the icon in the compact sidebar.
  final bool collapsed;

  /// Whether to draw the hairline top border (used by the settings row,
  /// which sits at the bottom of the sidebar separated by a divider).
  final bool topBorder;

  @override
  State<_SidebarActionButton> createState() => _SidebarActionButtonState();
}

class _SidebarActionButtonState extends State<_SidebarActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ParloColors>()!;
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _hovered ? colors.chalk : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: widget.topBorder
            ? Border(top: BorderSide(color: colors.chalk, width: 1))
            : null,
      ),
      child: Row(
        mainAxisAlignment: widget.collapsed
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: [
          Icon(widget.icon, size: 16, color: colors.graphite),
          if (!widget.collapsed) ...[
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.graphite,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: widget.label,
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: child,
        ),
      ),
    );
  }
}

/// The sidebar's bottom row: a full-width "设置" row with a hairline divider
/// above it (the design's "Settings Row").
class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter({required this.collapsed, required this.onSettings});

  final bool collapsed;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return _SidebarActionButton(
      icon: Icons.settings_outlined,
      label: '设置',
      onTap: onSettings,
      collapsed: collapsed,
      topBorder: true,
    );
  }
}

/// An icon-only button used by the compact sidebar header.
class _SidebarIconButton extends StatelessWidget {
  const _SidebarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final Widget icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: icon,
      color: Theme.of(context).extension<ParloColors>()!.ashen,
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 56, minHeight: 36),
      onPressed: onTap,
    );
  }
}

/// A small Lucide-style panel-left open/close icon.
class _SidebarToggleIcon extends StatelessWidget {
  const _SidebarToggleIcon({required this.collapsed});

  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size.square(18),
      painter: _SidebarToggleIconPainter(
        color: IconTheme.of(context).color ?? Colors.black,
        collapsed: collapsed,
      ),
    );
  }
}

class _SidebarToggleIconPainter extends CustomPainter {
  const _SidebarToggleIconPainter({
    required this.color,
    required this.collapsed,
  });

  final Color color;
  final bool collapsed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final panel = RRect.fromRectAndRadius(
      Rect.fromLTWH(1.5, 1.5, size.width - 3, size.height - 3),
      const Radius.circular(2),
    );
    canvas.drawRRect(panel, paint);

    canvas.drawLine(Offset(7, 2.5), Offset(7, size.height - 2.5), paint);

    final arrow = Path()
      ..moveTo(collapsed ? 10 : 13, 6)
      ..lineTo(collapsed ? 13 : 10, 9)
      ..lineTo(collapsed ? 10 : 13, 12);
    canvas.drawPath(arrow, paint);
  }

  @override
  bool shouldRepaint(_SidebarToggleIconPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.collapsed != collapsed;
}

/// A small reusable dialog that asks the user for a single text value.
///
/// Returns the entered text, or `null` if the user dismissed the dialog. Kept
/// here because the sidebar uses it for "new folder"; rename uses an inline
/// editor in the tree instead.
Future<String?> _showNameDialog({
  required BuildContext context,
  required String title,
  required String labelText,
  required String initialText,
  required String confirmText,
}) async {
  final controller = TextEditingController(text: initialText);
  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: labelText),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(null),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: Text(confirmText),
          ),
        ],
      );
    },
  );
}
