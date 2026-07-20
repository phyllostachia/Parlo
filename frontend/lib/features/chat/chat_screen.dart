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
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
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
          color: Theme.of(context).extension<ParloColors>()!.mist,
        ),
        Expanded(child: MessageList(conversationId: conversationId)),
        ChatInput(conversationId: conversationId),
      ],
    );
  }
}

/// The top bar of the chat screen: conversation title and model badge.
///
/// Phase 4 will add the thinking-effort switcher. For Phase 3 this is a
/// read-only display so the user can see which model the conversation is
/// bound to.
class _ChatTopBar extends ConsumerWidget {
  const _ChatTopBar({required this.conversationId});

  final int conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = Theme.of(context).extension<ParloSpacing>()!;
    final colors = Theme.of(context).extension<ParloColors>()!;

    final pathAsync = ref.watch(
      currentConversationProvider(conversationId),
    );
    final conversation = pathAsync.valueOrNull?.conversation;
    final title = (conversation == null || conversation.title.isEmpty)
        ? 'New conversation'
        : conversation.title;
    final modelName = _resolveModelName(
      ref.watch(modelListProvider),
      conversation?.modelId ?? '',
    );

    return Container(
      height: 56,
      padding: EdgeInsets.symmetric(horizontal: spacing.s24),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (modelName != null) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colors.chalk,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                modelName,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.graphite,
                    ),
              ),
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
}
