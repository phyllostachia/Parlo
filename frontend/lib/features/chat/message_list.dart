/// 一个 conversation 的可滚动 message flow。
///
/// 监听 [currentConversationProvider] 提供的 conversation path，并将每个 node 渲染为
/// [MessageBubble]。新 content 到达时自动滚到底部，但只有 user 已经接近底部时才执行，
/// 因此向上滚动阅读之前内容不会被打断。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/message.dart';
import '../../core/theme/spacing.dart';
import '../../core/widgets/error_banner.dart';
import 'chat_providers.dart';
import 'message_bubble.dart';

/// Message list widget。
class MessageList extends ConsumerStatefulWidget {
  /// 创建 list。
  const MessageList({required this.conversationId, super.key});

  /// 要渲染 path 的 conversation。
  final int conversationId;

  @override
  ConsumerState<MessageList> createState() => _MessageListState();
}

class _MessageListState extends ConsumerState<MessageList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Path 变化时（new message、new token）跳到底部，但只有 user 已经接近底部时才执行。
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
      // 使用 post-frame callback，使 new content layout 完成后再读取 maxScrollExtent。
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
        // Design “Message Flow”：column 宽 720px，在 canvas 中居中；垂直 padding 32px，
        // message 之间间隔 32px。
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
                // 最后一条 assistant message 尚未 complete 时视为“streaming”；它驱动 loading
                // cursor 和“Thinking…”placeholder。
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

/// Conversation 还没有 message 时显示的 placeholder。
///
/// 实际上，chat screen 只会在 empty state 的“create + post first message”和 path refresh
/// 之间短暂到达这里；chat screen 监听 provider 时，path 通常已经包含 user message 和
/// assistant placeholder。此 placeholder 是 graceful fallback。
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
