// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ModelRead _$ModelReadFromJson(Map<String, dynamic> json) {
  return _ModelRead.fromJson(json);
}

/// @nodoc
mixin _$ModelRead {
  /// 创建 conversation 时使用的 model id。
  String get id => throw _privateConstructorUsedError;

  /// Model selector 和 assistant message 下方 model badge 中显示的可读名称。
  String get displayName => throw _privateConstructorUsedError;

  /// Model family，例如 "gpt" 或 "claude"。仅用于提供上下文；frontend 不会根据它
  /// 分支处理（decision D4.3）。
  String get family => throw _privateConstructorUsedError;

  /// Upstream protocol，例如 "openai-response" 或 "anthropic-message"。
  /// 保持为 string；frontend 不会根据它分支处理。
  String get protocol => throw _privateConstructorUsedError;

  /// 此 model 是否可以接收 image attachment。
  bool get vision => throw _privateConstructorUsedError;

  /// 支持的 thinking-effort level，按 UI 应显示的顺序排列。第一项是新 conversation
  /// 的默认值。
  List<String> get thinkingEffort => throw _privateConstructorUsedError;

  /// 将此 ModelRead serialize 为 JSON map。
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// 创建 ModelRead 的副本，并用非 null parameter value 替换给定 field。
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ModelReadCopyWith<ModelRead> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ModelReadCopyWith<$Res> {
  factory $ModelReadCopyWith(ModelRead value, $Res Function(ModelRead) then) =
      _$ModelReadCopyWithImpl<$Res, ModelRead>;
  @useResult
  $Res call({
    String id,
    String displayName,
    String family,
    String protocol,
    bool vision,
    List<String> thinkingEffort,
  });
}

/// @nodoc
class _$ModelReadCopyWithImpl<$Res, $Val extends ModelRead>
    implements $ModelReadCopyWith<$Res> {
  _$ModelReadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// 创建 ModelRead 的副本，并用非 null parameter value 替换给定 field。
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? displayName = null,
    Object? family = null,
    Object? protocol = null,
    Object? vision = null,
    Object? thinkingEffort = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            displayName: null == displayName
                ? _value.displayName
                : displayName // ignore: cast_nullable_to_non_nullable
                      as String,
            family: null == family
                ? _value.family
                : family // ignore: cast_nullable_to_non_nullable
                      as String,
            protocol: null == protocol
                ? _value.protocol
                : protocol // ignore: cast_nullable_to_non_nullable
                      as String,
            vision: null == vision
                ? _value.vision
                : vision // ignore: cast_nullable_to_non_nullable
                      as bool,
            thinkingEffort: null == thinkingEffort
                ? _value.thinkingEffort
                : thinkingEffort // ignore: cast_nullable_to_non_nullable
                      as List<String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ModelReadImplCopyWith<$Res>
    implements $ModelReadCopyWith<$Res> {
  factory _$$ModelReadImplCopyWith(
    _$ModelReadImpl value,
    $Res Function(_$ModelReadImpl) then,
  ) = __$$ModelReadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String displayName,
    String family,
    String protocol,
    bool vision,
    List<String> thinkingEffort,
  });
}

