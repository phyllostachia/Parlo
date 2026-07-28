// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Message _$MessageFromJson(Map<String, dynamic> json) {
  return _Message.fromJson(json);
}

/// @nodoc
mixin _$Message {
  /// Server 分配的 identifier。
  int get id => throw _privateConstructorUsedError;

  /// 此 message 所属的 conversation。
  int get conversationId => throw _privateConstructorUsedError;

  /// Parent message id；root message 为 `null`。
  int? get parentId => throw _privateConstructorUsedError;

  /// 生成此 message 的 role。
  MessageRole get role => throw _privateConstructorUsedError;

  /// Text body。Assistant 仍在 streaming 时为空。
  String get content => throw _privateConstructorUsedError;

  /// Model 的 reasoning（“thinking” trace，如果有）。User message 以及 model 未生成
  /// reasoning 的 assistant message 为 `null`。
  String? get reasoning => throw _privateConstructorUsedError;

  /// 从开始请求到 reasoning 完成的耗时。没有 reasoning 的 message 为 `null`。
  int? get reasoningDurationMs => throw _privateConstructorUsedError;

  /// Client 可以获取附加 image 的 URL（如果有）。`null` 表示没有 image。
  String? get imageUrl => throw _privateConstructorUsedError;

  /// Server 仍向此 message streaming token 时为 `false`。注意：backend 在 `finally` block
  /// 中将其设为 `true`，因此 broken stream 也会以 `is_complete = true` 结束。Frontend
  /// 维护自己的 [StreamState] 来区分二者（架构 §5.4）。
  bool get isComplete => throw _privateConstructorUsedError;

  /// Message 创建时间。
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this Message to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MessageCopyWith<Message> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MessageCopyWith<$Res> {
  factory $MessageCopyWith(Message value, $Res Function(Message) then) =
      _$MessageCopyWithImpl<$Res, Message>;
  @useResult
  $Res call({
    int id,
    int conversationId,
    int? parentId,
    MessageRole role,
    String content,
    String? reasoning,
    int? reasoningDurationMs,
    String? imageUrl,
    bool isComplete,
    DateTime createdAt,
  });
}

/// @nodoc
class _$MessageCopyWithImpl<$Res, $Val extends Message>
    implements $MessageCopyWith<$Res> {
  _$MessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? conversationId = null,
    Object? parentId = freezed,
    Object? role = null,
    Object? content = null,
    Object? reasoning = freezed,
    Object? reasoningDurationMs = freezed,
    Object? imageUrl = freezed,
    Object? isComplete = null,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            conversationId: null == conversationId
                ? _value.conversationId
                : conversationId // ignore: cast_nullable_to_non_nullable
                      as int,
            parentId: freezed == parentId
                ? _value.parentId
                : parentId // ignore: cast_nullable_to_non_nullable
                      as int?,
            role: null == role
                ? _value.role
                : role // ignore: cast_nullable_to_non_nullable
                      as MessageRole,
            content: null == content
                ? _value.content
                : content // ignore: cast_nullable_to_non_nullable
                      as String,
            reasoning: freezed == reasoning
                ? _value.reasoning
                : reasoning // ignore: cast_nullable_to_non_nullable
                      as String?,
            reasoningDurationMs: freezed == reasoningDurationMs
                ? _value.reasoningDurationMs
                : reasoningDurationMs // ignore: cast_nullable_to_non_nullable
                      as int?,
            imageUrl: freezed == imageUrl
                ? _value.imageUrl
                : imageUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            isComplete: null == isComplete
                ? _value.isComplete
                : isComplete // ignore: cast_nullable_to_non_nullable
                      as bool,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MessageImplCopyWith<$Res> implements $MessageCopyWith<$Res> {
  factory _$$MessageImplCopyWith(
    _$MessageImpl value,
    $Res Function(_$MessageImpl) then,
  ) = __$$MessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    int conversationId,
    int? parentId,
    MessageRole role,
    String content,
    String? reasoning,
    int? reasoningDurationMs,
    String? imageUrl,
    bool isComplete,
    DateTime createdAt,
  });
}

