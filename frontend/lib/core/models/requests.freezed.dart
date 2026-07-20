// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'requests.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

UserMessageCreate _$UserMessageCreateFromJson(Map<String, dynamic> json) {
  return _UserMessageCreate.fromJson(json);
}

/// @nodoc
mixin _$UserMessageCreate {
  /// The parent message id. `null` means "use the conversation's current
  /// leaf".
  int? get parentId => throw _privateConstructorUsedError;

  /// The user's text. Required even if an image is attached.
  String get text => throw _privateConstructorUsedError;

  /// An optional base64 data URL for an attached image. The frontend builds
  /// this from the picked/pasted/dropped file before sending.
  String? get imageData => throw _privateConstructorUsedError;

  /// Serializes this UserMessageCreate to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserMessageCreate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserMessageCreateCopyWith<UserMessageCreate> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserMessageCreateCopyWith<$Res> {
  factory $UserMessageCreateCopyWith(
    UserMessageCreate value,
    $Res Function(UserMessageCreate) then,
  ) = _$UserMessageCreateCopyWithImpl<$Res, UserMessageCreate>;
  @useResult
  $Res call({int? parentId, String text, String? imageData});
}

/// @nodoc
class _$UserMessageCreateCopyWithImpl<$Res, $Val extends UserMessageCreate>
    implements $UserMessageCreateCopyWith<$Res> {
  _$UserMessageCreateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserMessageCreate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? parentId = freezed,
    Object? text = null,
    Object? imageData = freezed,
  }) {
    return _then(
      _value.copyWith(
            parentId: freezed == parentId
                ? _value.parentId
                : parentId // ignore: cast_nullable_to_non_nullable
                      as int?,
            text: null == text
                ? _value.text
                : text // ignore: cast_nullable_to_non_nullable
                      as String,
            imageData: freezed == imageData
                ? _value.imageData
                : imageData // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UserMessageCreateImplCopyWith<$Res>
    implements $UserMessageCreateCopyWith<$Res> {
  factory _$$UserMessageCreateImplCopyWith(
    _$UserMessageCreateImpl value,
    $Res Function(_$UserMessageCreateImpl) then,
  ) = __$$UserMessageCreateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int? parentId, String text, String? imageData});
}

/// @nodoc
class __$$UserMessageCreateImplCopyWithImpl<$Res>
    extends _$UserMessageCreateCopyWithImpl<$Res, _$UserMessageCreateImpl>
    implements _$$UserMessageCreateImplCopyWith<$Res> {
  __$$UserMessageCreateImplCopyWithImpl(
    _$UserMessageCreateImpl _value,
    $Res Function(_$UserMessageCreateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UserMessageCreate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? parentId = freezed,
    Object? text = null,
    Object? imageData = freezed,
  }) {
    return _then(
      _$UserMessageCreateImpl(
        parentId: freezed == parentId
            ? _value.parentId
            : parentId // ignore: cast_nullable_to_non_nullable
                  as int?,
        text: null == text
            ? _value.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String,
        imageData: freezed == imageData
            ? _value.imageData
            : imageData // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UserMessageCreateImpl implements _UserMessageCreate {
  const _$UserMessageCreateImpl({
    this.parentId,
    required this.text,
    this.imageData,
  });

  factory _$UserMessageCreateImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserMessageCreateImplFromJson(json);

  /// The parent message id. `null` means "use the conversation's current
  /// leaf".
  @override
  final int? parentId;

  /// The user's text. Required even if an image is attached.
  @override
  final String text;

  /// An optional base64 data URL for an attached image. The frontend builds
  /// this from the picked/pasted/dropped file before sending.
  @override
  final String? imageData;

  @override
  String toString() {
    return 'UserMessageCreate(parentId: $parentId, text: $text, imageData: $imageData)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserMessageCreateImpl &&
            (identical(other.parentId, parentId) ||
                other.parentId == parentId) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.imageData, imageData) ||
                other.imageData == imageData));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, parentId, text, imageData);

  /// Create a copy of UserMessageCreate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserMessageCreateImplCopyWith<_$UserMessageCreateImpl> get copyWith =>
      __$$UserMessageCreateImplCopyWithImpl<_$UserMessageCreateImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$UserMessageCreateImplToJson(this);
  }
}

abstract class _UserMessageCreate implements UserMessageCreate {
  const factory _UserMessageCreate({
    final int? parentId,
    required final String text,
    final String? imageData,
  }) = _$UserMessageCreateImpl;

  factory _UserMessageCreate.fromJson(Map<String, dynamic> json) =
      _$UserMessageCreateImpl.fromJson;

  /// The parent message id. `null` means "use the conversation's current
  /// leaf".
  @override
  int? get parentId;

  /// The user's text. Required even if an image is attached.
  @override
  String get text;

  /// An optional base64 data URL for an attached image. The frontend builds
  /// this from the picked/pasted/dropped file before sending.
  @override
  String? get imageData;

  /// Create a copy of UserMessageCreate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserMessageCreateImplCopyWith<_$UserMessageCreateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
