/// 首次使用和 401 后显示的专用 token + backend address dialog。
///
/// 根据 `product.md` §7.1，此 dialog 会阻塞 empty state，直到 user 输入 shared bearer token。
/// 它与 settings panel 的 token section 分离：此 dialog 是拦截“no token”或“token rejected”
/// state 的 modal，而 settings panel 用于之后编辑已经可用的 token。
///
/// Dialog 始终要求两项内容：shared bearer token 和 backend address（domain + port）。二者
/// 都是 required，不存在 same-origin fallback。所有 platform 使用同一个 dialog。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/network/base_url_providers.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import 'backend_url_field.dart';

/// Modal token + backend address dialog。由监听 auth store 和 base URL store 的 host widget
/// 显示；此 widget 自身只渲染 form 并转发 save。
class TokenDialog extends ConsumerStatefulWidget {
  /// 创建 dialog。
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
    // 从 store 预填 backend address。如果 user 已经保存过 address（例如 401 后重新输入
    // token），则不需要再次输入。
    final baseUrlStore = ref.read(baseUrlStoreProvider);
    final parsed = parseBackendUrl(baseUrlStore.read());
    if (parsed != null) {
      _domainController.text = parsed.domain;
      _portController.text = parsed.port;
    }
    // Token field 变化时 rebuild，使 Save button 重新计算。
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
    return buildBackendUrl(_domainController.text, _portController.text) !=
        null;
  }

  void _save() {
    if (!_canSave) return;

    final token = _tokenController.text.trim();
    final url = buildBackendUrl(_domainController.text, _portController.text)!;

    // 写入 token 并清除 unauthorized flag（以防 dialog 因 401 而出现）。
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

    // Headline 和 helper text 会随 dialog 打开原因变化。Dialog 可能因为 user 没有 token、
    // backend 拒绝 token 或缺少 backend address 而出现。Headline 选择最具体的原因。
    final String headline;
    final String helper;
    if (isFirstUse) {
      headline = 'Welcome to Parlo';
      helper =
          'Enter the shared bearer token and backend address to connect '
          'to your Parlo backend.';
    } else if (isUnauthorized) {
      headline = 'Re-enter your token';
      helper =
          'The backend rejected the current token. Enter a valid shared '
          'bearer token to continue.';
    } else if (needsAddress) {
      headline = 'Set your backend address';
      helper =
          'No backend address is set. Enter the domain and port of your '
          'Parlo backend to continue.';
    } else {
      headline = 'Re-enter your details';
      helper =
          'Enter the shared bearer token and backend address to connect '
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
