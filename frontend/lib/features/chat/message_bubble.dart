/// Conversation path 中的一条 message。
///
/// 根据 `product.md` §6.3：
/// - User message 使用包含 text 和 image（如果有）的 subtle bubble。
/// - Assistant message 渲染为 Markdown，并带 model-name footer、可选的 collapsible thinking
///   strip；有 sibling reply 时显示 version switcher，显示 hover action bar（Copy / Regenerate），
///   stream drop 时显示“connection broken, retry”button。
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
import '../../core/theme/fonts.dart';
import '../../core/theme/spacing.dart';
import 'chat_providers.dart';
import 'message_actions.dart';
import 'thinking_strip.dart';
import 'version_switcher.dart';

/// 使用对话字体渲染 Markdown，同时为 fenced code 和 inline code 使用代码字体。
Widget _conversationMarkdown(String content, Color textColor) {
  return GptMarkdown(
    content,
    style: TanFonts.naturalLanguageStyle.copyWith(color: textColor),
    codeBuilder: (context, name, code, _) =>
        _MarkdownCodeBlock(name: name, code: code),
    highlightBuilder: (context, text, inheritedStyle) => Text(
      text,
      style: TanFonts.codeStyle.copyWith(
        color: inheritedStyle.color ?? textColor,
        backgroundColor: inheritedStyle.backgroundColor,
      ),
    ),
  );
}

/// 单条 message row。
class MessageBubble extends ConsumerWidget {
  /// 创建 bubble。
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

  /// 要渲染的 message。
  final Message message;

  /// Message 所属的 conversation。用于解析 assistant message 下方显示的 model display name。
  final Conversation conversation;

  /// 此 message 在 path 上所在位置的 sibling metadata。驱动 assistant message 的 version switcher。
  final SiblingInfo siblings;

  /// 此 message 是否是当前正在 streaming 的 message。
  final bool isStreaming;

  /// 此 message 是否是 visible path 的最后一条。Retry button 只出现在最后一条 assistant message 上。
  final bool isLast;

  /// Conversation 当前的 stream state。用于决定是否显示“connection broken, retry”button。
  final StreamState streamState;

  /// User 要求 regenerate（或 retry）reply 时，携带 assistant message id 调用。
  final void Function(int assistantMessageId) onRegenerate;

