// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'conversation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Conversation _$ConversationFromJson(Map<String, dynamic> json) {
  return _Conversation.fromJson(json);
}

/// @nodoc
mixin _$Conversation {
  /// Server 分配的 identifier，用于 `/c/{id}` URL。
  int get id => throw _privateConstructorUsedError;

  /// 此 conversation 所属的 profile。
  int get profileId => throw _privateConstructorUsedError;

  /// 可读的 title。发送第一条 message 前为空。
  String get title => throw _privateConstructorUsedError;

  /// `config.yaml` 中的 model id。创建时固定；如需使用其他 model，请创建新 conversation。
  String get modelId => throw _privateConstructorUsedError;

  /// 此 conversation 是否启用深度思考。上游 effort 由 backend 的 model 配置解析。
  bool get thinkingEnabled => throw _privateConstructorUsedError;

  /// 可见 path 上最后一条 message 的 id；conversation 尚无 message 时为 `null`。
  int? get currentLeafId => throw _privateConstructorUsedError;

  /// Conversation 创建时间。
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Conversation 最近更新时间。用于 sidebar sorting。
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Conversation to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Conversation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ConversationCopyWith<Conversation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConversationCopyWith<$Res> {
  factory $ConversationCopyWith(
    Conversation value,
    $Res Function(Conversation) then,
  ) = _$ConversationCopyWithImpl<$Res, Conversation>;
  @useResult
  $Res call({
    int id,
    int profileId,
    String title,
    String modelId,
    bool thinkingEnabled,
    int? currentLeafId,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class _$ConversationCopyWithImpl<$Res, $Val extends Conversation>
    implements $ConversationCopyWith<$Res> {
  _$ConversationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Conversation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? profileId = null,
    Object? title = null,
    Object? modelId = null,
    Object? thinkingEnabled = null,
    Object? currentLeafId = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            profileId: null == profileId
                ? _value.profileId
                : profileId // ignore: cast_nullable_to_non_nullable
                      as int,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            modelId: null == modelId
                ? _value.modelId
                : modelId // ignore: cast_nullable_to_non_nullable
                      as String,
            thinkingEnabled: null == thinkingEnabled
                ? _value.thinkingEnabled
                : thinkingEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            currentLeafId: freezed == currentLeafId
                ? _value.currentLeafId
                : currentLeafId // ignore: cast_nullable_to_non_nullable
                      as int?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ConversationImplCopyWith<$Res>
    implements $ConversationCopyWith<$Res> {
  factory _$$ConversationImplCopyWith(
    _$ConversationImpl value,
    $Res Function(_$ConversationImpl) then,
  ) = __$$ConversationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    int profileId,
    String title,
    String modelId,
    bool thinkingEnabled,
    int? currentLeafId,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class __$$ConversationImplCopyWithImpl<$Res>
    extends _$ConversationCopyWithImpl<$Res, _$ConversationImpl>
    implements _$$ConversationImplCopyWith<$Res> {
  __$$ConversationImplCopyWithImpl(
    _$ConversationImpl _value,
    $Res Function(_$ConversationImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Conversation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? profileId = null,
    Object? title = null,
    Object? modelId = null,
    Object? thinkingEnabled = null,
    Object? currentLeafId = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$ConversationImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        profileId: null == profileId
            ? _value.profileId
            : profileId // ignore: cast_nullable_to_non_nullable
                  as int,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        modelId: null == modelId
            ? _value.modelId
            : modelId // ignore: cast_nullable_to_non_nullable
                  as String,
        thinkingEnabled: null == thinkingEnabled
            ? _value.thinkingEnabled
            : thinkingEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        currentLeafId: freezed == currentLeafId
            ? _value.currentLeafId
            : currentLeafId // ignore: cast_nullable_to_non_nullable
                  as int?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ConversationImpl implements _Conversation {
  const _$ConversationImpl({
    required this.id,
    required this.profileId,
    required this.title,
    required this.modelId,
    required this.thinkingEnabled,
    required this.currentLeafId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory _$ConversationImpl.fromJson(Map<String, dynamic> json) =>
      _$$ConversationImplFromJson(json);

  /// Server 分配的 identifier，用于 `/c/{id}` URL。
  @override
  final int id;

  /// 此 conversation 所属的 profile。
  @override
  final int profileId;

  /// 可读的 title。发送第一条 message 前为空。
  @override
  final String title;

  /// `config.yaml` 中的 model id。创建时固定；如需使用其他 model，请创建新 conversation。
  @override
  final String modelId;

  /// 此 conversation 是否启用深度思考。上游 effort 由 backend 的 model 配置解析。
  @override
  final bool thinkingEnabled;

  /// 可见 path 上最后一条 message 的 id；conversation 尚无 message 时为 `null`。
  @override
  final int? currentLeafId;

  /// Conversation 创建时间。
  @override
  final DateTime createdAt;

  /// Conversation 最近更新时间。用于 sidebar sorting。
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'Conversation(id: $id, profileId: $profileId, title: $title, modelId: $modelId, thinkingEnabled: $thinkingEnabled, currentLeafId: $currentLeafId, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConversationImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.profileId, profileId) ||
                other.profileId == profileId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.modelId, modelId) || other.modelId == modelId) &&
            (identical(other.thinkingEnabled, thinkingEnabled) ||
                other.thinkingEnabled == thinkingEnabled) &&
            (identical(other.currentLeafId, currentLeafId) ||
                other.currentLeafId == currentLeafId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    profileId,
    title,
    modelId,
    thinkingEnabled,
    currentLeafId,
    createdAt,
    updatedAt,
  );

  /// Create a copy of Conversation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ConversationImplCopyWith<_$ConversationImpl> get copyWith =>
      __$$ConversationImplCopyWithImpl<_$ConversationImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ConversationImplToJson(this);
  }
}

abstract class _Conversation implements Conversation {
  const factory _Conversation({
    required final int id,
    required final int profileId,
    required final String title,
    required final String modelId,
    required final bool thinkingEnabled,
    required final int? currentLeafId,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _$ConversationImpl;

  factory _Conversation.fromJson(Map<String, dynamic> json) =
      _$ConversationImpl.fromJson;

  /// Server 分配的 identifier，用于 `/c/{id}` URL。
  @override
  int get id;

  /// 此 conversation 所属的 profile。
  @override
  int get profileId;

  /// 可读的 title。发送第一条 message 前为空。
  @override
  String get title;

  /// `config.yaml` 中的 model id。创建时固定；如需使用其他 model，请创建新 conversation。
  @override
  String get modelId;

  /// 此 conversation 是否启用深度思考。上游 effort 由 backend 的 model 配置解析。
  @override
  bool get thinkingEnabled;

  /// 可见 path 上最后一条 message 的 id；conversation 尚无 message 时为 `null`。
  @override
  int? get currentLeafId;

  /// Conversation 创建时间。
  @override
  DateTime get createdAt;

  /// Conversation 最近更新时间。用于 sidebar sorting。
  @override
  DateTime get updatedAt;

  /// Create a copy of Conversation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ConversationImplCopyWith<_$ConversationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ConversationCreate _$ConversationCreateFromJson(Map<String, dynamic> json) {
  return _ConversationCreate.fromJson(json);
}

/// @nodoc
mixin _$ConversationCreate {
  /// 要绑定到此 conversation 的 model id。
  String get modelId => throw _privateConstructorUsedError;

  /// 可选的初始 title。通常在第一个 turn 前保持为空。
  String get title => throw _privateConstructorUsedError;

  /// 是否为新会话开启深度思考。
  bool get thinkingEnabled => throw _privateConstructorUsedError;

  /// Serializes this ConversationCreate to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ConversationCreate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ConversationCreateCopyWith<ConversationCreate> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConversationCreateCopyWith<$Res> {
  factory $ConversationCreateCopyWith(
    ConversationCreate value,
    $Res Function(ConversationCreate) then,
  ) = _$ConversationCreateCopyWithImpl<$Res, ConversationCreate>;
  @useResult
  $Res call({String modelId, String title, bool thinkingEnabled});
}

/// @nodoc
class _$ConversationCreateCopyWithImpl<$Res, $Val extends ConversationCreate>
    implements $ConversationCreateCopyWith<$Res> {
  _$ConversationCreateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ConversationCreate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? modelId = null,
    Object? title = null,
    Object? thinkingEnabled = null,
  }) {
    return _then(
      _value.copyWith(
            modelId: null == modelId
                ? _value.modelId
                : modelId // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            thinkingEnabled: null == thinkingEnabled
                ? _value.thinkingEnabled
                : thinkingEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ConversationCreateImplCopyWith<$Res>
    implements $ConversationCreateCopyWith<$Res> {
  factory _$$ConversationCreateImplCopyWith(
    _$ConversationCreateImpl value,
    $Res Function(_$ConversationCreateImpl) then,
  ) = __$$ConversationCreateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String modelId, String title, bool thinkingEnabled});
}

/// @nodoc
class __$$ConversationCreateImplCopyWithImpl<$Res>
    extends _$ConversationCreateCopyWithImpl<$Res, _$ConversationCreateImpl>
    implements _$$ConversationCreateImplCopyWith<$Res> {
  __$$ConversationCreateImplCopyWithImpl(
    _$ConversationCreateImpl _value,
    $Res Function(_$ConversationCreateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ConversationCreate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? modelId = null,
    Object? title = null,
    Object? thinkingEnabled = null,
  }) {
    return _then(
      _$ConversationCreateImpl(
        modelId: null == modelId
            ? _value.modelId
            : modelId // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        thinkingEnabled: null == thinkingEnabled
            ? _value.thinkingEnabled
            : thinkingEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ConversationCreateImpl implements _ConversationCreate {
  const _$ConversationCreateImpl({
    required this.modelId,
    this.title = '',
    this.thinkingEnabled = false,
  });

  factory _$ConversationCreateImpl.fromJson(Map<String, dynamic> json) =>
      _$$ConversationCreateImplFromJson(json);

  /// 要绑定到此 conversation 的 model id。
  @override
  final String modelId;

  /// 可选的初始 title。通常在第一个 turn 前保持为空。
  @override
  @JsonKey()
  final String title;

  /// 是否为新会话开启深度思考。
  @override
  @JsonKey()
  final bool thinkingEnabled;

  @override
  String toString() {
    return 'ConversationCreate(modelId: $modelId, title: $title, thinkingEnabled: $thinkingEnabled)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConversationCreateImpl &&
            (identical(other.modelId, modelId) || other.modelId == modelId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.thinkingEnabled, thinkingEnabled) ||
                other.thinkingEnabled == thinkingEnabled));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, modelId, title, thinkingEnabled);

  /// Create a copy of ConversationCreate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ConversationCreateImplCopyWith<_$ConversationCreateImpl> get copyWith =>
      __$$ConversationCreateImplCopyWithImpl<_$ConversationCreateImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ConversationCreateImplToJson(this);
  }
}

abstract class _ConversationCreate implements ConversationCreate {
  const factory _ConversationCreate({
    required final String modelId,
    final String title,
    final bool thinkingEnabled,
  }) = _$ConversationCreateImpl;

  factory _ConversationCreate.fromJson(Map<String, dynamic> json) =
      _$ConversationCreateImpl.fromJson;

  /// 要绑定到此 conversation 的 model id。
  @override
  String get modelId;

  /// 可选的初始 title。通常在第一个 turn 前保持为空。
  @override
  String get title;

  /// 是否为新会话开启深度思考。
  @override
  bool get thinkingEnabled;

  /// Create a copy of ConversationCreate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ConversationCreateImplCopyWith<_$ConversationCreateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ConversationUpdate _$ConversationUpdateFromJson(Map<String, dynamic> json) {
  return _ConversationUpdate.fromJson(json);
}

/// @nodoc
mixin _$ConversationUpdate {
  /// 要修改的新 title。
  String? get title => throw _privateConstructorUsedError;

  /// 要修改的深度思考开关；`null` 表示不变。
  bool? get thinkingEnabled => throw _privateConstructorUsedError;

  /// Serializes this ConversationUpdate to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ConversationUpdate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ConversationUpdateCopyWith<ConversationUpdate> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConversationUpdateCopyWith<$Res> {
  factory $ConversationUpdateCopyWith(
    ConversationUpdate value,
    $Res Function(ConversationUpdate) then,
  ) = _$ConversationUpdateCopyWithImpl<$Res, ConversationUpdate>;
  @useResult
  $Res call({String? title, bool? thinkingEnabled});
}

/// @nodoc
class _$ConversationUpdateCopyWithImpl<$Res, $Val extends ConversationUpdate>
    implements $ConversationUpdateCopyWith<$Res> {
  _$ConversationUpdateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ConversationUpdate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? title = freezed, Object? thinkingEnabled = freezed}) {
    return _then(
      _value.copyWith(
            title: freezed == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String?,
            thinkingEnabled: freezed == thinkingEnabled
                ? _value.thinkingEnabled
                : thinkingEnabled // ignore: cast_nullable_to_non_nullable
                      as bool?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ConversationUpdateImplCopyWith<$Res>
    implements $ConversationUpdateCopyWith<$Res> {
  factory _$$ConversationUpdateImplCopyWith(
    _$ConversationUpdateImpl value,
    $Res Function(_$ConversationUpdateImpl) then,
  ) = __$$ConversationUpdateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String? title, bool? thinkingEnabled});
}

/// @nodoc
class __$$ConversationUpdateImplCopyWithImpl<$Res>
    extends _$ConversationUpdateCopyWithImpl<$Res, _$ConversationUpdateImpl>
    implements _$$ConversationUpdateImplCopyWith<$Res> {
  __$$ConversationUpdateImplCopyWithImpl(
    _$ConversationUpdateImpl _value,
    $Res Function(_$ConversationUpdateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ConversationUpdate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? title = freezed, Object? thinkingEnabled = freezed}) {
    return _then(
      _$ConversationUpdateImpl(
        title: freezed == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String?,
        thinkingEnabled: freezed == thinkingEnabled
            ? _value.thinkingEnabled
            : thinkingEnabled // ignore: cast_nullable_to_non_nullable
                  as bool?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ConversationUpdateImpl implements _ConversationUpdate {
  const _$ConversationUpdateImpl({this.title, this.thinkingEnabled});

  factory _$ConversationUpdateImpl.fromJson(Map<String, dynamic> json) =>
      _$$ConversationUpdateImplFromJson(json);

  /// 要修改的新 title。
  @override
  final String? title;

  /// 要修改的深度思考开关；`null` 表示不变。
  @override
  final bool? thinkingEnabled;

  @override
  String toString() {
    return 'ConversationUpdate(title: $title, thinkingEnabled: $thinkingEnabled)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConversationUpdateImpl &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.thinkingEnabled, thinkingEnabled) ||
                other.thinkingEnabled == thinkingEnabled));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, title, thinkingEnabled);

  /// Create a copy of ConversationUpdate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ConversationUpdateImplCopyWith<_$ConversationUpdateImpl> get copyWith =>
      __$$ConversationUpdateImplCopyWithImpl<_$ConversationUpdateImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ConversationUpdateImplToJson(this);
  }
}

abstract class _ConversationUpdate implements ConversationUpdate {
  const factory _ConversationUpdate({
    final String? title,
    final bool? thinkingEnabled,
  }) = _$ConversationUpdateImpl;

  factory _ConversationUpdate.fromJson(Map<String, dynamic> json) =
      _$ConversationUpdateImpl.fromJson;

  /// 要修改的新 title。
  @override
  String? get title;

  /// 要修改的深度思考开关；`null` 表示不变。
  @override
  bool? get thinkingEnabled;

  /// Create a copy of ConversationUpdate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ConversationUpdateImplCopyWith<_$ConversationUpdateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
