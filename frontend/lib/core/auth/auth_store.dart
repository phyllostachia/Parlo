/// 与 backend 通信所用 bearer token 的 single source of truth。
///
/// 架构文档将 `AuthStore` 描述为 plain class。这里让它成为 [ChangeNotifier]，使 go_router
/// 可以在 token 变化或收到 401 时立即重新计算 redirect rule。这是对架构中 plain class
/// 的小幅增强：method signature 和 field 保持不变，只增加 `notifyListeners`，使 router
/// 和 token dialog 无需 polling 即可响应。
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// token 在 `shared_preferences` 中存储时使用的 key。
const String kAuthTokenKey = 'tan_token';

// 兼容改名前已经保存的 token；首次读取后会迁移到新 key。
const String _legacyAuthTokenKey = 'parlo_token';

/// bearer token 和“当前 token 是否已知未授权” flag 的 mutable holder。
///
/// 前端不缓存业务数据，但会持久化此 token（mobile 上还包括 base URL）。Persistence 在
/// 这里接入，因此每次 `write` 和 `clear` 都会让磁盘副本保持同步。
class AuthStore extends ChangeNotifier {
  /// 创建一个由给定 preferences 支持的 auth store。
  ///
  /// 注入 preferences instance，而不是在内部获取，使 store 易于测试。
  AuthStore(this._prefs);

  final SharedPreferences _prefs;

  /// 当前 token；尚未设置时为 `null`。
  String? _token;

  /// Backend 是否在 token 最近一次写入后以 401 拒绝过它。Router 读取它并 redirect 到
  /// empty state，token dialog 读取它并弹出自身。
  bool _isUnauthorized = false;

  /// 返回当前 token；尚未设置时为 `null`。
  String? read() => _token;

  /// 如果已经写入非空 token，则为 `true`。
  bool get hasToken => _token != null && _token!.isNotEmpty;

  /// 如果 backend 已报告当前 token 无效，则为 `true`。
  ///
  /// 每次写入新 token 或 backend 随后接受 request 时，它都会重置为 `false`。
  bool get isUnauthorized => _isUnauthorized;

  /// 将 `shared_preferences` 中保存的 token 加载到 memory。
  ///
  /// 在启动时调用一次。如果之前持久化了非空 token，它会成为当前 token，并通知 listener，
  /// 使 router 重新计算 redirect。
  Future<void> bootstrap() async {
    final saved =
        _prefs.getString(kAuthTokenKey) ??
        _prefs.getString(_legacyAuthTokenKey);
    if (saved != null && saved.isNotEmpty) {
      _token = saved;
      _isUnauthorized = false;
      if (_prefs.getString(kAuthTokenKey) == null) {
        _prefs.setString(kAuthTokenKey, saved);
      }
      notifyListeners();
    }
  }

  /// 存储新 token 并清除 unauthorized flag。
  ///
  /// 用户提交 token dialog 时调用。Token 也会写入 `shared_preferences`，因此页面 reload
  /// 后仍然存在。
  void write(String token) {
    _token = token;
    _isUnauthorized = false;
    notifyListeners();
    _prefs.setString(kAuthTokenKey, token);
  }

  /// 完全移除 token。
  ///
  /// 用户从 settings panel 清除 token 时调用。持久化副本也会被移除。
  void clear() {
    _token = null;
    _isUnauthorized = false;
    notifyListeners();
    _prefs.remove(kAuthTokenKey);
    _prefs.remove(_legacyAuthTokenKey);
  }

  /// 将当前 token 标记为被 401 response 拒绝。
  ///
  /// dio interceptor 在 `onError` 中发现 401 时调用此方法。
  void markUnauthorized() {
    if (_isUnauthorized) return;
    _isUnauthorized = true;
    notifyListeners();
  }

  /// 清除 unauthorized flag，例如写入新 token 或 request 再次成功之后。
  void markAuthorized() {
    if (!_isUnauthorized) return;
    _isUnauthorized = false;
    notifyListeners();
  }
}
