/// A single message in the conversation path.
///
/// Per `product.md` §6.3:
/// - User messages get a subtle bubble with the text and (if any) image.
/// - Assistant messages render as Markdown with a model-name footer, an
///   optional collapsible thinking strip, a version switcher when there
///   are sibling replies, a hover action bar (Copy / Regenerate), and a
///   "connection broken, retry" button when the stream dropped.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

import '../../core/models/conversation.dart';
import '../../core/models/message.dart';
import '../../core/models/model.dart';
import '../../core/network/api_client.dart';
import '../../core/platform/platform_capabilities.dart';
import '../../core/platform/platform_providers.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import 'chat_providers.dart';
import 'message_actions.dart';
import 'thinking_strip.dart';
import 'version_switcher.dart';

/// A single message row.
class MessageBubble extends ConsumerWidget {
  /// Creates the bubble.
  const MessageBubble({
    required this.message,
    required this.conversation,
    required this.siblings,
    required this.isStreaming,
    required this.isLast,
    required this.streamState,
    required this.onRegenerate,
    required this.onSwitchBranch,
    super.key,
  });

  /// The message to render.
  final Message message;

  /// The conversation the message belongs to. Used to resolve the model
  /// display name shown under assistant messages.
  final Conversation conversation;

  /// The sibling metadata for this message's position on the path. Drives
  /// the version switcher for assistant messages.
  final SiblingInfo siblings;

  /// Whether this message is the one currently being streamed.
  final bool isStreaming;

  /// Whether this is the last message on the visible path. The retry button
  /// only appears on the last assistant message.
  final bool isLast;

  /// The current stream state for the conversation. Used to decide whether
  /// to show the "connection broken, retry" button.
  final StreamState streamState;

  /// Called with an assistant message id when the user asks to regenerate
  /// (or retry) a reply.
  final void Function(int assistantMessageId) onRegenerate;

  /// Called with a target leaf message id when the user clicks the version
  /// switcher.
  final void Function(int leafId) onSwitchBranch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (message.role) {
      case MessageRole.user:
        return _UserBubble(message: message, ref: ref);
      case MessageRole.assistant:
        return _AssistantBlock(
          message: message,
          conversation: conversation,
          siblings: siblings,
          isStreaming: isStreaming,
          isLast: isLast,
          streamState: streamState,
          onRegenerate: onRegenerate,
          onSwitchBranch: onSwitchBranch,
          ref: ref,
        );
      case MessageRole.system:
        return _SystemBlock(message: message);
    }
  }
}

