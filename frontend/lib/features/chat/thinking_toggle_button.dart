/// 深度思考开关按钮。
///
/// 按钮不暴露上游 effort 档位；它只展示并切换会话级的开关状态。Backend 根据该状态选择
/// `thinking_off_effort` 或 `thinking_on_effort`。
library;

import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';

/// 用于新会话和现有会话输入框的深度思考开关。
class ThinkingToggleButton extends StatelessWidget {
  /// 创建深度思考开关。
  const ThinkingToggleButton({
    required this.enabled,
    required this.onPressed,
    this.height = 32,
    super.key,
  });

  /// 当前是否开启深度思考。
  final bool enabled;

  /// 点击按钮时切换状态；为 `null` 时禁用交互。
  final VoidCallback? onPressed;

  /// 与相邻发送按钮保持一致的高度。
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<TanColors>()!;
    final foreground = onPressed == null ? colors.pebble : colors.graphite;

    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: '深度思考',
      toggled: enabled,
      child: Tooltip(
        message: enabled ? '关闭深度思考' : '开启深度思考',
        child: Material(
          color: enabled ? colors.softStone : colors.paperWhite,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onPressed,
            child: Container(
              height: height,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                border: Border.all(
                  color: enabled ? colors.graphite : colors.mist,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.psychology_outlined, size: 13, color: foreground),
                  const SizedBox(width: 6),
                  Text(
                    '深度思考',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: foreground,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