/// @nodoc
class __$$MessageImplCopyWithImpl<$Res>
    extends _$MessageCopyWithImpl<$Res, _$MessageImpl>
    implements _$$MessageImplCopyWith<$Res> {
  __$$MessageImplCopyWithImpl(
    _$MessageImpl _value,
    $Res Function(_$MessageImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? conversationId = null,
    Object? parentId = freezed,
    Object? role = null,
    Object? content = null,
    Object? reasoning = freezed,
    Object? reasoningDurationMs = freezed,
    Object? imageUrl = freezed,
    Object? isComplete = null,
    Object? createdAt = null,
  }) {
    return _then(
      _$MessageImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        conversationId: null == conversationId
            ? _value.conversationId
            : conversationId // ignore: cast_nullable_to_non_nullable
                  as int,
        parentId: freezed == parentId
            ? _value.parentId
            : parentId // ignore: cast_nullable_to_non_nullable
                  as int?,
        role: null == role
            ? _value.role
            : role // ignore: cast_nullable_to_non_nullable
                  as MessageRole,
        content: null == content
            ? _value.content
            : content // ignore: cast_nullable_to_non_nullable
                  as String,
        reasoning: freezed == reasoning
            ? _value.reasoning
            : reasoning // ignore: cast_nullable_to_non_nullable
                  as String?,
        reasoningDurationMs: freezed == reasoningDurationMs
            ? _value.reasoningDurationMs
            : reasoningDurationMs // ignore: cast_nullable_to_non_nullable
                  as int?,
        imageUrl: freezed == imageUrl
            ? _value.imageUrl
            : imageUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        isComplete: null == isComplete
            ? _value.isComplete
            : isComplete // ignore: cast_nullable_to_non_nullable
                  as bool,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MessageImpl implements _Message {
  const _$MessageImpl({
    required this.id,
    required this.conversationId,
    required this.parentId,
    required this.role,
    required this.content,
    required this.reasoning,
    this.reasoningDurationMs,
    required this.imageUrl,
    required this.isComplete,
    required this.createdAt,
  });

  factory _$MessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$MessageImplFromJson(json);

  /// Server 分配的 identifier。
  @override
  final int id;

  /// 此 message 所属的 conversation。
  @override
  final int conversationId;

  /// Parent message id；root message 为 `null`。
  @override
  final int? parentId;

  /// 生成此 message 的 role。
  @override
  final MessageRole role;

  /// Text body。Assistant 仍在 streaming 时为空。
  @override
  final String content;

  /// Model 的 reasoning（“thinking” trace，如果有）。User message 以及 model 未生成
  /// reasoning 的 assistant message 为 `null`。
  @override
  final String? reasoning;

  /// 从开始请求到 reasoning 完成的耗时。没有 reasoning 的 message 为 `null`。
  @override
  final int? reasoningDurationMs;

  /// Client 可以获取附加 image 的 URL（如果有）。`null` 表示没有 image。
  @override
  final String? imageUrl;

  /// Server 仍向此 message streaming token 时为 `false`。注意：backend 在 `finally` block
  /// 中将其设为 `true`，因此 broken stream 也会以 `is_complete = true` 结束。Frontend
  /// 维护自己的 [StreamState] 来区分二者（架构 §5.4）。
  @override
  final bool isComplete;

  /// Message 创建时间。
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'Message(id: $id, conversationId: $conversationId, parentId: $parentId, role: $role, content: $content, reasoning: $reasoning, reasoningDurationMs: $reasoningDurationMs, imageUrl: $imageUrl, isComplete: $isComplete, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessageImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.conversationId, conversationId) ||
                other.conversationId == conversationId) &&
            (identical(other.parentId, parentId) ||
                other.parentId == parentId) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.reasoning, reasoning) ||
                other.reasoning == reasoning) &&
            (identical(other.reasoningDurationMs, reasoningDurationMs) ||
                other.reasoningDurationMs == reasoningDurationMs) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.isComplete, isComplete) ||
                other.isComplete == isComplete) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    conversationId,
    parentId,
    role,
    content,
    reasoning,
    reasoningDurationMs,
    imageUrl,
    isComplete,
    createdAt,
  );

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MessageImplCopyWith<_$MessageImpl> get copyWith =>
      __$$MessageImplCopyWithImpl<_$MessageImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MessageImplToJson(this);
  }
}

