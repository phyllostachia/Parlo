/// The single source of truth for the bearer token used to talk to the
/// backend.
///
/// The architecture document describes `AuthStore` as a plain class. We make
/// it a [ChangeNotifier] so the go_router can re-evaluate its redirect rule
/// the moment the token changes or a 401 lands. This is a small enhancement
/// over the architecture's plain class — the method signatures and fields are
/// the same; only `notifyListeners` is added so the router and the token
/// dialog can react without polling.
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The key under which the token is stored in `shared_preferences`.
const String kAuthTokenKey = 'parlo_token';

/// The mutable holder for the bearer token and the "is the current token known
/// to be unauthorized?" flag.
///
/// The frontend does not cache business data, but it does persist this token
/// (and, on mobile, the base URL). Persistence is wired up here so every
/// `write` and `clear` keeps the on-disk copy in sync.
class AuthStore extends ChangeNotifier {
  /// Creates an auth store backed by the given preferences.
  ///
  /// The preferences instance is injected (rather than fetched inside) so the
  /// store stays easy to test.
  AuthStore(this._prefs);

  final SharedPreferences _prefs;

  /// The current token, or `null` if none has been set.
  String? _token;

  /// Whether the backend has rejected the current token with a 401 since it
  /// was last written. The router reads this to redirect to the empty state,
  /// and the token dialog reads this to pop itself up.
  bool _isUnauthorized = false;

  /// Returns the current token, or `null` if none is set.
  String? read() => _token;

  /// `true` if a non-empty token has been written.
  bool get hasToken => _token != null && _token!.isNotEmpty;

  /// `true` if the backend has reported the current token as invalid.
  ///
  /// This is reset to `false` whenever a new token is written or the backend
  /// later accepts a request.
  bool get isUnauthorized => _isUnauthorized;

  /// Loads any saved token from `shared_preferences` into memory.
  ///
  /// Call this once at startup. If a non-empty token was previously persisted,
  /// it becomes the current token and listeners are notified so the router can
  /// re-evaluate its redirect.
  Future<void> bootstrap() async {
    final saved = _prefs.getString(kAuthTokenKey);
    if (saved != null && saved.isNotEmpty) {
      _token = saved;
      _isUnauthorized = false;
      notifyListeners();
    }
  }

  /// Stores a new token and clears the unauthorized flag.
  ///
  /// Call this when the user submits the token dialog. The token is also
  /// written to `shared_preferences` so it survives a page reload.
  void write(String token) {
    _token = token;
    _isUnauthorized = false;
    notifyListeners();
    _prefs.setString(kAuthTokenKey, token);
  }

  /// Removes the token entirely.
  ///
  /// Call this when the user clears the token from the settings panel. The
  /// persisted copy is also removed.
  void clear() {
    _token = null;
    _isUnauthorized = false;
    notifyListeners();
    _prefs.remove(kAuthTokenKey);
  }

  /// Flags the current token as rejected by a 401 response.
  ///
  /// The dio interceptor calls this from `onError` when it sees a 401.
  void markUnauthorized() {
    if (_isUnauthorized) return;
    _isUnauthorized = true;
    notifyListeners();
  }

  /// Clears the unauthorized flag, e.g. after a new token is written or a
  /// request succeeds again.
  void markAuthorized() {
    if (!_isUnauthorized) return;
    _isUnauthorized = false;
    notifyListeners();
  }
}
