/// The `< n / m >` switcher that moves the visible path between sibling
/// assistant replies.
///
/// Per `product.md` §6.3, when an assistant message has more than one
/// sibling (alternative replies under the same parent user message), the UI
/// shows a small `< 2 / 3 >` control. Clicking the left or right arrow asks
/// the backend to move the conversation's current leaf to the previous or
/// next sibling, and the visible path is replaced with the new branch.
///
/// The switcher is only shown when there are two or more siblings. A single
/// sibling means there is nothing to switch to, so the widget returns nothing.
library;

import 'package:flutter/material.dart';

import '../../core/models/message.dart';
import '../../core/theme/colors.dart';

/// A `< n / m >` branch switcher for one message tree node.
class VersionSwitcher extends StatelessWidget {
  /// Creates the switcher.
  const VersionSwitcher({
    required this.siblings,
    required this.onSwitch,
    super.key,
  });

  /// The sibling metadata for the message this switcher sits under. The
  /// `siblings` list is every message id sharing the parent (including the
  /// active one); `activeId` is the one the visible path currently goes
  /// through.
  final SiblingInfo siblings;

  /// Called with the target sibling's message id when the user clicks an
  /// arrow. The caller is expected to forward this to
  /// `CurrentConversationNotifier.switchBranch`.
  final void Function(int leafId) onSwitch;

  @override
  Widget build(BuildContext context) {
    // Hide the switcher entirely when there is only one reply. The product
    // doc says the switcher appears "when an assistant message has more
    // than one sibling reply".
    if (siblings.siblings.length < 2) {
      return const SizedBox.shrink();
    }

    final colors = Theme.of(context).extension<ParloColors>()!;
    final activeIndex = siblings.siblings.indexOf(siblings.activeId);
    // Position is shown 1-based so the user reads "2 / 3", not "1 / 2" with
    // zero-indexed numbers.
    final position = activeIndex + 1;
    final total = siblings.siblings.length;
    final canGoPrevious = activeIndex > 0;
    final canGoNext = activeIndex < siblings.siblings.length - 1;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          iconSize: 18,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          color: canGoPrevious ? colors.graphite : colors.mist,
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
                  color: colors.graphite,
                ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          iconSize: 18,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          color: canGoNext ? colors.graphite : colors.mist,
          onPressed: canGoNext
              ? () => onSwitch(siblings.siblings[activeIndex + 1])
              : null,
          tooltip: 'Next version',
        ),
      ],
    );
  }
}
