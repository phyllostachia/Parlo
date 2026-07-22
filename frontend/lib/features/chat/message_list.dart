/// The scrollable message flow for one conversation.
///
/// Watches the conversation path from [currentConversationProvider] and
/// renders each node as a [MessageBubble]. Auto-scrolls to the bottom when
/// new content arrives, but only if the user is already near the bottom — so
/// scrolling up to read earlier content is not interrupted.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/message.dart';
import '../../core/theme/spacing.dart';
import '../../core/widgets/error_banner.dart';
import 'chat_providers.dart';
import 'message_bubble.dart';

/// The message list widget.
class MessageList extends ConsumerStatefulWidget {
  /// Creates the list.
  const MessageList({required this.conversationId, super.key});

  /// The conversation whose path to render.
  final int conversationId;

  @override
  ConsumerState<MessageList> createState() => _MessageListState();
}

class _MessageListState extends ConsumerState<MessageList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Jump to the bottom whenever the path changes (new message, new token),
    // but only if the user is already near the bottom.
    ref.listenManual(
      currentConversationProvider(widget.conversationId),
      (_, _) => _jumpToBottomIfNearBottom(),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _jumpToBottomIfNearBottom() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final isNearBottom = position.pixels >= position.maxScrollExtent - 120;
    if (isNearBottom) {
      // Use a post-frame callback so the new content has been laid out
      // before we read maxScrollExtent.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pathAsync = ref.watch(
      currentConversationProvider(widget.conversationId),
    );
    final spacing = Theme.of(context).extension<ParloSpacing>()!;

    return pathAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorBanner(
        message: 'Could not load the conversation.',
        error: error,
        onRetry: () =>
            ref.invalidate(currentConversationProvider(widget.conversationId)),
      ),
      data: (path) {
        if (path.path.isEmpty) {
          return const _EmptyConversation();
        }
        final streamState = ref.watch(streamStateProvider);
        // Design "Message Flow": the column is 720px wide, centered on the
        // canvas, with 32px of vertical padding and 32px between messages.
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(
                horizontal: spacing.s16,
                vertical: spacing.s32,
              ),
              itemCount: path.path.length,
              itemBuilder: (context, index) {
                final node = path.path[index];
                final isLast = index == path.path.length - 1;
                // The last assistant message is "streaming" if it is not yet
                // complete; that drives the loading cursor and the "Thinking…"
                // placeholder.
                final isStreaming =
                    isLast &&
                    node.message.role == MessageRole.assistant &&
                    !node.message.isComplete;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: MessageBubble(
                    message: node.message,
                    conversation: path.conversation,
                    siblings: node.siblings,
                    isStreaming: isStreaming,
                    isLast: isLast,
                    streamState: streamState,
                    onRegenerate: (assistantMessageId) {
                      ref
                          .read(
                            currentConversationProvider(
                              widget.conversationId,
                            ).notifier,
                          )
                          .regenerate(assistantMessageId: assistantMessageId);
                    },
                    onSwitchBranch: (leafId) {
                      ref
                          .read(
                            currentConversationProvider(
                              widget.conversationId,
                            ).notifier,
                          )
                          .switchBranch(leafId: leafId);
                    },
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// The placeholder shown for a conversation with no messages yet.
///
/// In practice the chat screen reaches this only briefly between the empty
/// state's "create + post first message" and the path refresh; by the time
/// the chat screen watches the provider, the path has the user message and
/// assistant placeholder. The placeholder is a graceful fallback.
class _EmptyConversation extends StatelessWidget {
  const _EmptyConversation();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Say hello to start the conversation.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
