/// The dedicated token + backend address dialog shown on first use and after a
/// 401.
///
/// Per `product.md` §7.1 the dialog blocks the empty state until the user
/// enters a shared bearer token. It is separate from the settings panel's
/// token section: this dialog is a modal that intercepts the "no token" or
/// "token rejected" state, while the settings panel is for editing an
/// already-working token later.
///
/// The dialog always asks for two things: the shared bearer token and the
/// backend address (domain + port). Both are required — there is no
/// same-origin fallback. The same dialog is used on every platform.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/network/base_url_providers.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import 'backend_url_field.dart';

/// The modal token + backend address dialog. Shown by a host widget that
/// watches the auth store and the base URL store; this widget itself only
/// renders the form and forwards the save.
class TokenDialog extends ConsumerStatefulWidget {
  /// Creates the dialog.
  const TokenDialog({super.key});

  @override
  ConsumerState<TokenDialog> createState() => _TokenDialogState();
}

class _TokenDialogState extends ConsumerState<TokenDialog> {
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _domainController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  bool _obscured = true;

  @override
  void initState() {
    super.initState();
    // Pre-fill the backend address from the store. If the user already saved
    // an address (e.g. they are re-entering a token after a 401) they should
    // not have to type it again.
    final baseUrlStore = ref.read(baseUrlStoreProvider);
    final parsed = parseBackendUrl(baseUrlStore.read());
    if (parsed != null) {
      _domainController.text = parsed.domain;
      _portController.text = parsed.port;
    }
    // Rebuild when the token field changes so the Save button re-evaluates.
    _tokenController.addListener(_handleChanged);
  }

  @override
  void dispose() {
    _tokenController.removeListener(_handleChanged);
    _tokenController.dispose();
    _domainController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _handleChanged() {
    if (!mounted) return;
    setState(() {});
  }

  bool get _canSave {
    final token = _tokenController.text.trim();
    if (token.isEmpty) return false;
    return buildBackendUrl(_domainController.text, _portController.text) != null;
  }

  void _save() {
    if (!_canSave) return;

    final token = _tokenController.text.trim();
    final url = buildBackendUrl(_domainController.text, _portController.text)!;

    // Write the token and clear the unauthorized flag (in case this dialog
    // appeared because of a 401).
    ref.read(authStoreProvider).write(token);
    ref.read(authStoreProvider).markAuthorized();
    ref.read(baseUrlStoreProvider).write(url);

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ParloColors>()!;
    final spacing = Theme.of(context).extension<ParloSpacing>()!;
    final authStore = ref.watch(authStoreProvider);
    final baseUrlStore = ref.watch(baseUrlStoreProvider);
    final isUnauthorized = authStore.isUnauthorized;
    final isFirstUse = !authStore.hasToken;
    final needsAddress = !baseUrlStore.hasValue;

    // The headline and helper text change with the reason the dialog opened.
    // The dialog can appear because the user has no token, the backend rejected
    // the token, or the backend address is missing. The headline picks the
    // most specific reason.
    final String headline;
    final String helper;
    if (isFirstUse) {
      headline = 'Welcome to Parlo';
      helper = 'Enter the shared bearer token and backend address to connect '
          'to your Parlo backend.';
    } else if (isUnauthorized) {
      headline = 'Re-enter your token';
      helper = 'The backend rejected the current token. Enter a valid shared '
          'bearer token to continue.';
    } else if (needsAddress) {
      headline = 'Set your backend address';
      helper = 'No backend address is set. Enter the domain and port of your '
          'Parlo backend to continue.';
    } else {
      headline = 'Re-enter your details';
      helper = 'Enter the shared bearer token and backend address to connect '
          'to your Parlo backend.';
    }

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
            BackendUrlField(
              domainController: _domainController,
              portController: _portController,
              onChanged: () => setState(() {}),
            ),
            SizedBox(height: spacing.s8),
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
          onPressed: _canSave ? _save : null,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