/// A user message: subtle bubble, text, and optional image.
class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.message, required this.ref});

  final Message message;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ParloColors>()!;
    final spacing = Theme.of(context).extension<ParloSpacing>()!;
    final baseUrl = ref.read(baseUrlProvider);
    final imageUrl = message.imageUrl == null || message.imageUrl!.isEmpty
        ? null
        : '$baseUrl${message.imageUrl}';

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Container(
          decoration: BoxDecoration(
            color: colors.softStone,
            borderRadius: BorderRadius.circular(ParloRadius.light.card),
          ),
          padding: EdgeInsets.all(spacing.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.content.isNotEmpty)
                Text(
                  message.content,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colors.carbonInk,
                      ),
                ),
              if (imageUrl != null) ...[
                SizedBox(height: spacing.s8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(ParloRadius.light.card),
                  child: Image.network(imageUrl),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// An assistant message: optional thinking strip, Markdown body, optional
/// streaming indicator, version switcher, hover action bar, and a retry
/// button when the stream dropped.
class _AssistantBlock extends ConsumerStatefulWidget {
  const _AssistantBlock({
    required this.message,
    required this.conversation,
    required this.siblings,
    required this.isStreaming,
    required this.isLast,
    required this.streamState,
    required this.onRegenerate,
    required this.onSwitchBranch,
    required this.ref,
  });

  final Message message;
  final Conversation conversation;
  final SiblingInfo siblings;
  final bool isStreaming;
  final bool isLast;
  final StreamState streamState;
  final void Function(int assistantMessageId) onRegenerate;
  final void Function(int leafId) onSwitchBranch;
  final WidgetRef ref;

  @override
  ConsumerState<_AssistantBlock> createState() => _AssistantBlockState();
}

class _AssistantBlockState extends ConsumerState<_AssistantBlock> {
  /// Whether the pointer is currently over this message. On the web, the
  /// action bar is only shown while this is `true`. On mobile, the action
  /// bar is always shown (the platform has no hover), so this field is
  /// ignored in that mode.
  bool _isHovered = false;

  bool get _showRetryButton =>
      widget.isLast &&
      widget.message.role == MessageRole.assistant &&
      (widget.streamState == StreamState.error ||
          widget.streamState == StreamState.stopped);

  bool get _showActions =>
      widget.message.isComplete &&
      !widget.isStreaming;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ParloColors>()!;
    final spacing = Theme.of(context).extension<ParloSpacing>()!;
    final models = widget.ref.watch(modelListProvider);
    final modelName = _resolveModelName(models, widget.conversation.modelId);
    final capabilities = widget.ref.read(platformCapabilitiesProvider);
    final showActionsOnHover =
        capabilities.messageActions == MessageActionsMode.hover;

    // The action bar is shown when the message is complete AND (we are on
    // mobile, which always shows it, OR the pointer is hovering on web).
    final actionsVisible = _showActions &&
        (!showActionsOnHover || _isHovered);

    final hasReasoning =
        widget.message.reasoning != null && widget.message.reasoning!.isNotEmpty;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasReasoning)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ThinkingStrip(
                  reasoning: widget.message.reasoning!,
                  isStreaming: widget.isStreaming &&
                      widget.message.content.isEmpty,
                ),
              ),
            if (widget.message.content.isEmpty && widget.isStreaming)
              _StreamingPlaceholder()
            else
              GptMarkdown(
                widget.message.content,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colors.carbonInk,
                    ),
              ),
            if (widget.isStreaming && widget.message.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: _StreamingDot(color: colors.clay),
              ),
            if (_showRetryButton)
              Padding(
                padding: EdgeInsets.only(top: spacing.s8),
                child: _RetryButton(
                  streamState: widget.streamState,
                  onPressed: () =>
                      widget.onRegenerate(widget.message.id),
                ),
              ),
            if (widget.message.isComplete) ...[
              SizedBox(height: spacing.s8),
              Row(
                children: [
                  if (actionsVisible)
                    MessageActions(
                      content: widget.message.content,
                      onRegenerate: () =>
                          widget.onRegenerate(widget.message.id),
                      canRegenerate: !widget.isStreaming,
                    ),
                  Expanded(
                    child: VersionSwitcher(
                      siblings: widget.siblings,
                      onSwitch: widget.onSwitchBranch,
                    ),
                  ),
                  if (modelName != null)
                    Text(
                      modelName,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Finds the display name for the conversation's model id, or `null`.
  String? _resolveModelName(List<ModelRead> models, String modelId) {
    for (final model in models) {
      if (model.id == modelId) return model.displayName;
    }
    return null;
  }
}

/// A small "thinking…" placeholder shown while the assistant's first token
/// has not yet arrived.
class _StreamingPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ParloColors>()!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colors.pebble,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Thinking…',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// A single pulsing dot shown at the end of a streaming assistant message.
class _StreamingDot extends StatefulWidget {
  const _StreamingDot({required this.color});

  final Color color;

  @override
  State<_StreamingDot> createState() => _StreamingDotState();
}

class _StreamingDotState extends State<_StreamingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// The "connection broken, retry" button shown when the stream dropped or
/// the user stopped it. The label changes with the stream state so the user
/// understands what happened.
class _RetryButton extends StatelessWidget {
  const _RetryButton({
    required this.streamState,
    required this.onPressed,
  });

  final StreamState streamState;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = streamState == StreamState.stopped
        ? 'Continue'
        : 'Connection broken. Retry';
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.refresh, size: 16),
      label: Text(label),
    );
  }
}

/// A system message — rarely shown, kept minimal.
class _SystemBlock extends StatelessWidget {
  const _SystemBlock({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ParloColors>()!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.chalk,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message.content,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