abstract class _Message implements Message {
  const factory _Message({
    required final int id,
    required final int conversationId,
    required final int? parentId,
    required final MessageRole role,
    required final String content,
    required final String? reasoning,
    final int? reasoningDurationMs,
    required final String? imageUrl,
    required final bool isComplete,
    required final DateTime createdAt,
  }) = _$MessageImpl;

  factory _Message.fromJson(Map<String, dynamic> json) = _$MessageImpl.fromJson;

  /// Server 分配的 identifier。
  @override
  int get id;

  /// 此 message 所属的 conversation。
  @override
  int get conversationId;

  /// Parent message id；root message 为 `null`。
  @override
  int? get parentId;

  /// 生成此 message 的 role。
  @override
  MessageRole get role;

  /// Text body。Assistant 仍在 streaming 时为空。
  @override
  String get content;

  /// Model 的 reasoning（“thinking” trace，如果有）。User message 以及 model 未生成
  /// reasoning 的 assistant message 为 `null`。
  @override
  String? get reasoning;

  /// 从开始请求到 reasoning 完成的耗时。没有 reasoning 的 message 为 `null`。
  @override
  int? get reasoningDurationMs;

  /// Client 可以获取附加 image 的 URL（如果有）。`null` 表示没有 image。
  @override
  String? get imageUrl;

  /// Server 仍向此 message streaming token 时为 `false`。注意：backend 在 `finally` block
  /// 中将其设为 `true`，因此 broken stream 也会以 `is_complete = true` 结束。Frontend
  /// 维护自己的 [StreamState] 来区分二者（架构 §5.4）。
  @override
  bool get isComplete;

