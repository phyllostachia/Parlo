/// Sidebar 中显示的 profile folder tree。
///
/// 将 profile list 渲染为 folder。每个 folder 都可以展开以显示其中的 conversation。
/// Profile 和 conversation row 都会在 hover 时显示“...”menu，其中有 rename（inline edit）
/// 和 delete（带 confirmation）。点击 conversation 会 navigation 到它。
///
/// 两层都按 `updated_at` descending 排序；backend 已按此顺序返回，因此直接按 list order
/// 渲染。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/conversation.dart';
import '../../core/models/profile.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import 'sidebar_providers.dart';

/// Sidebar 中显示的完整 profile + conversation tree。
class ProfileTree extends ConsumerWidget {
  /// 创建 tree。
  const ProfileTree({
    required this.currentConversationId,
    required this.onNavigate,
    this.collapsed = false,
    this.onExpand,
    super.key,
  });

  /// Main area 显示的 conversation id；empty state 时为 `null`。
  final int? currentConversationId;

  /// User 选择 conversation 时，以 `/c/123` 形式的 path 调用。
  final void Function(String path) onNavigate;

  /// 是否渲染 compact icon-only profile list。
  final bool collapsed;

  /// 选择 compact profile icon 时展开完整 sidebar。
  final VoidCallback? onExpand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(profilesProvider);

    return profilesAsync.when(
      loading: () => collapsed
          ? const _CollapsedHint(icon: Icons.more_horiz)
          : const _CenteredHint(text: 'Loading…'),
      error: (error, _) => collapsed
          ? const _CollapsedHint(icon: Icons.error_outline)
          : _CenteredHint(
              text: 'Could not load folders:\n$error',
              actionLabel: 'Retry',
              onAction: () => ref.invalidate(profilesProvider),
            ),
      data: (profiles) {
        if (profiles.isEmpty) {
          return collapsed
              ? const _CollapsedHint(icon: Icons.folder_off_outlined)
              : const _CenteredHint(
                  text: 'No folders yet.\nCreate one with the + button above.',
                );
        }
        if (collapsed) {
          return ListView.builder(
            padding: EdgeInsets.zero,
            itemCount:
                profiles.length + (currentConversationId == null ? 0 : 1),
            itemBuilder: (context, index) {
              if (currentConversationId != null && index == 0) {
                return _CollapsedTreeRow(
                  icon: Icons.chat_bubble_outline,
                  tooltip: '当前对话',
                  active: true,
                  onTap: () => onNavigate('/c/${currentConversationId!}'),
                );
              }
              final profile =
                  profiles[currentConversationId == null ? index : index - 1];
              return _CollapsedTreeRow(
                icon: Icons.folder_outlined,
                tooltip: profile.name,
                onTap: onExpand,
              );
            },
          );
        }
        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: profiles.length,
          itemBuilder: (context, index) {
            return Padding(
              // Design “Profile List”：profile group 之间间隔 4px。
              padding: EdgeInsets.only(
                bottom: index == profiles.length - 1 ? 0 : 4,
              ),
              child: _ProfileFolder(
                profile: profiles[index],
                currentConversationId: currentConversationId,
                onNavigate: onNavigate,
              ),
            );
          },
        );
      },
    );
  }
}

/// 一条 profile folder row，以及展开时显示的 conversation。
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
  /// Row 当前是否处于 inline-rename mode。
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
      // 从 expanded set 移除，使 row 不会尝试为已删除的 profile 加载 conversation。
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

    final colors = Theme.of(context).extension<ParloColors>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TreeRow(
          // Design “Profile Header”：14px chevron（expanded 时向下，collapsed 时向右）后接
          // 15px folder icon，二者都使用 muted ashen color。
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                expanded ? Icons.expand_more : Icons.chevron_right,
                size: 14,
                color: colors.ashen,
              ),
              const SizedBox(width: 8),
              Icon(Icons.folder_outlined, size: 15, color: colors.ashen),
            ],
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
                  // Design：13px、weight 550、ashen。
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.ashen,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
          onTap: _isRenaming ? null : _toggleExpanded,
          menuItems: const [_MenuItem.rename, _MenuItem.delete],
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

