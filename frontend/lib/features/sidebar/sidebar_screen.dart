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
    super.key,
  });

  /// The conversation id shown in the main area, or `null` on the empty state.
  /// Used to highlight the active conversation in the tree.
  final int? currentConversationId;

  /// Called when the user picks a conversation. The argument is a path like
  /// `/c/123`. Kept as a callback (rather than the sidebar reaching into the
  /// router directly) so the shell owns navigation.
  final void Function(String path) onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<ParloColors>()!;

    // Design "Sidebar": 280px wide, soft-stone fill, 16px padding, 16px gap
    // between the three sections (top / tree / settings row), with a hairline
    // chalk border on the right edge.
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: colors.softStone,
        border: Border(right: BorderSide(color: colors.chalk, width: 1)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SidebarHeader(
            onNewProfile: () => _promptForProfileName(context, ref),
            onNewConversation: () => onNavigate('/'),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ProfileTree(
              currentConversationId: currentConversationId,
              onNavigate: onNavigate,
            ),
          ),
          const SizedBox(height: 16),
          _SidebarFooter(onSettings: () => _openSettingsPanel(context)),
        ],
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
    required this.onNewProfile,
    required this.onNewConversation,
  });

  final VoidCallback onNewProfile;
  final VoidCallback onNewConversation;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ParloColors>()!;
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
              Icon(
                Icons.keyboard_double_arrow_left,
                size: 18,
                color: colors.ashen,
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
    this.topBorder = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

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
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered ? colors.chalk : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: widget.topBorder
                ? Border(top: BorderSide(color: colors.chalk, width: 1))
                : null,
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 16, color: colors.graphite),
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
          ),
        ),
      ),
    );
  }
}

/// The sidebar's bottom row: a full-width "设置" row with a hairline divider
/// above it (the design's "Settings Row").
class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter({required this.onSettings});

  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return _SidebarActionButton(
      icon: Icons.settings_outlined,
      label: '设置',
      onTap: onSettings,
      topBorder: true,
    );
  }
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
