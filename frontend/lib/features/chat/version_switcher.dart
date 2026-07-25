/// 在 sibling assistant reply 之间移动 visible path 的 `< n / m >` switcher。
///
/// 根据 `product.md` §6.3，当 assistant message 有多个 sibling（同一 parent user message
/// 下的 alternative reply）时，UI 显示小型 `< 2 / 3 >` control。点击左或右 arrow 会要求
/// backend 将 conversation current leaf 移动到 previous 或 next sibling，并用新 branch 替换
/// visible path。
///
/// 只有存在两个或更多 sibling 时显示 switcher。单个 sibling 没有可切换目标，因此 widget
/// 不返回内容。
library;

import 'package:flutter/material.dart';

import '../../core/models/message.dart';
import '../../core/theme/colors.dart';

/// 单个 message tree node 的 `< n / m >` branch switcher。
class VersionSwitcher extends StatelessWidget {
  /// 创建 switcher。
  const VersionSwitcher({
    required this.siblings,
    required this.onSwitch,
    super.key,
  });

  /// 此 switcher 所属 message 的 sibling metadata。`siblings` list 包含与 parent 共享的每个
  /// message id（包括 active one）；`activeId` 是当前 visible path 经过的 message。
  final SiblingInfo siblings;

  /// User 点击 arrow 时，携带目标 sibling 的 message id 调用。调用方应将它转发给
  /// `CurrentConversationNotifier.switchBranch`。
  final void Function(int leafId) onSwitch;

  @override
  Widget build(BuildContext context) {
    // 只有一条 reply 时完全隐藏 switcher。Product doc 规定 switcher 在“assistant message
    // has more than one sibling reply”时出现。
    if (siblings.siblings.length < 2) {
      return const SizedBox.shrink();
    }

    final colors = Theme.of(context).extension<ParloColors>()!;
    final activeIndex = siblings.siblings.indexOf(siblings.activeId);
    // Position 使用 1-based 显示，使 user 看到“2 / 3”，而不是带 zero-indexed number 的
    // “1 / 2”。
    final position = activeIndex + 1;
    final total = siblings.siblings.length;
    final canGoPrevious = activeIndex > 0;
    final canGoNext = activeIndex < siblings.siblings.length - 1;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          iconSize: 16,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          color: canGoPrevious ? colors.ashen : colors.mist,
          onPressed: canGoPrevious
              ? () => onSwitch(siblings.siblings[activeIndex - 1])
              : null,
          tooltip: 'Previous version',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            '$position / $total',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.ashen,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          iconSize: 16,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          color: canGoNext ? colors.ashen : colors.mist,
          onPressed: canGoNext
              ? () => onSwitch(siblings.siblings[activeIndex + 1])
              : null,
          tooltip: 'Next version',
        ),
      ],
    );
  }
}
