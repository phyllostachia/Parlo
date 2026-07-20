/// Riverpod providers that expose the [BaseUrlStore] and connect it to the
/// [baseUrlProvider] consumed by the dio client.
///
/// `baseUrlStoreProvider` is a [ChangeNotifierProvider] so the dio provider
/// rebuilds automatically when the base URL changes. The `baseUrlProvider`
/// (kept in `api_client.dart` for backwards compatibility) watches this
/// store and returns its current value.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import 'base_url_store.dart';

/// The single [BaseUrlStore] for the whole app.
///
/// Watches [sharedPreferencesProvider] so the store has a place to persist
/// the base URL. The store is created once and reused for the app's
/// lifetime. `bootstrap()` loads any saved value asynchronously.
final baseUrlStoreProvider = ChangeNotifierProvider<BaseUrlStore>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final store = BaseUrlStore(prefs);
  // Load any saved base URL. This is fire-and-forget: the store starts empty
  // and notifies listeners when the saved value arrives a few milliseconds
  // later.
  store.bootstrap();
  return store;
});