  /// User 点击 version switcher 时，携带目标 leaf message id 调用。
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

/// User message：subtle bubble、text 和可选 image。
class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.message, required this.ref});

  final Message message;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<TanColors>()!;
    final spacing = Theme.of(context).extension<TanSpacing>()!;
    final baseUrl = ref.read(baseUrlProvider);
    final imageUrl = message.imageUrl == null || message.imageUrl!.isEmpty
        ? null
        : '$baseUrl${message.imageUrl}';

    // Design “User Message Row”：bubble 贴近 720px column 的右边缘；bubble 自身的 text
    // width 上限约为 420px。
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 452),
        child: Container(
          decoration: BoxDecoration(
            color: colors.softStone,
            borderRadius: BorderRadius.circular(TanRadius.light.card),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.content.isNotEmpty)
                _conversationMarkdown(message.content, colors.carbonInk),
              if (imageUrl != null) ...[
                SizedBox(height: spacing.s8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(TanRadius.light.card),
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

/// Assistant message：可选 thinking strip、带 chunk 淡入效果的 Markdown body、可选 streaming
/// indicator、version switcher、hover action bar，以及 stream drop 时显示的 retry button。
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
  /// Pointer 当前是否位于此 message 上。Web 上只有它为 `true` 时显示 action bar。Mobile
  /// 始终显示 action bar（platform 没有 hover），因此该 field 在该 mode 下会被忽略。
  bool _isHovered = false;

  bool get _showRetryButton =>
      widget.isLast &&
      widget.message.role == MessageRole.assistant &&
      (widget.streamState == StreamState.error ||
          widget.streamState == StreamState.stopped);

  bool get _showActions => widget.message.isComplete && !widget.isStreaming;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<TanColors>()!;
    final spacing = Theme.of(context).extension<TanSpacing>()!;
    final models = widget.ref.watch(modelListProvider);
    final modelName = _resolveModelName(models, widget.conversation.modelId);
    final capabilities = widget.ref.read(platformCapabilitiesProvider);
    final showActionsOnHover =
        capabilities.messageActions == MessageActionsMode.hover;

    // Message 完成且（当前是始终显示 action 的 mobile，或 pointer 正在 Web 上 hover）时
    // 显示 action bar。
    final actionsVisible = _showActions && (!showActionsOnHover || _isHovered);

    final hasReasoning =
        widget.message.reasoning != null &&
        widget.message.reasoning!.isNotEmpty;

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
                  key: ValueKey<String>('thinking-${widget.message.id}'),
                  reasoning: widget.message.reasoning!,
                  reasoningDuration: widget.message.reasoningDurationMs == null
                      ? null
                      : Duration(
                          milliseconds: widget.message.reasoningDurationMs!,
                        ),
                  isStreaming:
                      widget.isStreaming && widget.message.content.isEmpty,
                ),
              ),
            // 首个 token 到达前不显示额外 loading UI，避免“Thinking…”转圈打断对话节奏。
            // 流式 token 到达后，以短暂淡入缓和新文字突然出现的观感。
            if (widget.message.content.isNotEmpty)
              widget.isStreaming
                  ? _StreamingMarkdown(
                      key: ValueKey<String>(
                        'streaming-markdown-${widget.message.id}',
                      ),
                      content: widget.message.content,
                      textColor: colors.carbonInk,
                    )
                  : _conversationMarkdown(
                      widget.message.content,
                      colors.carbonInk,
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
                  onPressed: () => widget.onRegenerate(widget.message.id),
                ),
              ),
            if (widget.message.isComplete) ...[
              SizedBox(height: spacing.s8),
              // Design “Assistant Footer Row”：左侧显示 model attribution，中间显示 version
              // switcher，右侧显示 hover action。
              Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: modelName != null
                          ? Text(
                              modelName,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: colors.pebble,
                                    fontSize: 12,
                                  ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                  VersionSwitcher(
                    siblings: widget.siblings,
                    onSwitch: widget.onSwitchBranch,
                  ),
                  Expanded(
                    // 始终为 hover action 预留高度，避免 Web 上按钮出现时把 footer
                    // row 撑高、导致整条 assistant message 发生垂直位移。
                    child: SizedBox(
                      height: 28,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: actionsVisible
                            ? MessageActions(
                                content: widget.message.content,
                                onRegenerate: () =>
                                    widget.onRegenerate(widget.message.id),
                                canRegenerate: !widget.isStreaming,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 查找 conversation model id 的 display name；找不到时为 `null`。
  String? _resolveModelName(List<ModelRead> models, String modelId) {
    for (final model in models) {
      if (model.id == modelId) return model.displayName;
    }
    return null;
  }
}

/// 流式 Markdown 正文。
///
/// Markdown renderer 会在每个 SSE delta 到达后重新解析完整 content，因此无法可靠地为
/// 任意 Markdown 结构单独包裹新字符。这里以很小的 opacity 幅度重播整个正文的 140ms
/// 淡入；已显示内容不会闪烁，新追加字符的出现则不再生硬。
class _StreamingMarkdown extends StatefulWidget {
  const _StreamingMarkdown({
    required this.content,
    required this.textColor,
    super.key,
  });

  final String content;
  final Color textColor;

  @override
  State<_StreamingMarkdown> createState() => _StreamingMarkdownState();
}

class _StreamingMarkdownState extends State<_StreamingMarkdown>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _opacity = Tween<double>(
      begin: 0.72,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _StreamingMarkdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.content != oldWidget.content) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final markdown = _conversationMarkdown(widget.content, widget.textColor);
    if (disableAnimations) return markdown;

    return FadeTransition(
      key: const ValueKey<String>('streaming-markdown-fade'),
      opacity: _opacity,
      child: markdown,
    );
  }
}

/// Markdown fenced code block，使用集中配置的代码字体。
class _MarkdownCodeBlock extends StatelessWidget {
  const _MarkdownCodeBlock({required this.name, required this.code});

  final String name;
  final String code;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<TanColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.softStone,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (name.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                name,
                style: textTheme.labelSmall?.copyWith(color: colors.ashen),
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              code,
              style: TanFonts.codeStyle.copyWith(color: colors.carbonInk),
            ),
          ),
        ],
      ),
    );
  }
}

/// Streaming assistant message 末尾显示的单个 pulsing dot。
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
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}

/// Stream drop 或 user stop 时显示的“connection broken, retry”button。Label 会随 stream
/// state 变化，使 user 理解发生了什么。
class _RetryButton extends StatelessWidget {
  const _RetryButton({required this.streamState, required this.onPressed});

  final StreamState streamState;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = streamState == StreamState.stopped ? '继续' : '连接中断，重试';
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.refresh, size: 16),
      label: Text(label),
    );
  }
}

/// System message：很少显示，并保持 minimal。
class _SystemBlock extends StatelessWidget {
  const _SystemBlock({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<TanColors>()!;
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
