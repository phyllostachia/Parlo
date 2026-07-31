/// User 点击 sidebar gear 时显示的 settings panel。
///
/// 根据 `product.md` §7.2，此 panel 只管理 frontend 真正拥有的三项内容：bearer token、
/// backend address 和 theme。其他内容都位于 backend `config.yaml` 中。
///
/// v1 只提供 light theme。Dark 和“follow system”option 会列出但禁用，并标记“Coming soon”，
/// 使 panel 不会虚假表示当前可用功能。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/network/base_url_providers.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../settings/backend_url_field.dart';

/// 以居中 dialog 显示的 settings panel。
class SettingsPanelDialog extends ConsumerStatefulWidget {
  /// 创建 dialog。
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
    final colors = Theme.of(context).extension<TanColors>()!;
    final spacing = Theme.of(context).extension<TanSpacing>()!;

    return Dialog(
      backgroundColor: colors.paperWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TanRadius.light.elevatedCard),
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
                Text('设置', style: Theme.of(context).textTheme.displayLarge),
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
                      child: const Text('关闭'),
                    ),
                    SizedBox(width: spacing.s16),
                    SizedBox(
                      width: 160,
                      height: 52,
                      child: FilledButton(
                        onPressed: _canSave ? _save : null,
                        child: const Text('保存'),
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

/// Settings design 中的 token field。
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
        Text('令牌', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: 56,
          child: TextField(
            controller: controller,
            obscureText: obscured,
            onChanged: (_) => onChanged(),
            style: Theme.of(context).textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: '在此粘贴令牌',
              suffixIcon: IconButton(
                tooltip: obscured ? '显示令牌' : '隐藏令牌',
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

/// Settings design 中的 backend address field。
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
        Text('后端地址', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        BackendUrlField(
          domainController: domainController,
          portController: portController,
          onChanged: onChanged,
          fieldGap: 12,
          portWidth: 140,
          domainLabel: '后端域名',
          portLabel: '端口',
          numbersOnlyError: '只能输入数字',
        ),
      ],
    );
  }
}

/// Theme section。v1 只支持 light theme；其他 option 会列出但禁用。
///
class _ThemeSection extends StatelessWidget {
  const _ThemeSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('主题', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          '当前版本仅支持浅色主题。深色主题和跟随系统将在后续版本提供。',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).extension<TanColors>()!.ashen,
          ),
        ),
        const SizedBox(height: 8),
        const _ThemeOption(label: '浅色', selected: true),
        const SizedBox(height: 8),
        _ThemeOption(
          label: '深色',
          disabled: true,
          disabledColor: Theme.of(context).disabledColor,
        ),
        const SizedBox(height: 8),
        _ThemeOption(
          label: '跟随系统',
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
    final colors = Theme.of(context).extension<TanColors>()!;
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
                Text('即将推出', style: Theme.of(context).textTheme.bodyMedium),
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
