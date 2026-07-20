/// The profile folder tree shown in the sidebar.
///
/// Renders the list of profiles as folders. Each folder can be expanded to
/// show its conversations. Both profile and conversation rows reveal a
/// "..." menu on hover with rename (inline edit) and delete (with
/// confirmation). Clicking a conversation navigates to it.
///
/// The order is `updated_at` descending on both levels — the backend already
/// returns them that way, so we render in list order.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/conversation.dart';
import '../../core/models/profile.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import 'sidebar_providers.dart';

/// The full profile + conversation tree shown in the sidebar.
class ProfileTree extends ConsumerWidget {
  /// Creates the tree.
  const ProfileTree({
    required this.currentConversationId,
    required this.onNavigate,
    super.key,
  });

  /// The conversation id shown in the main area, or `null` on the empty state.
  final int? currentConversationId;

  /// Called with a path like `/c/123` when the user picks a conversation.
  final void Function(String path) onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(profilesProvider);

    return profilesAsync.when(
      loading: () => const _CenteredHint(text: 'Loading…'),
      error: (error, _) => _CenteredHint(
        text: 'Could not load folders:\n$error',
        actionLabel: 'Retry',
        onAction: () => ref.invalidate(profilesProvider),
      ),
      data: (profiles) {
        if (profiles.isEmpty) {
          return const _CenteredHint(
            text: 'No folders yet.\nCreate one with the + button above.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: profiles.length,
          itemBuilder: (context, index) {
            return _ProfileFolder(
              profile: profiles[index],
              currentConversationId: currentConversationId,
              onNavigate: onNavigate,
            );
          },
        );
      },
    );
  }
}

/// One profile folder row, plus its conversations when expanded.
class _ProfileFolder extends ConsumerStatefulWidget {
  const _ProfileFolder({
    required this.profile,
    required this.currentConversationId,
    required this.onNavigate,
  });

  final Profile profile;
  final int? currentConversationId;
  final void Function(String path) onNavigate;

  @override
  ConsumerState<_ProfileFolder> createState() => _ProfileFolderState();
}

class _ProfileFolderState extends ConsumerState<_ProfileFolder> {
  /// Whether the row is currently in inline-rename mode.
  bool _isRenaming = false;
  late final TextEditingController _renameController;

  @override
  void initState() {
    super.initState();
    _renameController = TextEditingController(text: widget.profile.name);
  }

  @override
  void dispose() {
    _renameController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    final current = Set<int>.from(ref.read(expandedProfilesProvider));
    if (current.contains(widget.profile.id)) {
      current.remove(widget.profile.id);
    } else {
      current.add(widget.profile.id);
    }
    ref.read(expandedProfilesProvider.notifier).state = current;
  }

  Future<void> _startRename() async {
    _renameController.text = widget.profile.name;
    setState(() => _isRenaming = true);
  }

  Future<void> _submitRename() async {
    final name = _renameController.text.trim();
    setState(() => _isRenaming = false);
    if (name.isEmpty || name == widget.profile.name) return;
    await ref
        .read(profilesProvider.notifier)
        .renameProfile(widget.profile.id, name);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await _showDeleteConfirmation(
      context: context,
      title: 'Delete folder?',
      message:
          '"${widget.profile.name}" and every conversation inside it will be '
          'deleted. This cannot be undone.',
      confirmText: 'Delete',
    );
    if (confirmed) {
      // Remove from the expanded set so the row does not try to load
      // conversations for a now-deleted profile.
      final current = Set<int>.from(ref.read(expandedProfilesProvider));
      current.remove(widget.profile.id);
      ref.read(expandedProfilesProvider.notifier).state = current;
      await ref
          .read(profilesProvider.notifier)
          .deleteProfile(widget.profile.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final expanded = ref
        .watch(expandedProfilesProvider)
        .contains(widget.profile.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TreeRow(
          leading: IconButton(
            icon: Icon(
              expanded ? Icons.expand_more : Icons.chevron_right,
            ),
            onPressed: _toggleExpanded,
            tooltip: expanded ? 'Collapse' : 'Expand',
          ),
          label: _isRenaming
              ? TextField(
                  controller: _renameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  onSubmitted: (_) => _submitRename(),
                  onTapOutside: (_) => _submitRename(),
                )
              : Text(
                  widget.profile.name,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
          onTap: _isRenaming ? null : _toggleExpanded,
          menuItems: const [
            _MenuItem.rename,
            _MenuItem.delete,
          ],
          onMenuItem: (item) {
            switch (item) {
              case _MenuItem.rename:
                _startRename();
              case _MenuItem.delete:
                _confirmDelete();
            }
          },
        ),
        if (expanded)
          _ConversationsList(
            profileId: widget.profile.id,
            currentConversationId: widget.currentConversationId,
            onNavigate: widget.onNavigate,
          ),
      ],
    );
  }
}

/// The list of conversations shown when a profile folder is expanded.
class _ConversationsList extends ConsumerWidget {
  const _ConversationsList({
    required this.profileId,
    required this.currentConversationId,
    required this.onNavigate,
  });

  final int profileId;
  final int? currentConversationId;
  final void Function(String path) onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final convosAsync = ref.watch(
      conversationsForProfileProvider(profileId),
    );

    return convosAsync.when(
      loading: () => const _IndentedHint(text: 'Loading…'),
      error: (error, _) => _IndentedHint(
        text: 'Could not load: $error',
        actionLabel: 'Retry',
        onAction: () => ref.invalidate(conversationsForProfileProvider(profileId)),
      ),
      data: (conversations) {
        if (conversations.isEmpty) {
          return const _IndentedHint(text: 'No conversations yet');
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final conversation in conversations)
              _ConversationRow(
                conversation: conversation,
                profileId: profileId,
                isActive: conversation.id == currentConversationId,
                onNavigate: onNavigate,
              ),
          ],
        );
      },
    );
  }
}

