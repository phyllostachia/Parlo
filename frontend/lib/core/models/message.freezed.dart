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
  /// The server-assigned identifier.
  int get id => throw _privateConstructorUsedError;

  /// The conversation this message belongs to.
  int get conversationId => throw _privateConstructorUsedError;

  /// The parent message id, or `null` for a root message.
  int? get parentId => throw _privateConstructorUsedError;

  /// Who produced this message.
  MessageRole get role => throw _privateConstructorUsedError;

  /// The text body. Empty while the assistant is still streaming.
  String get content => throw _privateConstructorUsedError;

  /// The model's reasoning (the "thinking" trace), if any. `null` for user
  /// messages and for assistant messages whose model produced none.
  String? get reasoning => throw _privateConstructorUsedError;

  /// The URL the client can fetch the attached image from, if any. `null`
  /// means no image.
  String? get imageUrl => throw _privateConstructorUsedError;

  /// `false` while the server is still streaming tokens into this message.
  /// Note: the backend sets this to `true` in its `finally` block, so a
  /// broken stream also ends with `is_complete = true`. The frontend keeps
  /// its own [StreamState] to tell the difference (architecture §5.4).
  bool get isComplete => throw _privateConstructorUsedError;

  /// When the message was created.
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
    required this.imageUrl,
    required this.isComplete,
    required this.createdAt,
  });

  factory _$MessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$MessageImplFromJson(json);

  /// The server-assigned identifier.
  @override
  final int id;

  /// The conversation this message belongs to.
  @override
  final int conversationId;

  /// The parent message id, or `null` for a root message.
  @override
  final int? parentId;

  /// Who produced this message.
  @override
  final MessageRole role;

  /// The text body. Empty while the assistant is still streaming.
  @override
  final String content;

  /// The model's reasoning (the "thinking" trace), if any. `null` for user
  /// messages and for assistant messages whose model produced none.
  @override
  final String? reasoning;

  /// The URL the client can fetch the attached image from, if any. `null`
  /// means no image.
  @override
  final String? imageUrl;

  /// `false` while the server is still streaming tokens into this message.
  /// Note: the backend sets this to `true` in its `finally` block, so a
  /// broken stream also ends with `is_complete = true`. The frontend keeps
  /// its own [StreamState] to tell the difference (architecture §5.4).
  @override
  final bool isComplete;

  /// When the message was created.
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'Message(id: $id, conversationId: $conversationId, parentId: $parentId, role: $role, content: $content, reasoning: $reasoning, imageUrl: $imageUrl, isComplete: $isComplete, createdAt: $createdAt)';
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
    required final String? imageUrl,
    required final bool isComplete,
    required final DateTime createdAt,
  }) = _$MessageImpl;

  factory _Message.fromJson(Map<String, dynamic> json) = _$MessageImpl.fromJson;

  /// The server-assigned identifier.
  @override
  int get id;

  /// The conversation this message belongs to.
  @override
  int get conversationId;

  /// The parent message id, or `null` for a root message.
  @override
  int? get parentId;

  /// Who produced this message.
  @override
  MessageRole get role;

  /// The text body. Empty while the assistant is still streaming.
  @override
  String get content;

  /// The model's reasoning (the "thinking" trace), if any. `null` for user
  /// messages and for assistant messages whose model produced none.
  @override
  String? get reasoning;

  /// The URL the client can fetch the attached image from, if any. `null`
  /// means no image.
  @override
  String? get imageUrl;

  /// `false` while the server is still streaming tokens into this message.
  /// Note: the backend sets this to `true` in its `finally` block, so a
  /// broken stream also ends with `is_complete = true`. The frontend keeps
  /// its own [StreamState] to tell the difference (architecture §5.4).
  @override
  bool get isComplete;

  /// When the message was created.
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
  /// All message ids that share this node's parent, including this node.
  List<int> get siblings => throw _privateConstructorUsedError;

  /// The id of the sibling the visible path currently goes through.
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

  /// All message ids that share this node's parent, including this node.
  final List<int> _siblings;

  /// All message ids that share this node's parent, including this node.
  @override
  @JsonKey()
  List<int> get siblings {
    if (_siblings is EqualUnmodifiableListView) return _siblings;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_siblings);
  }

  /// The id of the sibling the visible path currently goes through.
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

  /// All message ids that share this node's parent, including this node.
  @override
  List<int> get siblings;

  /// The id of the sibling the visible path currently goes through.
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
  /// The message at this position on the path.
  Message get message => throw _privateConstructorUsedError;

  /// The sibling metadata used to render the version switcher.
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

  /// The message at this position on the path.
  @override
  final Message message;

  /// The sibling metadata used to render the version switcher.
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

  /// The message at this position on the path.
  @override
  Message get message;

  /// The sibling metadata used to render the version switcher.
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
  /// The conversation this path belongs to.
  Conversation get conversation => throw _privateConstructorUsedError;

  /// The visible messages, from root to the current leaf.
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

  /// The conversation this path belongs to.
  @override
  final Conversation conversation;

  /// The visible messages, from root to the current leaf.
  final List<MessageTreeNode> _path;

  /// The visible messages, from root to the current leaf.
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

  /// The conversation this path belongs to.
  @override
  Conversation get conversation;

  /// The visible messages, from root to the current leaf.
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
  /// The user message that was just persisted.
  Message get userMessage => throw _privateConstructorUsedError;

  /// The empty assistant placeholder to stream tokens into.
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

  /// The user message that was just persisted.
  @override
  final Message userMessage;

  /// The empty assistant placeholder to stream tokens into.
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

  /// The user message that was just persisted.
  @override
  Message get userMessage;

  /// The empty assistant placeholder to stream tokens into.
  @override
  Message get assistantMessage;

  /// Create a copy of SendMessageResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SendMessageResponseImplCopyWith<_$SendMessageResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
