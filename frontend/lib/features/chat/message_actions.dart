/// Assistant message 下方显示的 action bar：Copy 和 Regenerate。
///
/// 根据 `product.md` §6.3，Web 上 action 在 hover 时显示。Mobile 没有 hover，因此 action
/// 始终可见。Parent widget 读取 [PlatformCapabilities] 决定 mode；此 widget 只负责渲染
/// button 并转发 tap。
///
/// Copy 将 message body 放到 system clipboard，并短暂以“Copied”label 替代 Copy icon，向
/// user 提供反馈。Regenerate 转发给调用方，由调用方调用 `CurrentConversationNotifier.regenerate`。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/colors.dart';

/// Assistant message 下方的 action row。
class MessageActions extends StatefulWidget {
  /// 创建 action bar。
  const MessageActions({
    required this.content,
    required this.onRegenerate,
    required this.canRegenerate,
    super.key,
  });

  /// User tap Copy 时要复制的 text。
  final String content;

  /// User tap Regenerate 时调用。调用方应将它转发给 conversation notifier。
  final VoidCallback onRegenerate;

  /// 此 message 是否可 regenerate。Stream 运行时，或 message 不在 visible path leaf 上时，
  /// 调用方会禁用它。
  final bool canRegenerate;

  @override
  State<MessageActions> createState() => _MessageActionsState();
}

class _MessageActionsState extends State<MessageActions> {
  /// 当前是否以“Copied”label 替代 Copy icon。
  bool _showCopied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.content));
    if (!mounted) return;
    setState(() => _showCopied = true);
    // 短暂显示 confirmation，然后恢复为 Copy icon。
    Future<void>.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _showCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<TanColors>()!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_showCopied)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Copied',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: colors.graphite),
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

/// Action bar 内使用的小型 icon button。
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
    final colors = Theme.of(context).extension<TanColors>()!;
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
