/// 一个 conversation 的 chat screen。
///
/// 由 top bar（title + model badge；thinking-effort switcher 在阶段 4 加入）、可滚动 message
/// list 和底部 input 组成。这是 router 为 `/c/:id` 返回的 widget。
///
/// Chat screen 挂载在 `AppShell` 的 main area 内；它不渲染自己的 `Scaffold`，因此 sidebar
/// shell 负责 page chrome。
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

/// Conversation page widget。
class ChatScreen extends ConsumerWidget {
  /// 创建 chat screen。
  const ChatScreen({required this.conversationId, super.key});

  /// Route 中的 conversation id。
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

/// Chat screen 的 top bar。
///
/// 遵循 design 的“Top Bar”：左侧是带小型 rename pencil 的 conversation title；右侧是
/// soft-stone model badge 和 outlined thinking-effort dropdown。
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
      // Design “Top Bar”：垂直 12px、水平 24px padding。没有 fixed height；padding 加
      // content 决定 bar height。
      padding: EdgeInsets.symmetric(horizontal: spacing.s24, vertical: 12),
      child: Row(
        children: [
          // Design “Title Group”：15px semibold title 加上 pebble 色 13px pencil icon，二者
          // 间隔 10px。Pencil 用于重命名 conversation。`Expanded` 让 title group 占据剩余
          // width，使右侧 badge 推到 trailing edge（design 的 `space_between` alignment）。
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
            // Design “Model Badge”：soft-stone fill、8px radius、sparkles icon，以及
            // graphite 色 model name。
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

  /// 查找给定 model id 的 display name；找不到时为 `null`。
  String? _resolveModelName(List<ModelRead> models, String modelId) {
    if (modelId.isEmpty) return null;
    for (final model in models) {
      if (model.id == modelId) return model.displayName;
    }
    return null;
  }

  /// 查找绑定 model 支持的 thinking-effort level。Model 没有 thinking level 时为空（badge
  /// 随后隐藏）。
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

/// Conversation title 旁的小型 pencil button。打开 rename dialog，并通过 [onSubmit] 提交。
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

/// Top bar 中 outlined thinking-effort badge。
///
/// 匹配 design 的“Thinking Badge”：带 mist border 的 capsule、brain icon、当前 level label
/// 和 chevron。点击后打开包含 model 支持 level 的小型 popup menu。
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
