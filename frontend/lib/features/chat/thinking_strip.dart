/// 在主 reply body 上方显示 assistant reasoning（“thinking”trace）的 collapsible strip。
///
/// 根据 `product.md` §6.3，此 strip 具有以下特征：
/// - Optional：只有 message 有 reasoning text 时显示。
/// - 默认 collapsed；user 点击后展开。
/// - Streaming 时 live：reasoning token 到达期间，pulsing indicator 标记 strip 处于 active，
///   让 user 知道 model 仍在 thinking，并可以展开观看 reasoning scroll。
///
/// Strip 不标注 thinking-effort level：该 value 已位于 top bar，再次显示只会使 message 杂乱。
library;

import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/fonts.dart';

/// 单条 assistant message reasoning 的 collapsible view。
class ThinkingStrip extends StatefulWidget {
  /// 创建 strip。
  const ThinkingStrip({
    required this.reasoning,
    required this.isStreaming,
    super.key,
  });

  /// 展开时显示的 reasoning text。Reasoning 为空表示完全不显示 strip（parent 会隐藏它）。
  final String reasoning;

  /// 此 message 的 reasoning 是否仍在 streaming。为 `true` 时，strip header 显示 pulsing
  /// indicator，使 user 知道 model 仍在 thinking。
  final bool isStreaming;

  @override
  State<ThinkingStrip> createState() => _ThinkingStripState();
}

class _ThinkingStripState extends State<ThinkingStrip> {
  /// User 是否展开 strip 以阅读 reasoning。
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<TanColors>()!;

    return Container(
      decoration: BoxDecoration(
        color: colors.softStone,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(
            isExpanded: _isExpanded,
            isStreaming: widget.isStreaming,
            onTap: () => setState(() => _isExpanded = !_isExpanded),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: _ReasoningBody(
                reasoning: widget.reasoning,
                isStreaming: widget.isStreaming,
              ),
            ),
        ],
      ),
    );
  }
}

/// Thinking strip 可点击的 header row。
///
/// 显示在 collapsed（right）和 expanded（down）之间变化的 chevron、“Thinking”label，以及
/// reasoning 仍在 streaming 时显示的小 pulsing dot。整个 row 都是 button，因此 user 可以
/// 点击任意位置进行 toggle。
class _Header extends StatelessWidget {
  const _Header({
    required this.isExpanded,
    required this.isStreaming,
    required this.onTap,
  });

  final bool isExpanded;
  final bool isStreaming;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<TanColors>()!;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              isExpanded ? Icons.expand_more : Icons.chevron_right,
              size: 18,
              color: colors.graphite,
            ),
            const SizedBox(width: 6),
            Text(
              'Thinking',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: colors.graphite),
            ),
            if (isStreaming) ...[
              const SizedBox(width: 8),
              _PulsingDot(color: colors.clay),
            ],
          ],
        ),
      ),
    );
  }
}

/// Expanded strip 的 body，显示 reasoning text。
///
/// Reasoning 仍在 streaming 时，body 自动滚到底部，使最新 token 保持可见。Message complete
/// 后，body 是静态的可滚动 view。
class _ReasoningBody extends StatefulWidget {
  const _ReasoningBody({required this.reasoning, required this.isStreaming});

  final String reasoning;
  final bool isStreaming;

  @override
  State<_ReasoningBody> createState() => _ReasoningBodyState();
}

class _ReasoningBodyState extends State<_ReasoningBody> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _jumpToBottom();
  }

  @override
  void didUpdateWidget(covariant _ReasoningBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 新 reasoning token 到达时，保持最新 text 可见。
    if (widget.reasoning != oldWidget.reasoning) {
      _jumpToBottom();
    }
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<TanColors>()!;
    // 限制 height，避免较长 reasoning trace 将 reply body 推出 screen；user 改为在此 box
    // 内滚动。
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 240),
      child: SingleChildScrollView(
        controller: _scrollController,
        child: SelectableText(
          widget.reasoning,
          style: TanFonts.naturalLanguageStyle.copyWith(
            color: colors.graphite,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

/// 通过 pulse（淡入淡出）标记 active streaming 的小 dot。
class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});

  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
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
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
