/// 可复用的小型 error banner，可选带有 retry button。
///
/// 阶段 6 统一应用的 error state，使每个 `AsyncError` 都以相同方式渲染：一行 message、
/// error detail，以及由调用方连接到 `ref.invalidate(provider)` 的“Retry” button。
library;

import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';

/// 居中的 error block，可选带有 retry action。
class ErrorBanner extends StatelessWidget {
  /// 创建 banner。
  const ErrorBanner({
    required this.message,
    this.error,
    this.onRetry,
    super.key,
  });

  /// 标题 message，例如“Could not load the conversation.”。
  final String message;

  /// 显示在 headline 下方的 error detail；为 `null` 时隐藏。
  final Object? error;

  /// 用户点击“Retry”时调用。为 `null` 时隐藏 retry button（用于没有可 retry 内容、仅需
  /// 告知用户的场景）。
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<TanColors>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: colors.ashen, size: 32),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                '$error',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
