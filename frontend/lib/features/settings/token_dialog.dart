/// The dedicated token dialog shown on first use and after a 401.
///
/// Per `product.md` §7.1 the dialog blocks the empty state until the user
/// enters a shared bearer token. It is separate from the settings panel's
/// token section: this dialog is a modal that intercepts the "no token" or
/// "token rejected" state, while the settings panel is for editing an
/// already-working token later.
///
/// On the web the dialog only asks for the token (the API is same-origin). On
/// mobile, where `PlatformCapabilities.canInputBackendUrl` is `true`, the
/// dialog also asks for the backend address, because the app needs to know
/// which host to talk to.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/network/base_url_providers.dart';
import '../../core/platform/platform_providers.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';

/// The modal token dialog. Shown by a host widget that watches the auth
/// store; this widget itself only renders the form and forwards the save.
class TokenDialog extends ConsumerStatefulWidget {
  /// Creates the dialog.
  const TokenDialog({super.key});

  @override
  ConsumerState<TokenDialog> createState() => _TokenDialogState();
}

class _TokenDialogState extends ConsumerState<TokenDialog> {
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _baseUrlController = TextEditingController();
  bool _obscured = true;

  @override
  void dispose() {
    _tokenController.dispose();
    _baseUrlController.dispose();
    super.dispose();
  }

  void _save() {
    final token = _tokenController.text.trim();
    if (token.isEmpty) return;

    // Write the token and clear the unauthorized flag (in case this dialog
    // appeared because of a 401).
    ref.read(authStoreProvider).write(token);
    ref.read(authStoreProvider).markAuthorized();

    // On mobile, persist the base URL when the user entered one.
    final capabilities = ref.read(platformCapabilitiesProvider);
    if (capabilities.canInputBackendUrl) {
      ref.read(baseUrlStoreProvider).write(_baseUrlController.text);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ParloColors>()!;
    final spacing = Theme.of(context).extension<ParloSpacing>()!;
    final authStore = ref.watch(authStoreProvider);
    final capabilities = ref.read(platformCapabilitiesProvider);
    final isUnauthorized = authStore.isUnauthorized;
    final isFirstUse = !authStore.hasToken;

    // The headline and helper text change with the reason the dialog opened.
    final headline = isFirstUse ? 'Welcome to Parlo' : 'Re-enter your token';
    final helper = isUnauthorized
        ? 'The backend rejected the current token. Enter a valid shared '
            'bearer token to continue.'
        : 'Enter the shared bearer token to connect to your Parlo backend.';

    return AlertDialog(
      backgroundColor: colors.paperWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ParloRadius.light.elevatedCard),
      ),
      title: Text(headline),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(helper, style: Theme.of(context).textTheme.bodyMedium),
            SizedBox(height: spacing.s16),
            if (capabilities.canInputBackendUrl) ...[
              TextField(
                controller: _baseUrlController,
                decoration: const InputDecoration(
                  labelText: 'Backend URL',
                  hintText: 'https://parlo.example.com',
                ),
                keyboardType: TextInputType.url,
                autocorrect: false,
              ),
              SizedBox(height: spacing.s8),
            ],
            TextField(
              controller: _tokenController,
              obscureText: _obscured,
              decoration: InputDecoration(
                labelText: 'Bearer token',
                hintText: 'Paste your token here',
                suffixIcon: IconButton(
                  tooltip: _obscured ? 'Show' : 'Hide',
                  icon: Icon(
                    _obscured
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _obscured = !_obscured),
                ),
              ),
              onSubmitted: (_) => _save(),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
