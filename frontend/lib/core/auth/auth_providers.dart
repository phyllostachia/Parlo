/// Riverpod providers that expose the [AuthStore] and the persisted
/// `SharedPreferences` to the rest of the app.
///
/// `sharedPreferencesProvider` is overridden in `main.dart` with the real
/// instance so the rest of the app can read it synchronously. `authStoreProvider`
/// is a [ChangeNotifierProvider] so the go_router and the token dialog rebuild
/// automatically when the token changes.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_store.dart';

/// The application's `shared_preferences` instance.
///
/// This is overridden in `main.dart` with the instance obtained from
/// `SharedPreferences.getInstance()` so the rest of the app can read it
/// synchronously. The bearer token and the base URL are both stored here.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  // The default factory throws so a missing override is caught early instead
  // of silently producing null values deep in the app.
  throw StateError(
    'sharedPreferencesProvider must be overridden in main() with the '
    'instance from SharedPreferences.getInstance()',
  );
});

/// The single [AuthStore] for the whole app.
///
/// Watches [sharedPreferencesProvider] so the store has a place to persist the
/// token. The store is created once and reused for the app's lifetime.
final authStoreProvider = ChangeNotifierProvider<AuthStore>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final store = AuthStore(prefs);
  // Load any saved token. This is fire-and-forget: the store starts empty and
  // notifies listeners when the saved token arrives a few milliseconds later.
  store.bootstrap();
  return store;
});