/// @nodoc
class __$$ModelReadImplCopyWithImpl<$Res>
    extends _$ModelReadCopyWithImpl<$Res, _$ModelReadImpl>
    implements _$$ModelReadImplCopyWith<$Res> {
  __$$ModelReadImplCopyWithImpl(
    _$ModelReadImpl _value,
    $Res Function(_$ModelReadImpl) _then,
  ) : super(_value, _then);

  /// 创建 ModelRead 的副本，并用非 null parameter value 替换给定 field。
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? displayName = null,
    Object? family = null,
    Object? protocol = null,
    Object? vision = null,
    Object? thinkingEffort = null,
  }) {
    return _then(
      _$ModelReadImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        displayName: null == displayName
            ? _value.displayName
            : displayName // ignore: cast_nullable_to_non_nullable
                  as String,
        family: null == family
            ? _value.family
            : family // ignore: cast_nullable_to_non_nullable
                  as String,
        protocol: null == protocol
            ? _value.protocol
            : protocol // ignore: cast_nullable_to_non_nullable
                  as String,
        vision: null == vision
            ? _value.vision
            : vision // ignore: cast_nullable_to_non_nullable
                  as bool,
        thinkingEffort: null == thinkingEffort
            ? _value._thinkingEffort
            : thinkingEffort // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ModelReadImpl implements _ModelRead {
  const _$ModelReadImpl({
    required this.id,
    required this.displayName,
    required this.family,
    required this.protocol,
    required this.vision,
    final List<String> thinkingEffort = const <String>[],
  }) : _thinkingEffort = thinkingEffort;

  factory _$ModelReadImpl.fromJson(Map<String, dynamic> json) =>
      _$$ModelReadImplFromJson(json);

  /// 创建 conversation 时使用的 model id。
  @override
  final String id;

  /// Model selector 和 assistant message 下方 model badge 中显示的可读名称。
  @override
  final String displayName;

  /// Model family，例如 "gpt" 或 "claude"。仅用于提供上下文；frontend 不会根据它
  /// 分支处理（decision D4.3）。
  @override
  final String family;

  /// Upstream protocol，例如 "openai-response" 或 "anthropic-message"。
  /// 保持为 string；frontend 不会根据它分支处理。
  @override
  final String protocol;

  /// 此 model 是否可以接收 image attachment。
  @override
  final bool vision;

  /// 支持的 thinking-effort level，按 UI 应显示的顺序排列。第一项是新 conversation
  /// 的默认值。
  final List<String> _thinkingEffort;

  /// 支持的 thinking-effort level，按 UI 应显示的顺序排列。第一项是新 conversation
  /// 的默认值。
  @override
  @JsonKey()
  List<String> get thinkingEffort {
    if (_thinkingEffort is EqualUnmodifiableListView) return _thinkingEffort;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_thinkingEffort);
  }

  @override
  String toString() {
    return 'ModelRead(id: $id, displayName: $displayName, family: $family, protocol: $protocol, vision: $vision, thinkingEffort: $thinkingEffort)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ModelReadImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.family, family) || other.family == family) &&
            (identical(other.protocol, protocol) ||
                other.protocol == protocol) &&
            (identical(other.vision, vision) || other.vision == vision) &&
            const DeepCollectionEquality().equals(
              other._thinkingEffort,
              _thinkingEffort,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    displayName,
    family,
    protocol,
    vision,
    const DeepCollectionEquality().hash(_thinkingEffort),
  );

  /// 创建 ModelRead 的副本，并用非 null parameter value 替换给定 field。
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ModelReadImplCopyWith<_$ModelReadImpl> get copyWith =>
      __$$ModelReadImplCopyWithImpl<_$ModelReadImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ModelReadImplToJson(this);
  }
}

abstract class _ModelRead implements ModelRead {
  const factory _ModelRead({
    required final String id,
    required final String displayName,
    required final String family,
    required final String protocol,
    required final bool vision,
    final List<String> thinkingEffort,
  }) = _$ModelReadImpl;

  factory _ModelRead.fromJson(Map<String, dynamic> json) =
      _$ModelReadImpl.fromJson;

  /// 创建 conversation 时使用的 model id。
  @override
  String get id;

  /// Model selector 和 assistant message 下方 model badge 中显示的可读名称。
  @override
  String get displayName;

  /// Model family，例如 "gpt" 或 "claude"。仅用于提供上下文；frontend 不会根据它
  /// 分支处理（decision D4.3）。
  @override
  String get family;

  /// Upstream protocol，例如 "openai-response" 或 "anthropic-message"。
  /// 保持为 string；frontend 不会根据它分支处理。
  @override
  String get protocol;

  /// 此 model 是否可以接收 image attachment。
  @override
  bool get vision;

  /// 支持的 thinking-effort level，按 UI 应显示的顺序排列。第一项是新 conversation
  /// 的默认值。
  @override
  List<String> get thinkingEffort;

