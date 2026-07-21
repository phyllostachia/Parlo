/// A host widget that shows the [TokenDialog] whenever the auth store needs
/// a token or the base URL store is empty.
///
/// This widget renders nothing itself; it only listens to the auth store and
/// the base URL store and opens the [TokenDialog] as a modal when:
/// - the user has no token yet (first use), or
/// - the backend has flagged the current token as a 401, or
/// - the user has not entered a backend address yet.
///
/// The dialog is non-dismissable, so the user must enter both values to
/// proceed. Saving clears the unauthorized flag and closes the dialog; the
/// stores then notify listeners, which would re-evaluate this host and find
/// no reason to show the dialog again.
///
/// Place this widget anywhere inside a widget tree that has a `Navigator`
/// above it (the [AppShell] satisfies this).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/network/base_url_providers.dart';
import 'token_dialog.dart';

/// The invisible host that opens the token dialog when needed.
class TokenDialogHost extends ConsumerStatefulWidget {
  /// Creates the host.
  const TokenDialogHost({super.key});

  @override
  ConsumerState<TokenDialogHost> createState() => _TokenDialogHostState();
}

class _TokenDialogHostState extends ConsumerState<TokenDialogHost> {
  /// Whether the dialog is currently open. Tracked so the listener does not
  /// open a second dialog on top of the first.
  bool _isDialogOpen = false;

  @override
  void initState() {
    super.initState();
    // Check on startup, before any `notifyListeners` has fired. A post-frame
    // callback is needed because `showDialog` requires a `Navigator` that is
    // not yet available during `initState`.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowDialog());
  }

  @override
  Widget build(BuildContext context) {
    // Re-evaluate whenever the auth store or the base URL store changes
    // (token written, token cleared, 401 flagged, 401 cleared, base URL
    // written, base URL cleared).
    ref.listen<ChangeNotifier>(authStoreProvider, (_, _) {
      _maybeShowDialog();
    });
    ref.listen<ChangeNotifier>(baseUrlStoreProvider, (_, _) {
      _maybeShowDialog();
    });
    // The host renders nothing; it only triggers the dialog.
    return const SizedBox.shrink();
  }

  void _maybeShowDialog() {
    if (!mounted) return;
    final authStore = ref.read(authStoreProvider);
    final baseUrlStore = ref.read(baseUrlStoreProvider);
    final needsInput = !authStore.hasToken
        || authStore.isUnauthorized
        || !baseUrlStore.hasValue;
    if (!needsInput || _isDialogOpen) return;

    _isDialogOpen = true;
    showDialog<void>(
      context: context,
      // Non-dismissable: the user must enter both values. The router already
      // forces every route to `/` while there is no valid token or base URL,
      // so there is nothing useful to dismiss to.
      barrierDismissible: false,
      builder: (_) => const TokenDialog(),
    ).then((_) {
      _isDialogOpen = false;
      // Re-check after the dialog closes. If the user dismissed without
      // saving (should not happen since the dialog is non-dismissable, but
      // a back button could still close it on mobile), reopen it.
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowDialog());
    });
  }
}
