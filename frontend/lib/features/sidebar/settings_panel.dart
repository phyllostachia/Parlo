/// The settings panel shown when the sidebar gear is tapped.
///
/// Per `product.md` §7.2 the panel only manages three things the frontend can
/// really own: the bearer token, the backend address, and the theme.
/// Everything else lives in the backend `config.yaml`.
///
/// v1 ships only the light theme. The dark and "follow system" options are
/// listed but disabled with a "Coming soon" tag so the panel does not lie
/// about what works today.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/network/base_url_providers.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../settings/backend_url_field.dart';

/// The settings panel shown as a centered dialog.
class SettingsPanelDialog extends ConsumerWidget {
  /// Creates the dialog.
  const SettingsPanelDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<ParloColors>()!;
    final spacing = Theme.of(context).extension<ParloSpacing>()!;

    return Dialog(
      backgroundColor: colors.paperWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ParloRadius.light.elevatedCard),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: EdgeInsets.all(spacing.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Settings', style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: spacing.s24),
              const _TokenSection(),
              SizedBox(height: spacing.s24),
              const _BackendUrlSection(),
              SizedBox(height: spacing.s24),
              const _ThemeSection(),
              SizedBox(height: spacing.s16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The token management section: shows the current token (masked), lets the
/// user edit it, and save or clear.
class _TokenSection extends ConsumerStatefulWidget {
  const _TokenSection();

  @override
  ConsumerState<_TokenSection> createState() => _TokenSectionState();
}

class _TokenSectionState extends ConsumerState<_TokenSection> {
  late final TextEditingController _controller;
  bool _obscured = true;

  @override
  void initState() {
    super.initState();
    final authStore = ref.read(authStoreProvider);
    _controller = TextEditingController(text: authStore.read() ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final token = _controller.text;
    if (token.isEmpty) return;
    ref.read(authStoreProvider).write(token);
    // Clear the unauthorized flag in case the user is re-entering after a 401.
    ref.read(authStoreProvider).markAuthorized();
    Navigator.of(context).maybePop();
  }

  void _clear() {
    _controller.clear();
    ref.read(authStoreProvider).clear();
  }

  @override
  Widget build(BuildContext context) {
    final hasToken = ref.watch(authStoreProvider).hasToken;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Token', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          hasToken
              ? 'A token is set. The backend uses it as a Bearer credential.'
              : 'No token set. The app will prompt for one on first use.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                obscureText: _obscured,
                decoration: InputDecoration(
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
            ),
            const SizedBox(width: 8),
            FilledButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: hasToken ? _clear : null,
            child: const Text('Clear token'),
          ),
        ),
      ],
    );
  }
}

/// The backend address section: shows the current state, lets the user edit
/// the domain and port, and save or clear.
///
/// Clearing the address removes it from the store, which the token dialog
/// host watches — so the token dialog pops up immediately, asking the user to
/// re-enter the address.
class _BackendUrlSection extends ConsumerStatefulWidget {
  const _BackendUrlSection();

  @override
  ConsumerState<_BackendUrlSection> createState() =>
      _BackendUrlSectionState();
}

class _BackendUrlSectionState extends ConsumerState<_BackendUrlSection> {
  late final TextEditingController _domainController;
  late final TextEditingController _portController;

  @override
  void initState() {
    super.initState();
    final baseUrlStore = ref.read(baseUrlStoreProvider);
    final parsed = parseBackendUrl(baseUrlStore.read());
    _domainController = TextEditingController(text: parsed?.domain ?? '');
    _portController = TextEditingController(text: parsed?.port ?? '');
  }

  @override
  void dispose() {
    _domainController.dispose();
    _portController.dispose();
    super.dispose();
  }

  bool get _canSave {
    return buildBackendUrl(_domainController.text, _portController.text) != null;
  }

  void _save() {
    if (!_canSave) return;
    final url = buildBackendUrl(_domainController.text, _portController.text)!;
    ref.read(baseUrlStoreProvider).write(url);
    Navigator.of(context).maybePop();
  }

  void _clear() {
    ref.read(baseUrlStoreProvider).clear();
    _domainController.clear();
    _portController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final hasUrl = ref.watch(baseUrlStoreProvider).hasValue;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Backend address', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          hasUrl
              ? 'An address is set. The app sends every request to this host.'
              : 'No address set. The app will prompt for one on first use.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        BackendUrlField(
          domainController: _domainController,
          portController: _portController,
          onChanged: () => setState(() {}),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            FilledButton(
              onPressed: _canSave ? _save : null,
              child: const Text('Save'),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: hasUrl ? _clear : null,
              child: const Text('Clear address'),
            ),
          ],
        ),
      ],
    );
  }
}

/// The theme section. v1 only supports the light theme; the others are
/// listed but disabled.
///
/// Built with plain [ListTile]s instead of [RadioListTile] because the
/// `groupValue`/`onChanged` API on [RadioListTile] is deprecated in recent
/// Flutter, and we only need to show a single selected option anyway.
class _ThemeSection extends StatelessWidget {
  const _ThemeSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Theme', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'v1 supports the light theme. Dark and system-follow arrive in a '
          'later phase.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        const ListTile(
          leading: Icon(Icons.radio_button_checked, size: 20),
          title: Text('Light'),
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
        ListTile(
          leading: Icon(
            Icons.radio_button_unchecked,
            size: 20,
            color: Theme.of(context).disabledColor,
          ),
          title: Text(
            'Dark',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).disabledColor,
                ),
          ),
          subtitle: const Text('Coming soon'),
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
        ListTile(
          leading: Icon(
            Icons.radio_button_unchecked,
            size: 20,
            color: Theme.of(context).disabledColor,
          ),
          title: Text(
            'Follow system',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).disabledColor,
                ),
          ),
          subtitle: const Text('Coming soon'),
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
      ],
    );
  }
}
