/// Sidebar：应用中持久存在的左侧 column。
///
/// Layout 遵循 `product.md` §5：
/// - Top：创建新 profile 和新 conversation 的 button。
/// - Middle：profile folder tree（阶段 2 的 `ProfileTree`）。
/// - Bottom：打开 settings panel 的 gear button。
///
/// Sidebar 在各 route 中保持不变；只有 `currentConversationId` 变化时高亮的 conversation
/// 会改变。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/colors.dart';
import 'profile_tree.dart';
import 'settings_panel.dart';
import 'sidebar_providers.dart';

/// 完整 sidebar widget。
class SidebarScreen extends ConsumerWidget {
  /// 创建 sidebar。
  const SidebarScreen({
    required this.currentConversationId,
    required this.onNavigate,
    this.collapsed = false,
    this.onToggle,
    super.key,
  });

  /// Main area 显示的 conversation id；empty state 时为 `null`。用于高亮 tree 中的 active
  /// conversation。
  final int? currentConversationId;

  /// User 选择 conversation 时调用。Argument 是 `/c/123` 形式的 path。保留为 callback，
  /// 而不是让 sidebar 直接访问 router，使 shell 负责 navigation。
  final void Function(String path) onNavigate;

  /// 是否渲染 narrow screen 和手动折叠 wide sidebar 后使用的 80px icon-only sidebar。
  final bool collapsed;

  /// 在完整 sidebar 和 compact icon-only sidebar 之间 toggle。
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<ParloColors>()!;
    final contentWidth = collapsed ? 56.0 : 248.0;

    // Design “Sidebar”：expanded 时宽 280px，collapsed 时宽 80px；使用 soft-stone fill、
    // 16px padding、三个 section（top / tree / settings row）之间 16px gap，以及 hairline
    // chalk border。
    return AnimatedContainer(
      width: collapsed ? 80 : 280,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOutCubic,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: colors.softStone,
        border: Border(right: BorderSide(color: colors.chalk, width: 1)),
      ),
      padding: collapsed
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 16)
          : const EdgeInsets.all(16),
      child: OverflowBox(
        alignment: Alignment.topLeft,
        minWidth: contentWidth,
        maxWidth: contentWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SidebarHeader(
              collapsed: collapsed,
              onNewProfile: () => _promptForProfileName(context, ref),
              onNewConversation: () => onNavigate('/'),
              onToggle: onToggle,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ProfileTree(
                currentConversationId: currentConversationId,
                onNavigate: onNavigate,
                collapsed: collapsed,
                onExpand: collapsed ? onToggle : null,
              ),
            ),
            const SizedBox(height: 16),
            _SidebarFooter(
              collapsed: collapsed,
              onSettings: () => _openSettingsPanel(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _promptForProfileName(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final name = await _showNameDialog(
      context: context,
      title: 'New folder',
      labelText: 'Folder name',
      initialText: 'New folder',
      confirmText: 'Create',
    );
    if (name == null || name.trim().isEmpty) return;
    // Fire-and-forget；AsyncNotifier state 会反映 refetch。Error 会通过 tree 中的 AsyncValue
    // 暴露。
    await ref.read(profilesProvider.notifier).createProfile(name.trim());
  }

  Future<void> _openSettingsPanel(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => const SettingsPanelDialog(),
    );
  }
}

/// Sidebar 的 top section：brand row（serif wordmark + collapse icon）和两个 full-width
/// action button（“新建对话”和“新建分组”）。
class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({
    required this.collapsed,
    required this.onNewProfile,
    required this.onNewConversation,
    required this.onToggle,
  });

  final bool collapsed;
  final VoidCallback onNewProfile;
  final VoidCallback onNewConversation;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ParloColors>()!;
    if (collapsed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SidebarIconButton(
            icon: const _SidebarToggleIcon(collapsed: true),
            tooltip: '展开侧栏',
            onTap: onToggle,
          ),
          const SizedBox(height: 8),
          _SidebarActionButton(
            icon: Icons.edit_outlined,
            label: '新建对话',
            onTap: onNewConversation,
            collapsed: true,
          ),
          const SizedBox(height: 4),
          _SidebarActionButton(
            icon: Icons.create_new_folder_outlined,
            label: '新建分组',
            onTap: onNewProfile,
            collapsed: true,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Design “Brand Row”：左侧 20px serif wordmark，右侧 18px panel-left-close icon，
        // padding 4px。
        Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Parlo',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: 20,
                    color: colors.carbonInk,
                  ),
                ),
              ),
              if (onToggle != null)
                IconButton(
                  icon: const _SidebarToggleIcon(collapsed: false),
                  color: colors.ashen,
                  tooltip: '收起侧栏',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: onToggle,
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Design “New Actions Row”：两个相距 4px 的 full-width ghost button。
        _SidebarActionButton(
          icon: Icons.edit_outlined,
          label: '新建对话',
          onTap: onNewConversation,
        ),
        const SizedBox(height: 4),
        _SidebarActionButton(
          icon: Icons.create_new_folder_outlined,
          label: '新建分组',
          onTap: onNewProfile,
        ),
      ],
    );
  }
}

