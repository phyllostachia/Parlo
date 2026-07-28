/// 在主 reply body 上方显示 assistant reasoning（“thinking”trace）的可折叠摘要。
///
/// 默认只显示一个紧凑的「已思考 N 秒」短条。点击后，reasoning 文本以 200ms 动画展开；
/// 文本没有卡片背景，使用与正文一致的字体、较小字号和较浅颜色。
library;

import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/fonts.dart';

/// 单条 assistant message reasoning 的 collapsible view。
class ThinkingStrip extends StatefulWidget {
  /// 创建 strip。
  const ThinkingStrip({
    required this.reasoning,
    required this.reasoningDuration,
    required this.isStreaming,
    super.key,
  });

  /// 展开时显示的 reasoning text。Reasoning 为空表示完全不显示 strip（parent 会隐藏它）。
  final String reasoning;

  /// Backend 持久化的 reasoning 耗时。旧 message 没有该值时回退到一般性文案。
  final Duration? reasoningDuration;

  /// 此 message 的 reasoning 是否仍在 streaming。为 `true` 时显示进行中文案。
  final bool isStreaming;

  @override
  State<ThinkingStrip> createState() => _ThinkingStripState();
}

class _ThinkingStripState extends State<ThinkingStrip> {
  /// User 是否展开 strip 以阅读 reasoning。
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(
          isExpanded: _isExpanded,
          label: _labelFor(widget.reasoningDuration, widget.isStreaming),
          onTap: () => setState(() => _isExpanded = !_isExpanded),
        ),
        AnimatedSize(
          alignment: Alignment.topCenter,
          curve: Curves.easeOutCubic,
          duration: const Duration(milliseconds: 200),
          child: _isExpanded
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: _ReasoningBody(
                    reasoning: widget.reasoning,
                    isStreaming: widget.isStreaming,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  String _labelFor(Duration? duration, bool isStreaming) {
    if (duration == null) {
      return isStreaming ? '思考中' : '思考过程';
    }
    final seconds = (duration.inMilliseconds + 999) ~/ 1000;
    final displaySeconds = seconds < 1 ? 1 : seconds;
    return isStreaming ? '思考中 $displaySeconds 秒' : '已思考 $displaySeconds 秒';
  }
}

/// Thinking strip 可点击的 header row。
///
/// 显示在 collapsed（right）和 expanded（down）之间变化的 chevron 与耗时 label。
/// 整个短条都是 button，因此 user 可以点击任意位置进行 toggle。
class _Header extends StatelessWidget {
  const _Header({
    required this.isExpanded,
    required this.label,
    required this.onTap,
  });

  final bool isExpanded;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<TanColors>()!;
    return Semantics(
      button: true,
      expanded: isExpanded,
      label: '$label，${isExpanded ? '收起思考过程' : '展开思考过程'}',
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: colors.softStone,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.psychology_outlined, size: 14, color: colors.ashen),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.ashen,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                isExpanded ? Icons.expand_more : Icons.chevron_right,
                size: 16,
                color: colors.pebble,
              ),
            ],
          ),
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
    // 限制 height，避免较长 reasoning trace 将 reply body 推出 screen；user 改为在此区域
    // 内滚动。这里没有 background，展开文本直接落在与正文相同的页面表面上。
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 240),
      child: SingleChildScrollView(
        controller: _scrollController,
        child: SelectableText(
          widget.reasoning,
          style: TanFonts.naturalLanguageStyle.copyWith(
            color: colors.ashen,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