  /// 创建 ModelRead 的副本，并用非 null parameter value 替换给定 field。
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ModelReadImplCopyWith<_$ModelReadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ModelsResponse _$ModelsResponseFromJson(Map<String, dynamic> json) {
  return _ModelsResponse.fromJson(json);
}

/// @nodoc
mixin _$ModelsResponse {
  /// 配置的默认 model id。用于 empty state 的 model picker 初始选择。
  String get defaultModel => throw _privateConstructorUsedError;

  /// backend config 中声明的所有 model。
  List<ModelRead> get models => throw _privateConstructorUsedError;

  /// 将此 ModelsResponse serialize 为 JSON map。
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// 创建 ModelsResponse 的副本，并用非 null parameter value 替换给定 field。
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ModelsResponseCopyWith<ModelsResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ModelsResponseCopyWith<$Res> {
  factory $ModelsResponseCopyWith(
    ModelsResponse value,
    $Res Function(ModelsResponse) then,
  ) = _$ModelsResponseCopyWithImpl<$Res, ModelsResponse>;
  @useResult
  $Res call({String defaultModel, List<ModelRead> models});
}

/// @nodoc
class _$ModelsResponseCopyWithImpl<$Res, $Val extends ModelsResponse>
    implements $ModelsResponseCopyWith<$Res> {
  _$ModelsResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// 创建 ModelsResponse 的副本，并用非 null parameter value 替换给定 field。
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? defaultModel = null, Object? models = null}) {
    return _then(
      _value.copyWith(
            defaultModel: null == defaultModel
                ? _value.defaultModel
                : defaultModel // ignore: cast_nullable_to_non_nullable
                      as String,
            models: null == models
                ? _value.models
                : models // ignore: cast_nullable_to_non_nullable
                      as List<ModelRead>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ModelsResponseImplCopyWith<$Res>
    implements $ModelsResponseCopyWith<$Res> {
  factory _$$ModelsResponseImplCopyWith(
    _$ModelsResponseImpl value,
    $Res Function(_$ModelsResponseImpl) then,
  ) = __$$ModelsResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String defaultModel, List<ModelRead> models});
}

/// @nodoc
class __$$ModelsResponseImplCopyWithImpl<$Res>
    extends _$ModelsResponseCopyWithImpl<$Res, _$ModelsResponseImpl>
    implements _$$ModelsResponseImplCopyWith<$Res> {
  __$$ModelsResponseImplCopyWithImpl(
    _$ModelsResponseImpl _value,
    $Res Function(_$ModelsResponseImpl) _then,
  ) : super(_value, _then);

  /// 创建 ModelsResponse 的副本，并用非 null parameter value 替换给定 field。
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? defaultModel = null, Object? models = null}) {
    return _then(
      _$ModelsResponseImpl(
        defaultModel: null == defaultModel
            ? _value.defaultModel
            : defaultModel // ignore: cast_nullable_to_non_nullable
                  as String,
        models: null == models
            ? _value._models
            : models // ignore: cast_nullable_to_non_nullable
                  as List<ModelRead>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ModelsResponseImpl implements _ModelsResponse {
  const _$ModelsResponseImpl({
    required this.defaultModel,
    final List<ModelRead> models = const <ModelRead>[],
  }) : _models = models;

  factory _$ModelsResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$ModelsResponseImplFromJson(json);

  /// 配置的默认 model id。用于 empty state 的 model picker 初始选择。
  @override
  final String defaultModel;

  /// backend config 中声明的所有 model。
  final List<ModelRead> _models;

  /// backend config 中声明的所有 model。
  @override
  @JsonKey()
  List<ModelRead> get models {
    if (_models is EqualUnmodifiableListView) return _models;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_models);
  }

  @override
  String toString() {
    return 'ModelsResponse(defaultModel: $defaultModel, models: $models)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ModelsResponseImpl &&
            (identical(other.defaultModel, defaultModel) ||
                other.defaultModel == defaultModel) &&
            const DeepCollectionEquality().equals(other._models, _models));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    defaultModel,
    const DeepCollectionEquality().hash(_models),
  );

  /// 创建 ModelsResponse 的副本，并用非 null parameter value 替换给定 field。
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ModelsResponseImplCopyWith<_$ModelsResponseImpl> get copyWith =>
      __$$ModelsResponseImplCopyWithImpl<_$ModelsResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ModelsResponseImplToJson(this);
  }
}

abstract class _ModelsResponse implements ModelsResponse {
  const factory _ModelsResponse({
    required final String defaultModel,
    final List<ModelRead> models,
  }) = _$ModelsResponseImpl;

  factory _ModelsResponse.fromJson(Map<String, dynamic> json) =
      _$ModelsResponseImpl.fromJson;

  /// 配置的默认 model id。用于 empty state 的 model picker 初始选择。
  @override
  String get defaultModel;

  /// backend config 中声明的所有 model。
  @override
  List<ModelRead> get models;

  /// 创建 ModelsResponse 的副本，并用非 null parameter value 替换给定 field。
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ModelsResponseImplCopyWith<_$ModelsResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
