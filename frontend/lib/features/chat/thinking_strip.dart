/// A collapsible strip that shows the assistant's reasoning ("thinking"
/// trace) above the main reply body.
///
/// Per `product.md` §6.3 the strip is:
/// - Optional: only shown when the message has reasoning text.
/// - Collapsed by default; the user clicks to expand.
/// - Live during streaming: while the reasoning tokens arrive, a pulsing
///   indicator marks the strip as active so the user knows the model is
///   still thinking, and the user can expand to watch the reasoning scroll.
///
/// The strip does not label the thinking-effort level: that value already
/// lives in the top bar and would only clutter the message.
library;

import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';

/// A collapsible view of one assistant message's reasoning.
class ThinkingStrip extends StatefulWidget {
  /// Creates the strip.
  const ThinkingStrip({
    required this.reasoning,
    required this.isStreaming,
    super.key,
  });

  /// The reasoning text to show when expanded. Empty reasoning means the
  /// strip is not shown at all (the parent hides it).
  final String reasoning;

  /// Whether the reasoning is still being streamed for this message. While
  /// `true`, the strip header shows a pulsing indicator so the user can tell
  /// the model is still thinking.
  final bool isStreaming;

  @override
  State<ThinkingStrip> createState() => _ThinkingStripState();
}

class _ThinkingStripState extends State<ThinkingStrip> {
  /// Whether the user has expanded the strip to read the reasoning.
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ParloColors>()!;

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

/// The clickable header row of the thinking strip.
///
/// Shows a chevron that rotates between collapsed (right) and expanded
/// (down), the "Thinking" label, and a small pulsing dot when the reasoning
/// is still streaming. The whole row is a button so the user can click
/// anywhere on it to toggle.
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
    final colors = Theme.of(context).extension<ParloColors>()!;
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
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.graphite,
                  ),
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

/// The body of the expanded strip, showing the reasoning text.
///
/// When the reasoning is still streaming, the body auto-scrolls to the bottom
/// so the latest tokens stay visible. When the message is complete, the body
/// is a static, scrollable view.
class _ReasoningBody extends StatefulWidget {
  const _ReasoningBody({
    required this.reasoning,
    required this.isStreaming,
  });

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
    // When new reasoning tokens arrive, keep the latest text in view.
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
    final colors = Theme.of(context).extension<ParloColors>()!;
    // Cap the height so a long reasoning trace does not push the reply body
    // off the screen; the user scrolls inside this box instead.
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 240),
      child: SingleChildScrollView(
        controller: _scrollController,
        child: SelectableText(
          widget.reasoning,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.graphite,
                height: 1.5,
              ),
        ),
      ),
    );
  }
}

/// A small dot that pulses (fades in and out) to mark active streaming.
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
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