  /// Message 创建时间。
  @override
  DateTime get createdAt;

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MessageImplCopyWith<_$MessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SiblingInfo _$SiblingInfoFromJson(Map<String, dynamic> json) {
  return _SiblingInfo.fromJson(json);
}

/// @nodoc
mixin _$SiblingInfo {
  /// 与该 node 的 parent 共享的所有 message id，包括该 node。
  List<int> get siblings => throw _privateConstructorUsedError;

  /// 当前可见 path 经过的 sibling id。
  int get activeId => throw _privateConstructorUsedError;

  /// Serializes this SiblingInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SiblingInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SiblingInfoCopyWith<SiblingInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SiblingInfoCopyWith<$Res> {
  factory $SiblingInfoCopyWith(
    SiblingInfo value,
    $Res Function(SiblingInfo) then,
  ) = _$SiblingInfoCopyWithImpl<$Res, SiblingInfo>;
  @useResult
  $Res call({List<int> siblings, int activeId});
}

/// @nodoc
class _$SiblingInfoCopyWithImpl<$Res, $Val extends SiblingInfo>
    implements $SiblingInfoCopyWith<$Res> {
  _$SiblingInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SiblingInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? siblings = null, Object? activeId = null}) {
    return _then(
      _value.copyWith(
            siblings: null == siblings
                ? _value.siblings
                : siblings // ignore: cast_nullable_to_non_nullable
                      as List<int>,
            activeId: null == activeId
                ? _value.activeId
                : activeId // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SiblingInfoImplCopyWith<$Res>
    implements $SiblingInfoCopyWith<$Res> {
  factory _$$SiblingInfoImplCopyWith(
    _$SiblingInfoImpl value,
    $Res Function(_$SiblingInfoImpl) then,
  ) = __$$SiblingInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<int> siblings, int activeId});
}

/// @nodoc
class __$$SiblingInfoImplCopyWithImpl<$Res>
    extends _$SiblingInfoCopyWithImpl<$Res, _$SiblingInfoImpl>
    implements _$$SiblingInfoImplCopyWith<$Res> {
  __$$SiblingInfoImplCopyWithImpl(
    _$SiblingInfoImpl _value,
    $Res Function(_$SiblingInfoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SiblingInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? siblings = null, Object? activeId = null}) {
    return _then(
      _$SiblingInfoImpl(
        siblings: null == siblings
            ? _value._siblings
            : siblings // ignore: cast_nullable_to_non_nullable
                  as List<int>,
        activeId: null == activeId
            ? _value.activeId
            : activeId // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SiblingInfoImpl implements _SiblingInfo {
  const _$SiblingInfoImpl({
    final List<int> siblings = const <int>[],
    required this.activeId,
  }) : _siblings = siblings;

  factory _$SiblingInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$SiblingInfoImplFromJson(json);

  /// 与该 node 的 parent 共享的所有 message id，包括该 node。
  final List<int> _siblings;

  /// 与该 node 的 parent 共享的所有 message id，包括该 node。
  @override
  @JsonKey()
  List<int> get siblings {
    if (_siblings is EqualUnmodifiableListView) return _siblings;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_siblings);
  }

  /// 当前可见 path 经过的 sibling id。
  @override
  final int activeId;

  @override
  String toString() {
    return 'SiblingInfo(siblings: $siblings, activeId: $activeId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SiblingInfoImpl &&
            const DeepCollectionEquality().equals(other._siblings, _siblings) &&
            (identical(other.activeId, activeId) ||
                other.activeId == activeId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_siblings),
    activeId,
  );

  /// Create a copy of SiblingInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SiblingInfoImplCopyWith<_$SiblingInfoImpl> get copyWith =>
      __$$SiblingInfoImplCopyWithImpl<_$SiblingInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SiblingInfoImplToJson(this);
  }
}

abstract class _SiblingInfo implements SiblingInfo {
  const factory _SiblingInfo({
    final List<int> siblings,
    required final int activeId,
  }) = _$SiblingInfoImpl;

  factory _SiblingInfo.fromJson(Map<String, dynamic> json) =
      _$SiblingInfoImpl.fromJson;

  /// 与该 node 的 parent 共享的所有 message id，包括该 node。
  @override
  List<int> get siblings;

  /// 当前可见 path 经过的 sibling id。
  @override
  int get activeId;

  /// Create a copy of SiblingInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SiblingInfoImplCopyWith<_$SiblingInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MessageTreeNode _$MessageTreeNodeFromJson(Map<String, dynamic> json) {
  return _MessageTreeNode.fromJson(json);
}

/// @nodoc
mixin _$MessageTreeNode {
  /// Path 此位置上的 message。
  Message get message => throw _privateConstructorUsedError;

  /// 用于渲染 version switcher 的 sibling metadata。
  SiblingInfo get siblings => throw _privateConstructorUsedError;

  /// Serializes this MessageTreeNode to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MessageTreeNode
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MessageTreeNodeCopyWith<MessageTreeNode> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MessageTreeNodeCopyWith<$Res> {
  factory $MessageTreeNodeCopyWith(
    MessageTreeNode value,
    $Res Function(MessageTreeNode) then,
  ) = _$MessageTreeNodeCopyWithImpl<$Res, MessageTreeNode>;
  @useResult
  $Res call({Message message, SiblingInfo siblings});

  $MessageCopyWith<$Res> get message;
  $SiblingInfoCopyWith<$Res> get siblings;
}

/// @nodoc
class _$MessageTreeNodeCopyWithImpl<$Res, $Val extends MessageTreeNode>
    implements $MessageTreeNodeCopyWith<$Res> {
  _$MessageTreeNodeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MessageTreeNode
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null, Object? siblings = null}) {
    return _then(
      _value.copyWith(
            message: null == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as Message,
            siblings: null == siblings
                ? _value.siblings
                : siblings // ignore: cast_nullable_to_non_nullable
                      as SiblingInfo,
          )
          as $Val,
    );
  }

  /// Create a copy of MessageTreeNode
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MessageCopyWith<$Res> get message {
    return $MessageCopyWith<$Res>(_value.message, (value) {
      return _then(_value.copyWith(message: value) as $Val);
    });
  }

  /// Create a copy of MessageTreeNode
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SiblingInfoCopyWith<$Res> get siblings {
    return $SiblingInfoCopyWith<$Res>(_value.siblings, (value) {
      return _then(_value.copyWith(siblings: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MessageTreeNodeImplCopyWith<$Res>
    implements $MessageTreeNodeCopyWith<$Res> {
  factory _$$MessageTreeNodeImplCopyWith(
    _$MessageTreeNodeImpl value,
    $Res Function(_$MessageTreeNodeImpl) then,
  ) = __$$MessageTreeNodeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Message message, SiblingInfo siblings});

  @override
  $MessageCopyWith<$Res> get message;
  @override
  $SiblingInfoCopyWith<$Res> get siblings;
}

/// @nodoc
class __$$MessageTreeNodeImplCopyWithImpl<$Res>
    extends _$MessageTreeNodeCopyWithImpl<$Res, _$MessageTreeNodeImpl>
    implements _$$MessageTreeNodeImplCopyWith<$Res> {
  __$$MessageTreeNodeImplCopyWithImpl(
    _$MessageTreeNodeImpl _value,
    $Res Function(_$MessageTreeNodeImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MessageTreeNode
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null, Object? siblings = null}) {
    return _then(
      _$MessageTreeNodeImpl(
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as Message,
        siblings: null == siblings
            ? _value.siblings
            : siblings // ignore: cast_nullable_to_non_nullable
                  as SiblingInfo,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MessageTreeNodeImpl implements _MessageTreeNode {
  const _$MessageTreeNodeImpl({required this.message, required this.siblings});

  factory _$MessageTreeNodeImpl.fromJson(Map<String, dynamic> json) =>
      _$$MessageTreeNodeImplFromJson(json);

  /// Path 此位置上的 message。
  @override
  final Message message;

  /// 用于渲染 version switcher 的 sibling metadata。
  @override
  final SiblingInfo siblings;

  @override
  String toString() {
    return 'MessageTreeNode(message: $message, siblings: $siblings)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessageTreeNodeImpl &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.siblings, siblings) ||
                other.siblings == siblings));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, message, siblings);

  /// Create a copy of MessageTreeNode
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MessageTreeNodeImplCopyWith<_$MessageTreeNodeImpl> get copyWith =>
      __$$MessageTreeNodeImplCopyWithImpl<_$MessageTreeNodeImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$MessageTreeNodeImplToJson(this);
  }
}

abstract class _MessageTreeNode implements MessageTreeNode {
  const factory _MessageTreeNode({
    required final Message message,
    required final SiblingInfo siblings,
  }) = _$MessageTreeNodeImpl;

  factory _MessageTreeNode.fromJson(Map<String, dynamic> json) =
      _$MessageTreeNodeImpl.fromJson;

  /// Path 此位置上的 message。
  @override
  Message get message;

  /// 用于渲染 version switcher 的 sibling metadata。
  @override
  SiblingInfo get siblings;

  /// Create a copy of MessageTreeNode
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MessageTreeNodeImplCopyWith<_$MessageTreeNodeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ConversationPath _$ConversationPathFromJson(Map<String, dynamic> json) {
  return _ConversationPath.fromJson(json);
}

/// @nodoc
mixin _$ConversationPath {
  /// 此 path 所属的 conversation。
  Conversation get conversation => throw _privateConstructorUsedError;

  /// 从 root 到 current leaf 的可见 message。
  List<MessageTreeNode> get path => throw _privateConstructorUsedError;

  /// Serializes this ConversationPath to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ConversationPath
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ConversationPathCopyWith<ConversationPath> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConversationPathCopyWith<$Res> {
  factory $ConversationPathCopyWith(
    ConversationPath value,
    $Res Function(ConversationPath) then,
  ) = _$ConversationPathCopyWithImpl<$Res, ConversationPath>;
  @useResult
  $Res call({Conversation conversation, List<MessageTreeNode> path});

  $ConversationCopyWith<$Res> get conversation;
}

/// @nodoc
class _$ConversationPathCopyWithImpl<$Res, $Val extends ConversationPath>
    implements $ConversationPathCopyWith<$Res> {
  _$ConversationPathCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ConversationPath
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? conversation = null, Object? path = null}) {
    return _then(
      _value.copyWith(
            conversation: null == conversation
                ? _value.conversation
                : conversation // ignore: cast_nullable_to_non_nullable
                      as Conversation,
            path: null == path
                ? _value.path
                : path // ignore: cast_nullable_to_non_nullable
                      as List<MessageTreeNode>,
          )
          as $Val,
    );
  }

  /// Create a copy of ConversationPath
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ConversationCopyWith<$Res> get conversation {
    return $ConversationCopyWith<$Res>(_value.conversation, (value) {
      return _then(_value.copyWith(conversation: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ConversationPathImplCopyWith<$Res>
    implements $ConversationPathCopyWith<$Res> {
  factory _$$ConversationPathImplCopyWith(
    _$ConversationPathImpl value,
    $Res Function(_$ConversationPathImpl) then,
  ) = __$$ConversationPathImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Conversation conversation, List<MessageTreeNode> path});

  @override
  $ConversationCopyWith<$Res> get conversation;
}

/// @nodoc
class __$$ConversationPathImplCopyWithImpl<$Res>
    extends _$ConversationPathCopyWithImpl<$Res, _$ConversationPathImpl>
    implements _$$ConversationPathImplCopyWith<$Res> {
  __$$ConversationPathImplCopyWithImpl(
    _$ConversationPathImpl _value,
    $Res Function(_$ConversationPathImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ConversationPath
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? conversation = null, Object? path = null}) {
    return _then(
      _$ConversationPathImpl(
        conversation: null == conversation
            ? _value.conversation
            : conversation // ignore: cast_nullable_to_non_nullable
                  as Conversation,
        path: null == path
            ? _value._path
            : path // ignore: cast_nullable_to_non_nullable
                  as List<MessageTreeNode>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ConversationPathImpl implements _ConversationPath {
  const _$ConversationPathImpl({
    required this.conversation,
    final List<MessageTreeNode> path = const <MessageTreeNode>[],
  }) : _path = path;

  factory _$ConversationPathImpl.fromJson(Map<String, dynamic> json) =>
      _$$ConversationPathImplFromJson(json);

  /// 此 path 所属的 conversation。
  @override
  final Conversation conversation;

  /// 从 root 到 current leaf 的可见 message。
  final List<MessageTreeNode> _path;

  /// 从 root 到 current leaf 的可见 message。
  @override
  @JsonKey()
  List<MessageTreeNode> get path {
    if (_path is EqualUnmodifiableListView) return _path;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_path);
  }

  @override
  String toString() {
    return 'ConversationPath(conversation: $conversation, path: $path)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConversationPathImpl &&
            (identical(other.conversation, conversation) ||
                other.conversation == conversation) &&
            const DeepCollectionEquality().equals(other._path, _path));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    conversation,
    const DeepCollectionEquality().hash(_path),
  );

  /// Create a copy of ConversationPath
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ConversationPathImplCopyWith<_$ConversationPathImpl> get copyWith =>
      __$$ConversationPathImplCopyWithImpl<_$ConversationPathImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ConversationPathImplToJson(this);
  }
}

abstract class _ConversationPath implements ConversationPath {
  const factory _ConversationPath({
    required final Conversation conversation,
    final List<MessageTreeNode> path,
  }) = _$ConversationPathImpl;

  factory _ConversationPath.fromJson(Map<String, dynamic> json) =
      _$ConversationPathImpl.fromJson;

  /// 此 path 所属的 conversation。
  @override
  Conversation get conversation;

  /// 从 root 到 current leaf 的可见 message。
  @override
  List<MessageTreeNode> get path;

  /// Create a copy of ConversationPath
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ConversationPathImplCopyWith<_$ConversationPathImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SendMessageResponse _$SendMessageResponseFromJson(Map<String, dynamic> json) {
  return _SendMessageResponse.fromJson(json);
}

/// @nodoc
mixin _$SendMessageResponse {
  /// 刚持久化的 user message。
  Message get userMessage => throw _privateConstructorUsedError;

  /// 用于接收 token stream 的空 assistant placeholder。
  Message get assistantMessage => throw _privateConstructorUsedError;

  /// Serializes this SendMessageResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SendMessageResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SendMessageResponseCopyWith<SendMessageResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SendMessageResponseCopyWith<$Res> {
  factory $SendMessageResponseCopyWith(
    SendMessageResponse value,
    $Res Function(SendMessageResponse) then,
  ) = _$SendMessageResponseCopyWithImpl<$Res, SendMessageResponse>;
  @useResult
  $Res call({Message userMessage, Message assistantMessage});

  $MessageCopyWith<$Res> get userMessage;
  $MessageCopyWith<$Res> get assistantMessage;
}

/// @nodoc
class _$SendMessageResponseCopyWithImpl<$Res, $Val extends SendMessageResponse>
    implements $SendMessageResponseCopyWith<$Res> {
  _$SendMessageResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SendMessageResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? userMessage = null, Object? assistantMessage = null}) {
    return _then(
      _value.copyWith(
            userMessage: null == userMessage
                ? _value.userMessage
                : userMessage // ignore: cast_nullable_to_non_nullable
                      as Message,
            assistantMessage: null == assistantMessage
                ? _value.assistantMessage
                : assistantMessage // ignore: cast_nullable_to_non_nullable
                      as Message,
          )
          as $Val,
    );
  }

  /// Create a copy of SendMessageResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MessageCopyWith<$Res> get userMessage {
    return $MessageCopyWith<$Res>(_value.userMessage, (value) {
      return _then(_value.copyWith(userMessage: value) as $Val);
    });
  }

  /// Create a copy of SendMessageResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MessageCopyWith<$Res> get assistantMessage {
    return $MessageCopyWith<$Res>(_value.assistantMessage, (value) {
      return _then(_value.copyWith(assistantMessage: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SendMessageResponseImplCopyWith<$Res>
    implements $SendMessageResponseCopyWith<$Res> {
  factory _$$SendMessageResponseImplCopyWith(
    _$SendMessageResponseImpl value,
    $Res Function(_$SendMessageResponseImpl) then,
  ) = __$$SendMessageResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Message userMessage, Message assistantMessage});

  @override
  $MessageCopyWith<$Res> get userMessage;
  @override
  $MessageCopyWith<$Res> get assistantMessage;
}

/// @nodoc
class __$$SendMessageResponseImplCopyWithImpl<$Res>
    extends _$SendMessageResponseCopyWithImpl<$Res, _$SendMessageResponseImpl>
    implements _$$SendMessageResponseImplCopyWith<$Res> {
  __$$SendMessageResponseImplCopyWithImpl(
    _$SendMessageResponseImpl _value,
    $Res Function(_$SendMessageResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SendMessageResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? userMessage = null, Object? assistantMessage = null}) {
    return _then(
      _$SendMessageResponseImpl(
        userMessage: null == userMessage
            ? _value.userMessage
            : userMessage // ignore: cast_nullable_to_non_nullable
                  as Message,
        assistantMessage: null == assistantMessage
            ? _value.assistantMessage
            : assistantMessage // ignore: cast_nullable_to_non_nullable
                  as Message,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SendMessageResponseImpl implements _SendMessageResponse {
  const _$SendMessageResponseImpl({
    required this.userMessage,
    required this.assistantMessage,
  });

  factory _$SendMessageResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$SendMessageResponseImplFromJson(json);

  /// 刚持久化的 user message。
  @override
  final Message userMessage;

  /// 用于接收 token stream 的空 assistant placeholder。
  @override
  final Message assistantMessage;

  @override
  String toString() {
    return 'SendMessageResponse(userMessage: $userMessage, assistantMessage: $assistantMessage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SendMessageResponseImpl &&
            (identical(other.userMessage, userMessage) ||
                other.userMessage == userMessage) &&
            (identical(other.assistantMessage, assistantMessage) ||
                other.assistantMessage == assistantMessage));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, userMessage, assistantMessage);

  /// Create a copy of SendMessageResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SendMessageResponseImplCopyWith<_$SendMessageResponseImpl> get copyWith =>
      __$$SendMessageResponseImplCopyWithImpl<_$SendMessageResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SendMessageResponseImplToJson(this);
  }
}

abstract class _SendMessageResponse implements SendMessageResponse {
  const factory _SendMessageResponse({
    required final Message userMessage,
    required final Message assistantMessage,
  }) = _$SendMessageResponseImpl;

  factory _SendMessageResponse.fromJson(Map<String, dynamic> json) =
      _$SendMessageResponseImpl.fromJson;

  /// 刚持久化的 user message。
  @override
  Message get userMessage;

  /// 用于接收 token stream 的空 assistant placeholder。
  @override
  Message get assistantMessage;

  /// Create a copy of SendMessageResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SendMessageResponseImplCopyWith<_$SendMessageResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
