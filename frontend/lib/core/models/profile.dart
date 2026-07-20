/// The `Profile` data model.
///
/// A profile is a named group of conversations — the top-level folder shown in
/// the sidebar. The backend owns the data; the frontend never caches it. This
/// file is generated together with `profile.freezed.dart` (value class) and
/// `profile.g.dart` (JSON conversion) by `build_runner`.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile.freezed.dart';
part 'profile.g.dart';

/// A named group of conversations shown as a folder in the sidebar.
///
/// The fields mirror the backend `ProfileRead` schema exactly, so the same
/// class works as both the wire DTO and the in-memory model. There is no
/// separate mapping layer.
@freezed
class Profile with _$Profile {
  /// Creates a profile.
  const factory Profile({
    /// The server-assigned identifier, used in URL paths and CRUD calls.
    required int id,

    /// The human-readable folder name shown in the sidebar.
    required String name,

    /// When the profile was first created.
    required DateTime createdAt,

    /// When the profile was last renamed or had a conversation added.
    /// The sidebar sorts by this field, newest first.
    required DateTime updatedAt,
  }) = _Profile;

  /// Rebuilds a profile from the JSON returned by `GET /api/profiles`.
  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);
}
