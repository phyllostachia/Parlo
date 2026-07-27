/// dio client 使用的 backend base URL 的 mutable holder。
///
/// 每个 platform 都要求 base URL：用户必须告诉应用要通信的 host，且没有 same-origin
/// fallback。Store 会持久化 value，使其在 restart 后保留；dio provider 监听 store，并在
/// value 变化时 rebuild。
///
/// 该 store 与 [AuthStore] 一样使用 [ChangeNotifier]：dio provider 监听 base URL 并在其
/// 变化时 rebuild。Token dialog 和 settings panel 都向此 store 写入。
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// base URL 在 `shared_preferences` 中存储时使用的 key。
const String kBaseUrlKey = 'tan_base_url';

// 兼容改名前已经保存的地址；首次读取后会迁移到新 key。
const String _legacyBaseUrlKey = 'parlo_base_url';

/// backend base URL 的 mutable holder。
///
/// Persistence 在这里接入，因此每次 `write` 和 `clear` 都会让磁盘副本保持同步。Store
/// 从空状态开始；[bootstrap] 会在启动几毫秒后加载已保存的 value。
class BaseUrlStore extends ChangeNotifier {
  /// 创建一个由给定 preferences 支持的 base URL store。
  BaseUrlStore(this._prefs);

  final SharedPreferences _prefs;

  /// 当前 base URL；尚未设置时为空 string。
  ///
  /// 空 string 表示“使用 same-origin relative path”，这在 Web 上是正确的 value。
  String _value = '';

  /// 返回当前 base URL（尚未设置时为空 string）。
  String read() => _value;

  /// 是否已设置非空 base URL。
  bool get hasValue => _value.isNotEmpty;

  /// 将 `shared_preferences` 中保存的 base URL 加载到 memory。
  ///
  /// 在启动时调用一次。如果之前持久化了非空 value，它会成为当前 value，并通知 listener，
  /// 使 dio provider 使用恢复的 host rebuild。
  Future<void> bootstrap() async {
    final saved =
        _prefs.getString(kBaseUrlKey) ?? _prefs.getString(_legacyBaseUrlKey);
    if (saved != null && saved.isNotEmpty) {
      _value = saved;
      if (_prefs.getString(kBaseUrlKey) == null) {
        _prefs.setString(kBaseUrlKey, saved);
      }
      notifyListeners();
    }
  }

  /// 存储新的 base URL。
  ///
  /// value 也会写入 `shared_preferences`，使其在 restart 后保留。空 string 会被视为
  /// “没有 base URL”（same-origin）。
  void write(String value) {
    final normalized = value.trim();
    _value = normalized;
    notifyListeners();
    _prefs.setString(kBaseUrlKey, normalized);
  }

  /// 移除已存储的 base URL。
  void clear() {
    _value = '';
    notifyListeners();
    _prefs.remove(kBaseUrlKey);
    _prefs.remove(_legacyBaseUrlKey);
  }
}
