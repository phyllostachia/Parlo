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
import '../../core/theme/spacing.dart';
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

    return Container(
      width: 280,
      color: colors.boneParchment,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SidebarHeader(
            onNewProfile: () => _promptForProfileName(context, ref),
            onNewConversation: () => onNavigate('/'),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: colors.mist,
          ),
          Expanded(
            child: ProfileTree(
              currentConversationId: currentConversationId,
              onNavigate: onNavigate,
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: colors.mist,
          ),
          _SidebarFooter(
            onSettings: () => _openSettingsPanel(context),
          ),
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
    await ref
        .read(profilesProvider.notifier)
        .createProfile(name.trim());
  }

  Future<void> _openSettingsPanel(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => const SettingsPanelDialog(),
    );
  }
}

/// The sidebar's top row: the Parlo wordmark and two create buttons.
class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({
    required this.onNewProfile,
    required this.onNewConversation,
  });

  final VoidCallback onNewProfile;
  final VoidCallback onNewConversation;

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<ParloSpacing>()!;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        spacing.s16,
        spacing.s16,
        spacing.s8,
        spacing.s8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Parlo',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          IconButton(
            tooltip: 'New folder',
            icon: const Icon(Icons.create_new_folder_outlined),
            onPressed: onNewProfile,
          ),
          IconButton(
            tooltip: 'New chat',
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: onNewConversation,
          ),
        ],
      ),
    );
  }
}

/// The sidebar's bottom row: the settings gear.
class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter({required this.onSettings});

  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<ParloSpacing>()!;
    return Padding(
      padding: EdgeInsets.all(spacing.s8),
      child: IconButton(
        tooltip: 'Settings',
        icon: const Icon(Icons.settings_outlined),
        onPressed: onSettings,
      ),
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
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text),
            child: Text(confirmText),
          ),
        ],
      );
    },
  );
}