/// A single conversation row inside a profile folder.
class _ConversationRow extends ConsumerStatefulWidget {
  const _ConversationRow({
    required this.conversation,
    required this.profileId,
    required this.isActive,
    required this.onNavigate,
  });

  final Conversation conversation;
  final int profileId;
  final bool isActive;
  final void Function(String path) onNavigate;

  @override
  ConsumerState<_ConversationRow> createState() => _ConversationRowState();
}

class _ConversationRowState extends ConsumerState<_ConversationRow> {
  bool _isRenaming = false;
  late final TextEditingController _renameController;

  @override
  void initState() {
    super.initState();
    _renameController = TextEditingController(text: widget.conversation.title);
  }

  @override
  void dispose() {
    _renameController.dispose();
    super.dispose();
  }

  void _open() => widget.onNavigate('/c/${widget.conversation.id}');

  Future<void> _startRename() async {
    _renameController.text = widget.conversation.title;
    setState(() => _isRenaming = true);
  }

  Future<void> _submitRename() async {
    final title = _renameController.text.trim();
    setState(() => _isRenaming = false);
    if (title.isEmpty || title == widget.conversation.title) return;
    await ref.read(sidebarActionsProvider.notifier).renameConversation(
          profileId: widget.profileId,
          conversationId: widget.conversation.id,
          title: title,
        );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await _showDeleteConfirmation(
      context: context,
      title: 'Delete conversation?',
      message:
          '"${widget.conversation.title.isEmpty ? 'This conversation' : widget.conversation.title}" '
          'and every message in it will be deleted. This cannot be undone.',
      confirmText: 'Delete',
    );
    if (confirmed) {
      await ref.read(sidebarActionsProvider.notifier).deleteConversation(
            profileId: widget.profileId,
            conversationId: widget.conversation.id,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ParloColors>()!;
    final title = widget.conversation.title.isEmpty
        ? 'New conversation'
        : widget.conversation.title;

    return _TreeRow(
      indent: true,
      highlight: widget.isActive,
      highlightColor: colors.chalk,
      label: _isRenaming
          ? TextField(
              controller: _renameController,
              autofocus: true,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              onSubmitted: (_) => _submitRename(),
              onTapOutside: (_) => _submitRename(),
            )
          : Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      onTap: _isRenaming ? null : _open,
      menuItems: const [_MenuItem.rename, _MenuItem.delete],
      onMenuItem: (item) {
        switch (item) {
          case _MenuItem.rename:
            _startRename();
          case _MenuItem.delete:
            _confirmDelete();
        }
      },
    );
  }
}

/// The actions offered on a profile or conversation row's "..." menu.
enum _MenuItem { rename, delete }

/// A reusable sidebar row that shows a "..." menu on hover.
///
/// Used by both profile folders and conversations. The optional [indent] flag
/// shifts the row right so conversations sit visually under their folder. The
/// optional [highlight] + [highlightColor] give the active conversation a
/// subtle background.
class _TreeRow extends StatefulWidget {
  const _TreeRow({
    this.leading,
    required this.label,
    this.onTap,
    this.menuItems = const [],
    this.onMenuItem,
    this.indent = false,
    this.highlight = false,
    this.highlightColor,
  });

  final Widget? leading;
  final Widget label;
  final VoidCallback? onTap;
  final List<_MenuItem> menuItems;
  final ValueChanged<_MenuItem>? onMenuItem;
  final bool indent;
  final bool highlight;
  final Color? highlightColor;

  @override
  State<_TreeRow> createState() => _TreeRowState();
}

class _TreeRowState extends State<_TreeRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ParloColors>()!;
    final spacing = Theme.of(context).extension<ParloSpacing>()!;
    final background = widget.highlight
        ? (widget.highlightColor ?? colors.chalk)
        : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: background,
          padding: EdgeInsets.symmetric(
            horizontal: spacing.s8,
            vertical: 4,
          ),
          margin: EdgeInsets.only(left: widget.indent ? spacing.s24 : 0),
          child: Row(
            children: [
              if (widget.leading != null) ...[
                widget.leading!,
                const SizedBox(width: 8),
              ],
              Expanded(child: widget.label),
              if (_isHovered && widget.menuItems.isNotEmpty)
                PopupMenuButton<_MenuItem>(
                  icon: const Icon(Icons.more_horiz, size: 18),
                  tooltip: 'More',
                  itemBuilder: (_) => [
                    for (final item in widget.menuItems)
                      PopupMenuItem<_MenuItem>(
                        value: item,
                        child: Text(_labelForItem(item)),
                      ),
                  ],
                  onSelected: widget.onMenuItem,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String _labelForItem(_MenuItem item) {
  switch (item) {
    case _MenuItem.rename:
      return 'Rename';
    case _MenuItem.delete:
      return 'Delete';
  }
}

/// A small indented hint row, used inside an expanded folder.
class _IndentedHint extends StatelessWidget {
  const _IndentedHint({required this.text, this.actionLabel, this.onAction});

  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<ParloSpacing>()!;
    return Padding(
      padding: EdgeInsets.fromLTRB(spacing.s32, spacing.s8, spacing.s16, spacing.s8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

/// A centered hint shown when the whole tree is loading, empty, or errored.
class _CenteredHint extends StatelessWidget {
  const _CenteredHint({required this.text, this.actionLabel, this.onAction});

  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<ParloSpacing>()!;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(spacing.s16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A reusable delete-confirmation dialog. Returns `true` when the user
/// confirms.
Future<bool> _showDeleteConfirmation({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmText,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmText),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