/// Sidebar action row（“新建对话”/“新建分组”）和底部 settings row 使用的 full-width ghost button。
///
/// 匹配 design：16px icon + 14px medium label、10px gap、8x10 padding、8px corner radius，
/// 以及 hover 时变亮的透明 fill。
class _SidebarActionButton extends StatefulWidget {
  const _SidebarActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.collapsed = false,
    this.topBorder = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Compact sidebar 中是否只显示 icon。
  final bool collapsed;

  /// 是否绘制 hairline top border（settings row 使用；它位于 sidebar bottom，并由 divider 分隔）。
  final bool topBorder;

  @override
  State<_SidebarActionButton> createState() => _SidebarActionButtonState();
}

class _SidebarActionButtonState extends State<_SidebarActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ParloColors>()!;
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _hovered ? colors.chalk : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: widget.topBorder
            ? Border(top: BorderSide(color: colors.chalk, width: 1))
            : null,
      ),
      child: Row(
        mainAxisAlignment: widget.collapsed
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: [
          Icon(widget.icon, size: 16, color: colors.graphite),
          if (!widget.collapsed) ...[
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.graphite,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: widget.label,
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: child,
        ),
      ),
    );
  }
}

/// Sidebar 的 bottom row：full-width“设置”row，上方带 hairline divider（design 的“Settings Row”）。
class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter({required this.collapsed, required this.onSettings});

  final bool collapsed;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return _SidebarActionButton(
      icon: Icons.settings_outlined,
      label: '设置',
      onTap: onSettings,
      collapsed: collapsed,
      topBorder: true,
    );
  }
}

/// Compact sidebar header 使用的 icon-only button。
class _SidebarIconButton extends StatelessWidget {
  const _SidebarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final Widget icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: icon,
      color: Theme.of(context).extension<ParloColors>()!.ashen,
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 56, minHeight: 36),
      onPressed: onTap,
    );
  }
}

/// 小型 Lucide-style panel-left open/close icon。
class _SidebarToggleIcon extends StatelessWidget {
  const _SidebarToggleIcon({required this.collapsed});

  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size.square(18),
      painter: _SidebarToggleIconPainter(
        color: IconTheme.of(context).color ?? Colors.black,
        collapsed: collapsed,
      ),
    );
  }
}

class _SidebarToggleIconPainter extends CustomPainter {
  const _SidebarToggleIconPainter({
    required this.color,
    required this.collapsed,
  });

  final Color color;
  final bool collapsed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final panel = RRect.fromRectAndRadius(
      Rect.fromLTWH(1.5, 1.5, size.width - 3, size.height - 3),
      const Radius.circular(2),
    );
    canvas.drawRRect(panel, paint);

    canvas.drawLine(Offset(7, 2.5), Offset(7, size.height - 2.5), paint);

    final arrow = Path()
      ..moveTo(collapsed ? 10 : 13, 6)
      ..lineTo(collapsed ? 13 : 10, 9)
      ..lineTo(collapsed ? 10 : 13, 12);
    canvas.drawPath(arrow, paint);
  }

  @override
  bool shouldRepaint(_SidebarToggleIconPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.collapsed != collapsed;
}

/// 请求 user 输入单个 text value 的小型可复用 dialog。
///
/// 返回输入的 text；user dismiss dialog 时返回 `null`。保留在这里是因为 sidebar 用它
/// 创建“new folder”，而 rename 在 tree 中使用 inline editor。
Future<String?> _showNameDialog({
  required BuildContext context,
  required String title,
  required String labelText,
  required String initialText,
  required String confirmText,
}) async {
  final controller = TextEditingController(text: initialText);
  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: labelText),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(null),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: Text(confirmText),
          ),
        ],
      );
    },
  );
}
