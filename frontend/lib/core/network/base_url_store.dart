/// The mutable holder for the backend base URL used by the dio client.
///
/// On the web the app is served from the same origin as the API, so the base
/// URL is always an empty string (same-origin relative paths). On mobile the
/// app talks to a user-entered host, so the base URL must be persisted and
/// restored on startup.
///
/// This store is a [ChangeNotifier] for the same reason [AuthStore] is one:
/// the dio provider watches the base URL and rebuilds when it changes. The
/// token dialog writes to this store when the user enters a backend address
/// (only shown on mobile, where `PlatformCapabilities.canInputBackendUrl`
/// is `true`).
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The key under which the base URL is stored in `shared_preferences`.
const String kBaseUrlKey = 'parlo_base_url';

/// The mutable holder for the backend base URL.
///
/// Persistence is wired up here so every `write` and `clear` keeps the
/// on-disk copy in sync. The store starts empty; [bootstrap] loads any
/// saved value a few milliseconds after startup.
class BaseUrlStore extends ChangeNotifier {
  /// Creates a base URL store backed by the given preferences.
  BaseUrlStore(this._prefs);

  final SharedPreferences _prefs;

  /// The current base URL, or an empty string when none has been set.
  ///
  /// An empty string means "use same-origin relative paths", which is the
  /// correct value on the web.
  String _value = '';

  /// Returns the current base URL (empty string when none is set).
  String read() => _value;

  /// Whether a non-empty base URL has been set.
  bool get hasValue => _value.isNotEmpty;

  /// Loads any saved base URL from `shared_preferences` into memory.
  ///
  /// Call this once at startup. If a non-empty value was previously
  /// persisted, it becomes the current value and listeners are notified so
  /// the dio provider can rebuild with the restored host.
  Future<void> bootstrap() async {
    final saved = _prefs.getString(kBaseUrlKey);
    if (saved != null && saved.isNotEmpty) {
      _value = saved;
      notifyListeners();
    }
  }

  /// Stores a new base URL.
  ///
  /// The value is also written to `shared_preferences` so it survives a
  /// restart. An empty string is treated as "no base URL" (same-origin).
  void write(String value) {
    final normalized = value.trim();
    _value = normalized;
    notifyListeners();
    _prefs.setString(kBaseUrlKey, normalized);
  }

  /// Removes the stored base URL.
  void clear() {
    _value = '';
    notifyListeners();
    _prefs.remove(kBaseUrlKey);
  }
}
