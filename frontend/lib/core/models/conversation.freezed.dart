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
  /// The server-assigned identifier, used in the `/c/{id}` URL.
  int get id => throw _privateConstructorUsedError;

  /// The profile this conversation belongs to.
  int get profileId => throw _privateConstructorUsedError;

  /// The human-readable title. Empty until the first message is sent.
  String get title => throw _privateConstructorUsedError;

  /// The model id from `config.yaml`. Fixed at creation; to use another
  /// model, create a new conversation.
  String get modelId => throw _privateConstructorUsedError;

  /// The thinking-effort level for this conversation. One of the levels
  /// listed in the bound model's `thinking_effort` field. Changeable via
  /// `PATCH`.
  String get thinkingEffort => throw _privateConstructorUsedError;

  /// The id of the last message on the visible path, or `null` if the
  /// conversation has no messages yet.
  int? get currentLeafId => throw _privateConstructorUsedError;

  /// When the conversation was created.
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// When the conversation was last updated. Used for sidebar sorting.
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
    String thinkingEffort,
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
    Object? thinkingEffort = null,
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
            thinkingEffort: null == thinkingEffort
                ? _value.thinkingEffort
                : thinkingEffort // ignore: cast_nullable_to_non_nullable
                      as String,
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
    String thinkingEffort,
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
    Object? thinkingEffort = null,
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
        thinkingEffort: null == thinkingEffort
            ? _value.thinkingEffort
            : thinkingEffort // ignore: cast_nullable_to_non_nullable
                  as String,
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
    required this.thinkingEffort,
    required this.currentLeafId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory _$ConversationImpl.fromJson(Map<String, dynamic> json) =>
      _$$ConversationImplFromJson(json);

  /// The server-assigned identifier, used in the `/c/{id}` URL.
  @override
  final int id;

  /// The profile this conversation belongs to.
  @override
  final int profileId;

  /// The human-readable title. Empty until the first message is sent.
  @override
  final String title;

  /// The model id from `config.yaml`. Fixed at creation; to use another
  /// model, create a new conversation.
  @override
  final String modelId;

  /// The thinking-effort level for this conversation. One of the levels
  /// listed in the bound model's `thinking_effort` field. Changeable via
  /// `PATCH`.
  @override
  final String thinkingEffort;

  /// The id of the last message on the visible path, or `null` if the
  /// conversation has no messages yet.
  @override
  final int? currentLeafId;

  /// When the conversation was created.
  @override
  final DateTime createdAt;

  /// When the conversation was last updated. Used for sidebar sorting.
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'Conversation(id: $id, profileId: $profileId, title: $title, modelId: $modelId, thinkingEffort: $thinkingEffort, currentLeafId: $currentLeafId, createdAt: $createdAt, updatedAt: $updatedAt)';
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
            (identical(other.thinkingEffort, thinkingEffort) ||
                other.thinkingEffort == thinkingEffort) &&
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
    thinkingEffort,
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
    required final String thinkingEffort,
    required final int? currentLeafId,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _$ConversationImpl;

  factory _Conversation.fromJson(Map<String, dynamic> json) =
      _$ConversationImpl.fromJson;

  /// The server-assigned identifier, used in the `/c/{id}` URL.
  @override
  int get id;

  /// The profile this conversation belongs to.
  @override
  int get profileId;

  /// The human-readable title. Empty until the first message is sent.
  @override
  String get title;

  /// The model id from `config.yaml`. Fixed at creation; to use another
  /// model, create a new conversation.
  @override
  String get modelId;

  /// The thinking-effort level for this conversation. One of the levels
  /// listed in the bound model's `thinking_effort` field. Changeable via
  /// `PATCH`.
  @override
  String get thinkingEffort;

  /// The id of the last message on the visible path, or `null` if the
  /// conversation has no messages yet.
  @override
  int? get currentLeafId;

  /// When the conversation was created.
  @override
  DateTime get createdAt;

  /// When the conversation was last updated. Used for sidebar sorting.
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
  /// The model id to bind to this conversation.
  String get modelId => throw _privateConstructorUsedError;

  /// An optional starting title. Usually left empty until the first turn.
  String get title => throw _privateConstructorUsedError;

  /// An optional thinking-effort level. Must be one of the model's listed
  /// levels; `null` means "use the model's default".
  String? get thinkingEffort => throw _privateConstructorUsedError;

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
  $Res call({String modelId, String title, String? thinkingEffort});
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
    Object? thinkingEffort = freezed,
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
            thinkingEffort: freezed == thinkingEffort
                ? _value.thinkingEffort
                : thinkingEffort // ignore: cast_nullable_to_non_nullable
                      as String?,
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
  $Res call({String modelId, String title, String? thinkingEffort});
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
    Object? thinkingEffort = freezed,
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
        thinkingEffort: freezed == thinkingEffort
            ? _value.thinkingEffort
            : thinkingEffort // ignore: cast_nullable_to_non_nullable
                  as String?,
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
    this.thinkingEffort,
  });

  factory _$ConversationCreateImpl.fromJson(Map<String, dynamic> json) =>
      _$$ConversationCreateImplFromJson(json);

  /// The model id to bind to this conversation.
  @override
  final String modelId;

  /// An optional starting title. Usually left empty until the first turn.
  @override
  @JsonKey()
  final String title;

  /// An optional thinking-effort level. Must be one of the model's listed
  /// levels; `null` means "use the model's default".
  @override
  final String? thinkingEffort;

  @override
  String toString() {
    return 'ConversationCreate(modelId: $modelId, title: $title, thinkingEffort: $thinkingEffort)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConversationCreateImpl &&
            (identical(other.modelId, modelId) || other.modelId == modelId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.thinkingEffort, thinkingEffort) ||
                other.thinkingEffort == thinkingEffort));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, modelId, title, thinkingEffort);

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
    final String? thinkingEffort,
  }) = _$ConversationCreateImpl;

  factory _ConversationCreate.fromJson(Map<String, dynamic> json) =
      _$ConversationCreateImpl.fromJson;

  /// The model id to bind to this conversation.
  @override
  String get modelId;

  /// An optional starting title. Usually left empty until the first turn.
  @override
  String get title;

  /// An optional thinking-effort level. Must be one of the model's listed
  /// levels; `null` means "use the model's default".
  @override
  String? get thinkingEffort;

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
  /// The new title, if changing it.
  String? get title => throw _privateConstructorUsedError;

  /// The new thinking-effort level, if changing it. Must be one of the
  /// model's supported levels.
  String? get thinkingEffort => throw _privateConstructorUsedError;

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
  $Res call({String? title, String? thinkingEffort});
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
  $Res call({Object? title = freezed, Object? thinkingEffort = freezed}) {
    return _then(
      _value.copyWith(
            title: freezed == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String?,
            thinkingEffort: freezed == thinkingEffort
                ? _value.thinkingEffort
                : thinkingEffort // ignore: cast_nullable_to_non_nullable
                      as String?,
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
  $Res call({String? title, String? thinkingEffort});
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
  $Res call({Object? title = freezed, Object? thinkingEffort = freezed}) {
    return _then(
      _$ConversationUpdateImpl(
        title: freezed == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String?,
        thinkingEffort: freezed == thinkingEffort
            ? _value.thinkingEffort
            : thinkingEffort // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ConversationUpdateImpl implements _ConversationUpdate {
  const _$ConversationUpdateImpl({this.title, this.thinkingEffort});

  factory _$ConversationUpdateImpl.fromJson(Map<String, dynamic> json) =>
      _$$ConversationUpdateImplFromJson(json);

  /// The new title, if changing it.
  @override
  final String? title;

  /// The new thinking-effort level, if changing it. Must be one of the
  /// model's supported levels.
  @override
  final String? thinkingEffort;

  @override
  String toString() {
    return 'ConversationUpdate(title: $title, thinkingEffort: $thinkingEffort)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConversationUpdateImpl &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.thinkingEffort, thinkingEffort) ||
                other.thinkingEffort == thinkingEffort));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, title, thinkingEffort);

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
    final String? thinkingEffort,
  }) = _$ConversationUpdateImpl;

  factory _ConversationUpdate.fromJson(Map<String, dynamic> json) =
      _$ConversationUpdateImpl.fromJson;

  /// The new title, if changing it.
  @override
  String? get title;

  /// The new thinking-effort level, if changing it. Must be one of the
  /// model's supported levels.
  @override
  String? get thinkingEffort;

  /// Create a copy of ConversationUpdate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ConversationUpdateImplCopyWith<_$ConversationUpdateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
