/// The action bar shown under an assistant message: Copy and Regenerate.
///
/// Per `product.md` §6.3 the actions appear on hover on the web. On mobile
/// there is no hover, so the actions are always visible. The parent widget
/// decides which mode to use by reading [PlatformCapabilities]; this widget
/// just renders the buttons and forwards the taps.
///
/// Copy places the message body on the system clipboard and briefly shows a
/// "Copied" label in place of the Copy icon so the user gets feedback.
/// Regenerate forwards to the caller, which calls
/// `CurrentConversationNotifier.regenerate`.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/colors.dart';

/// The row of actions under an assistant message.
class MessageActions extends StatefulWidget {
  /// Creates the action bar.
  const MessageActions({
    required this.content,
    required this.onRegenerate,
    required this.canRegenerate,
    super.key,
  });

  /// The text to copy when the user taps Copy.
  final String content;

  /// Called when the user taps Regenerate. The caller is expected to forward
  /// this to the conversation notifier.
  final VoidCallback onRegenerate;

  /// Whether regenerate is available for this message. The caller disables
  /// it while a stream is running or when the message is not on the visible
  /// path's leaf.
  final bool canRegenerate;

  @override
  State<MessageActions> createState() => _MessageActionsState();
}

class _MessageActionsState extends State<MessageActions> {
  /// Whether the "Copied" label is currently shown in place of the Copy icon.
  bool _showCopied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.content));
    if (!mounted) return;
    setState(() => _showCopied = true);
    // Show the confirmation for a short beat, then revert to the Copy icon.
    Future<void>.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _showCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ParloColors>()!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_showCopied)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Copied',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.graphite,
                  ),
            ),
          )
        else
          _ActionButton(
            icon: Icons.copy_outlined,
            tooltip: 'Copy',
            onPressed: _copy,
          ),
        if (widget.canRegenerate) ...[
          const SizedBox(width: 4),
          _ActionButton(
            icon: Icons.refresh,
            tooltip: 'Regenerate',
            onPressed: widget.onRegenerate,
          ),
        ],
      ],
    );
  }
}

/// A small icon button used inside the action bar.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ParloColors>()!;
    return IconButton(
      icon: Icon(icon),
      iconSize: 16,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      color: colors.ashen,
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }
}
