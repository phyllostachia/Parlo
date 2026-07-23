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
class SettingsPanelDialog extends ConsumerStatefulWidget {
  /// Creates the dialog.
  const SettingsPanelDialog({super.key});

  @override
  ConsumerState<SettingsPanelDialog> createState() =>
      _SettingsPanelDialogState();
}

class _SettingsPanelDialogState extends ConsumerState<SettingsPanelDialog> {
  late final TextEditingController _tokenController;
  late final TextEditingController _domainController;
  late final TextEditingController _portController;
  bool _obscured = true;

  @override
  void initState() {
    super.initState();
    final baseUrlStore = ref.read(baseUrlStoreProvider);
    final parsed = parseBackendUrl(baseUrlStore.read());
    _tokenController = TextEditingController(
      text: ref.read(authStoreProvider).read() ?? '',
    );
    _domainController = TextEditingController(text: parsed?.domain ?? '');
    _portController = TextEditingController(text: parsed?.port ?? '');
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _domainController.dispose();
    _portController.dispose();
    super.dispose();
  }

  bool get _canSave {
    return _tokenController.text.trim().isNotEmpty &&
        buildBackendUrl(_domainController.text, _portController.text) != null;
  }

  void _save() {
    if (!_canSave) return;

    ref.read(authStoreProvider).write(_tokenController.text.trim());
    ref.read(authStoreProvider).markAuthorized();
    ref
        .read(baseUrlStoreProvider)
        .write(buildBackendUrl(_domainController.text, _portController.text)!);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ParloColors>()!;
    final spacing = Theme.of(context).extension<ParloSpacing>()!;

    return Dialog(
      backgroundColor: colors.paperWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ParloRadius.light.elevatedCard),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 700),
        child: SizedBox(
          key: const ValueKey('settings-modal'),
          width: 720,
          height: 700,
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Settings',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                SizedBox(height: spacing.s24),
                _TokenSection(
                  controller: _tokenController,
                  obscured: _obscured,
                  onToggleObscured: () =>
                      setState(() => _obscured = !_obscured),
                  onChanged: () => setState(() {}),
                ),
                SizedBox(height: spacing.s24),
                _BackendUrlSection(
                  domainController: _domainController,
                  portController: _portController,
                  onChanged: () => setState(() {}),
                ),
                SizedBox(height: spacing.s24),
                const _ThemeSection(),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                    SizedBox(width: spacing.s16),
                    SizedBox(
                      width: 160,
                      height: 52,
                      child: FilledButton(
                        onPressed: _canSave ? _save : null,
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The token field from the settings design.
class _TokenSection extends StatelessWidget {
  const _TokenSection({
    required this.controller,
    required this.obscured,
    required this.onToggleObscured,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool obscured;
  final VoidCallback onToggleObscured;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Token', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: 56,
          child: TextField(
            controller: controller,
            obscureText: obscured,
            onChanged: (_) => onChanged(),
            style: Theme.of(context).textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: 'Paste your token here',
              suffixIcon: IconButton(
                tooltip: obscured ? 'Show token' : 'Hide token',
                icon: Icon(
                  obscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: onToggleObscured,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The backend address fields from the settings design.
class _BackendUrlSection extends StatelessWidget {
  const _BackendUrlSection({
    required this.domainController,
    required this.portController,
    required this.onChanged,
  });

  final TextEditingController domainController;
  final TextEditingController portController;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Backend address',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        BackendUrlField(
          domainController: domainController,
          portController: portController,
          onChanged: onChanged,
          fieldGap: 12,
          portWidth: 140,
        ),
      ],
    );
  }
}

/// The theme section. v1 only supports the light theme; the others are
/// listed but disabled.
///
class _ThemeSection extends StatelessWidget {
  const _ThemeSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Theme', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'v1 supports the light theme. Dark and system-follow arrive in a '
          'later phase.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).extension<ParloColors>()!.ashen,
          ),
        ),
        const SizedBox(height: 8),
        const _ThemeOption(label: 'Light', selected: true),
        const SizedBox(height: 8),
        _ThemeOption(
          label: 'Dark',
          disabled: true,
          disabledColor: Theme.of(context).disabledColor,
        ),
        const SizedBox(height: 8),
        _ThemeOption(
          label: 'Follow system',
          disabled: true,
          disabledColor: Theme.of(context).disabledColor,
        ),
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    this.disabled = false,
    this.disabledColor,
    this.selected = false,
  });

  final String label;
  final bool disabled;
  final Color? disabledColor;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ParloColors>()!;
    final mutedColor = disabledColor ?? colors.pebble;
    final radioColor = disabled ? colors.mist : colors.graphite;

    return SizedBox(
      height: disabled ? 52 : 44,
      child: Row(
        children: [
          Icon(
            selected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            size: 24,
            color: radioColor,
          ),
          const SizedBox(width: 12),
          if (disabled)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: mutedColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Coming soon',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            )
          else
            Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colors.carbonInk,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}
