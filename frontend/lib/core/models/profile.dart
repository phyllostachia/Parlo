/// `Profile` data model。
///
/// Profile 是一组有名称的 conversation，即 sidebar 中显示的顶层 folder。Backend 负责
/// 管理 data；frontend 从不缓存它。此 file 会由 `build_runner` 与 `profile.freezed.dart`
///（value class）和 `profile.g.dart`（JSON conversion）一起生成。
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile.freezed.dart';
part 'profile.g.dart';

/// Sidebar 中以 folder 形式显示的一组有名称的 conversation。
///
/// Field 与 backend `ProfileRead` schema 完全对应，因此同一个 class 同时作为 wire DTO 和
/// in-memory model 使用，不需要单独的 mapping layer。
@freezed
class Profile with _$Profile {
  /// 创建 profile。
  const factory Profile({
    /// Server 分配的 identifier，用于 URL path 和 CRUD call。
    required int id,

    /// Sidebar 中显示的可读 folder name。
    required String name,

    /// Profile 首次创建时间。
    required DateTime createdAt,

    /// Profile 最近一次重命名或添加 conversation 的时间。Sidebar 按此 field 从新到旧排序。
    required DateTime updatedAt,
  }) = _Profile;

  /// 根据 `GET /api/profiles` 返回的 JSON 重建 profile。
  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);
}
