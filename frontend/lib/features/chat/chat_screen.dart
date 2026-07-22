/// The chat screen for one conversation.
///
/// Composes a top bar (title + model badge; thinking-effort switcher is
/// Phase 4), the scrollable message list, and the bottom input. This is the
/// widget the router returns for `/c/:id`.
///
/// The chat screen is mounted inside the `AppShell`'s main area; it does not
/// render its own `Scaffold` so the sidebar shell owns the page chrome.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/model.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../sidebar/sidebar_providers.dart';
import 'chat_input.dart';
import 'chat_providers.dart';
import 'message_list.dart';

/// The conversation page widget.
class ChatScreen extends ConsumerWidget {
  /// Creates the chat screen.
  const ChatScreen({required this.conversationId, super.key});

  /// The conversation id from the route.
  final int conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ChatTopBar(conversationId: conversationId),
        Divider(
          height: 1,
          thickness: 1,
          color: Theme.of(context).extension<ParloColors>()!.chalk,
        ),
        Expanded(child: MessageList(conversationId: conversationId)),
        ChatInput(conversationId: conversationId),
      ],
    );
  }
}

/// The top bar of the chat screen.
///
/// Follows the design's "Top Bar": the conversation title with a small
/// rename pencil on the left; a soft-stone model badge and an outlined
/// thinking-effort dropdown on the right.
class _ChatTopBar extends ConsumerWidget {
  const _ChatTopBar({required this.conversationId});

  final int conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = Theme.of(context).extension<ParloSpacing>()!;
    final colors = Theme.of(context).extension<ParloColors>()!;

    final pathAsync = ref.watch(currentConversationProvider(conversationId));
    final conversation = pathAsync.valueOrNull?.conversation;
    final title = (conversation == null || conversation.title.isEmpty)
        ? 'New conversation'
        : conversation.title;
    final models = ref.watch(modelListProvider);
    final modelName = _resolveModelName(models, conversation?.modelId ?? '');
    final thinkingLevels = _resolveThinkingLevels(
      models,
      conversation?.modelId ?? '',
    );

    return Container(
      // Design "Top Bar": 12px vertical, 24px horizontal padding. No fixed
      // height — the padding plus content sets the bar height.
      padding: EdgeInsets.symmetric(horizontal: spacing.s24, vertical: 12),
      child: Row(
        children: [
          // Design "Title Group": 15px semibold title plus a 13px pencil
          // icon in pebble, 10px apart. The pencil renames the conversation.
          // `Expanded` makes the title group take the remaining width so the
          // badges on the right are pushed flush to the trailing edge (the
          // design's `space_between` alignment).
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (conversation != null) ...[
                  const SizedBox(width: 10),
                  _RenameButton(
                    initialTitle: conversation.title,
                    onSubmit: (newTitle) =>
                        _rename(ref, conversation.profileId, newTitle),
                  ),
                ],
              ],
            ),
          ),
          if (modelName != null) ...[
            const SizedBox(width: 12),
            // Design "Model Badge": soft-stone fill, 8px radius, sparkles
            // icon plus the model name in graphite.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colors.softStone,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, size: 13, color: colors.graphite),
                  const SizedBox(width: 6),
                  Text(
                    modelName,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.graphite,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (conversation != null && thinkingLevels.isNotEmpty) ...[
            const SizedBox(width: 8),
            _ThinkingEffortBadge(
              levels: thinkingLevels,
              currentLevel: conversation.thinkingEffort,
              onSelected: (level) => _setThinkingEffort(ref, level),
            ),
          ],
        ],
      ),
    );
  }

  /// Finds the display name for the given model id, or `null`.
  String? _resolveModelName(List<ModelRead> models, String modelId) {
    if (modelId.isEmpty) return null;
    for (final model in models) {
      if (model.id == modelId) return model.displayName;
    }
    return null;
  }

  /// Finds the thinking-effort levels the bound model supports. Empty when
  /// the model has no thinking levels (the badge then hides itself).
  List<String> _resolveThinkingLevels(List<ModelRead> models, String modelId) {
    if (modelId.isEmpty) return const <String>[];
    for (final model in models) {
      if (model.id == modelId) return model.thinkingEffort;
    }
    return const <String>[];
  }

  Future<void> _rename(WidgetRef ref, int profileId, String title) async {
    await ref
        .read(sidebarActionsProvider.notifier)
        .renameConversation(
          profileId: profileId,
          conversationId: conversationId,
          title: title,
        );
    ref.invalidate(currentConversationProvider(conversationId));
  }

  Future<void> _setThinkingEffort(WidgetRef ref, String level) async {
    final dio = ref.read(dioProvider);
    await dio.patch<Map<String, dynamic>>(
      '/api/conversations/$conversationId',
      data: <String, dynamic>{'thinking_effort': level},
    );
    ref.invalidate(currentConversationProvider(conversationId));
  }
}

/// The small pencil button next to the conversation title. Opens a rename
/// dialog and submits through [onSubmit].
class _RenameButton extends StatelessWidget {
  const _RenameButton({required this.initialTitle, required this.onSubmit});

  final String initialTitle;
  final ValueChanged<String> onSubmit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ParloColors>()!;
    return IconButton(
      tooltip: 'Rename',
      icon: Icon(Icons.edit_outlined, size: 13, color: colors.pebble),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      visualDensity: VisualDensity.compact,
      onPressed: () async {
        final controller = TextEditingController(text: initialTitle);
        final newTitle = await showDialog<String>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Rename conversation'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Title'),
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
                child: const Text('Rename'),
              ),
            ],
          ),
        );
        final trimmed = newTitle?.trim();
        if (trimmed != null && trimmed.isNotEmpty && trimmed != initialTitle) {
          onSubmit(trimmed);
        }
      },
    );
  }
}

/// The outlined thinking-effort badge in the top bar.
///
/// Matches the design's "Thinking Badge": a mist-bordered capsule with a
/// brain icon, the current level label, and a chevron. Tapping opens a small
/// popup menu with the model's supported levels.
class _ThinkingEffortBadge extends StatelessWidget {
  const _ThinkingEffortBadge({
    required this.levels,
    required this.currentLevel,
    required this.onSelected,
  });

  final List<String> levels;
  final String currentLevel;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ParloColors>()!;
    final label = currentLevel.isEmpty ? levels.first : currentLevel;

    return PopupMenuButton<String>(
      tooltip: 'Thinking effort',
      onSelected: onSelected,
      itemBuilder: (_) => [
        for (final level in levels)
          PopupMenuItem<String>(value: level, child: Text(level)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.mist, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.psychology_outlined, size: 13, color: colors.graphite),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.graphite,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.expand_more, size: 12, color: colors.ashen),
          ],
        ),
      ),
    );
  }
}
