/// A small, reusable error banner with an optional retry button.
///
/// Phase 6 standardizes the app's error states so every `AsyncError` renders
/// the same way: a one-line message, the error detail, and a "Retry" button
/// that the caller wires to `ref.invalidate(provider)`.
library;

import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';

/// A centered error block with an optional retry action.
class ErrorBanner extends StatelessWidget {
  /// Creates the banner.
  const ErrorBanner({
    required this.message,
    this.error,
    this.onRetry,
    super.key,
  });

  /// The headline message, e.g. "Could not load the conversation."
  final String message;

  /// The error detail to show under the headline, or `null` to hide it.
  final Object? error;

  /// Called when the user taps "Retry". When `null`, the retry button is
  /// hidden (used when there is nothing to retry, only to inform).
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ParloColors>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: colors.ashen,
              size: 32,
            ),
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
