/// 当 auth store 需要 token 或 base URL store 为空时显示 [TokenDialog] 的 host widget。
///
/// 此 widget 自身不渲染内容；它只监听 auth store 和 base URL store，并在以下情况将
/// [TokenDialog] 作为 modal 打开：
/// - user 尚无 token（first use）；
/// - backend 将当前 token 标记为 401；
/// - user 尚未输入 backend address。
///
/// Dialog 不可 dismiss，因此 user 必须输入两个 value 才能继续。Save 会清除 unauthorized
/// flag 并关闭 dialog；随后 store 通知 listener，host 会重新计算并发现无需再次显示 dialog。
///
/// 将此 widget 放在上方具有 `Navigator` 的 widget tree 中（[AppShell] 满足此条件）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/network/base_url_providers.dart';
import 'token_dialog.dart';

/// 必要时打开 token dialog 的 invisible host。
class TokenDialogHost extends ConsumerStatefulWidget {
  /// 创建 host。
  const TokenDialogHost({super.key});

  @override
  ConsumerState<TokenDialogHost> createState() => _TokenDialogHostState();
}

class _TokenDialogHostState extends ConsumerState<TokenDialogHost> {
  /// Dialog 当前是否打开。记录此状态，避免 listener 在第一个 dialog 上再打开第二个。
  bool _isDialogOpen = false;

  @override
  void initState() {
    super.initState();
    // 在任何 `notifyListeners` 触发前检查 startup。由于 `showDialog` 需要 Navigator，而
    // Navigator 在 `initState` 时还不可用，因此需要 post-frame callback。
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowDialog());
  }

  @override
  Widget build(BuildContext context) {
    // Auth store 或 base URL store 变化时重新计算（token written、token cleared、401 flagged、
    // 401 cleared、base URL written、base URL cleared）。
    ref.listen<ChangeNotifier>(authStoreProvider, (_, _) {
      _maybeShowDialog();
    });
    ref.listen<ChangeNotifier>(baseUrlStoreProvider, (_, _) {
      _maybeShowDialog();
    });
    // Host 不渲染内容；它只触发 dialog。
    return const SizedBox.shrink();
  }

  void _maybeShowDialog() {
    if (!mounted) return;
    final authStore = ref.read(authStoreProvider);
    final baseUrlStore = ref.read(baseUrlStoreProvider);
    final needsInput =
        !authStore.hasToken ||
        authStore.isUnauthorized ||
        !baseUrlStore.hasValue;
    if (!needsInput || _isDialogOpen) return;

    _isDialogOpen = true;
    showDialog<void>(
      context: context,
      // Non-dismissable：user 必须输入两个 value。没有有效 token 或 base URL 时，router 已
      // 将所有 route 强制到 `/`，因此没有可供 dismiss 后返回的有用页面。
      barrierDismissible: false,
      builder: (_) => const TokenDialog(),
    ).then((_) {
      _isDialogOpen = false;
      // Dialog 关闭后重新检查。如果 user 没有 save 就 dismiss（dialog 不可 dismiss，本不应
      // 发生，但 mobile 上 back button 仍可能关闭），则重新打开。
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowDialog());
    });
  }
}