/// Profile folder 展开时显示的 conversation list。
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
    final convosAsync = ref.watch(conversationsForProfileProvider(profileId));

    return convosAsync.when(
      loading: () => const _IndentedHint(text: 'Loading…'),
      error: (error, _) => _IndentedHint(
        text: 'Could not load: $error',
        actionLabel: 'Retry',
        onAction: () =>
            ref.invalidate(conversationsForProfileProvider(profileId)),
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

/// Profile folder 内的一条 conversation row。
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
    await ref
        .read(sidebarActionsProvider.notifier)
        .renameConversation(
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
      await ref
          .read(sidebarActionsProvider.notifier)
          .deleteConversation(
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
      // Design "Conversation Row (active)": paper-white fill, carbon-ink
      // text at weight 550. Inactive rows are transparent with graphite text.
      highlightColor: colors.paperWhite,
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: widget.isActive ? colors.carbonInk : colors.graphite,
                fontWeight: widget.isActive
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
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

/// Profile 或 conversation row 的“...”menu 提供的 action。
enum _MenuItem { rename, delete }

/// 在 hover 时显示“...”menu 的可复用 sidebar row。
///
/// Profile folder 和 conversation 都使用它。可选 [indent] flag 将 row 向右移动，使
/// conversation 在视觉上位于 folder 下方。可选 [highlight] + [highlightColor] 为 active
/// conversation 提供 subtle background。
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
  bool _isMenuOpen = false;

  void _handleMenuSelected(_MenuItem item) {
    setState(() => _isMenuOpen = false);
    widget.onMenuItem?.call(item);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ParloColors>()!;
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
          // Design row：8px corner radius、8x10 padding。Conversation row 位于 folder header
          // 右侧 18px（design 的“Profile Items”left padding）。
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          margin: EdgeInsets.only(left: widget.indent ? 18 : 0),
          child: Row(
            children: [
              if (widget.leading != null) ...[
                widget.leading!,
                const SizedBox(width: 8),
              ],
              Expanded(child: widget.label),
              // Popup route 打开时保持 button 留在 tree 中。否则 pointer 从 row 移入 popup
              // 会触发 `onExit`，dispose button，导致 selected item 在 callback 运行前丢失 callback。
              if ((_isHovered || _isMenuOpen) && widget.menuItems.isNotEmpty)
                PopupMenuButton<_MenuItem>(
                  child: const SizedBox(
                    width: 24,
                    height: 20,
                    child: Center(child: Icon(Icons.more_horiz, size: 18)),
                  ),
                  tooltip: 'More',
                  onOpened: () => setState(() => _isMenuOpen = true),
                  onCanceled: () => setState(() => _isMenuOpen = false),
                  itemBuilder: (_) => [
                    for (final item in widget.menuItems)
                      PopupMenuItem<_MenuItem>(
                        value: item,
                        child: Text(_labelForItem(item)),
                      ),
                  ],
                  onSelected: _handleMenuSelected,
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

/// Expanded folder 内使用的小型 indented hint row。
class _IndentedHint extends StatelessWidget {
  const _IndentedHint({required this.text, this.actionLabel, this.onAction});

  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<ParloSpacing>()!;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        spacing.s32,
        spacing.s8,
        spacing.s16,
        spacing.s8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

/// 整棵 tree loading、empty 或 error 时显示的居中 hint。
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
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// 保持 collapsed rail 不显示 text 的 compact placeholder。
class _CollapsedHint extends StatelessWidget {
  const _CollapsedHint({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ParloColors>()!;
    return Center(child: Icon(icon, size: 16, color: colors.ashen));
  }
}

/// Compact sidebar 中的一条 icon-only profile/conversation row。
class _CollapsedTreeRow extends StatefulWidget {
  const _CollapsedTreeRow({
    required this.icon,
    required this.tooltip,
    this.active = false,
    this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool active;
  final VoidCallback? onTap;

  @override
  State<_CollapsedTreeRow> createState() => _CollapsedTreeRowState();
}

class _CollapsedTreeRowState extends State<_CollapsedTreeRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ParloColors>()!;
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: widget.onTap == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 36,
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: widget.active || _hovered
                  ? (widget.active ? colors.paperWhite : colors.chalk)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(
              widget.icon,
              size: 16,
              color: widget.active ? colors.carbonInk : colors.ashen,
            ),
          ),
        ),
      ),
    );
  }
}

/// 可复用的 delete-confirmation dialog。User 确认时返回 `true`。
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
