// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sse_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$SseEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int messageId) started,
    required TResult Function(String content) textDelta,
    required TResult Function(String content) reasoningDelta,
    required TResult Function(String content) reasoningSignature,
    required TResult Function(String message) error,
    required TResult Function() done,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int messageId)? started,
    TResult? Function(String content)? textDelta,
    TResult? Function(String content)? reasoningDelta,
    TResult? Function(String content)? reasoningSignature,
    TResult? Function(String message)? error,
    TResult? Function()? done,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int messageId)? started,
    TResult Function(String content)? textDelta,
    TResult Function(String content)? reasoningDelta,
    TResult Function(String content)? reasoningSignature,
    TResult Function(String message)? error,
    TResult Function()? done,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SseStarted value) started,
    required TResult Function(SseTextDelta value) textDelta,
    required TResult Function(SseReasoningDelta value) reasoningDelta,
    required TResult Function(SseReasoningSignature value) reasoningSignature,
    required TResult Function(SseError value) error,
    required TResult Function(SseDone value) done,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SseStarted value)? started,
    TResult? Function(SseTextDelta value)? textDelta,
    TResult? Function(SseReasoningDelta value)? reasoningDelta,
    TResult? Function(SseReasoningSignature value)? reasoningSignature,
    TResult? Function(SseError value)? error,
    TResult? Function(SseDone value)? done,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SseStarted value)? started,
    TResult Function(SseTextDelta value)? textDelta,
    TResult Function(SseReasoningDelta value)? reasoningDelta,
    TResult Function(SseReasoningSignature value)? reasoningSignature,
    TResult Function(SseError value)? error,
    TResult Function(SseDone value)? done,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SseEventCopyWith<$Res> {
  factory $SseEventCopyWith(SseEvent value, $Res Function(SseEvent) then) =
      _$SseEventCopyWithImpl<$Res, SseEvent>;
}

/// @nodoc
class _$SseEventCopyWithImpl<$Res, $Val extends SseEvent>
    implements $SseEventCopyWith<$Res> {
  _$SseEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SseEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$SseStartedImplCopyWith<$Res> {
  factory _$$SseStartedImplCopyWith(
    _$SseStartedImpl value,
    $Res Function(_$SseStartedImpl) then,
  ) = __$$SseStartedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({int messageId});
}

/// @nodoc
class __$$SseStartedImplCopyWithImpl<$Res>
    extends _$SseEventCopyWithImpl<$Res, _$SseStartedImpl>
    implements _$$SseStartedImplCopyWith<$Res> {
  __$$SseStartedImplCopyWithImpl(
    _$SseStartedImpl _value,
    $Res Function(_$SseStartedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SseEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? messageId = null}) {
    return _then(
      _$SseStartedImpl(
        messageId: null == messageId
            ? _value.messageId
            : messageId // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$SseStartedImpl implements SseStarted {
  const _$SseStartedImpl({required this.messageId});

  /// The id of the assistant placeholder this stream is filling.
  @override
  final int messageId;

  @override
  String toString() {
    return 'SseEvent.started(messageId: $messageId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SseStartedImpl &&
            (identical(other.messageId, messageId) ||
                other.messageId == messageId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, messageId);

  /// Create a copy of SseEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SseStartedImplCopyWith<_$SseStartedImpl> get copyWith =>
      __$$SseStartedImplCopyWithImpl<_$SseStartedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int messageId) started,
    required TResult Function(String content) textDelta,
    required TResult Function(String content) reasoningDelta,
    required TResult Function(String content) reasoningSignature,
    required TResult Function(String message) error,
    required TResult Function() done,
  }) {
    return started(messageId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int messageId)? started,
    TResult? Function(String content)? textDelta,
    TResult? Function(String content)? reasoningDelta,
    TResult? Function(String content)? reasoningSignature,
    TResult? Function(String message)? error,
    TResult? Function()? done,
  }) {
    return started?.call(messageId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int messageId)? started,
    TResult Function(String content)? textDelta,
    TResult Function(String content)? reasoningDelta,
    TResult Function(String content)? reasoningSignature,
    TResult Function(String message)? error,
    TResult Function()? done,
    required TResult orElse(),
  }) {
    if (started != null) {
      return started(messageId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SseStarted value) started,
    required TResult Function(SseTextDelta value) textDelta,
    required TResult Function(SseReasoningDelta value) reasoningDelta,
    required TResult Function(SseReasoningSignature value) reasoningSignature,
    required TResult Function(SseError value) error,
    required TResult Function(SseDone value) done,
  }) {
    return started(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SseStarted value)? started,
    TResult? Function(SseTextDelta value)? textDelta,
    TResult? Function(SseReasoningDelta value)? reasoningDelta,
    TResult? Function(SseReasoningSignature value)? reasoningSignature,
    TResult? Function(SseError value)? error,
    TResult? Function(SseDone value)? done,
  }) {
    return started?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SseStarted value)? started,
    TResult Function(SseTextDelta value)? textDelta,
    TResult Function(SseReasoningDelta value)? reasoningDelta,
    TResult Function(SseReasoningSignature value)? reasoningSignature,
    TResult Function(SseError value)? error,
    TResult Function(SseDone value)? done,
    required TResult orElse(),
  }) {
    if (started != null) {
      return started(this);
    }
    return orElse();
  }
}

abstract class SseStarted implements SseEvent {
  const factory SseStarted({required final int messageId}) = _$SseStartedImpl;

  /// The id of the assistant placeholder this stream is filling.
  int get messageId;

  /// Create a copy of SseEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SseStartedImplCopyWith<_$SseStartedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SseTextDeltaImplCopyWith<$Res> {
  factory _$$SseTextDeltaImplCopyWith(
    _$SseTextDeltaImpl value,
    $Res Function(_$SseTextDeltaImpl) then,
  ) = __$$SseTextDeltaImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String content});
}

/// @nodoc
class __$$SseTextDeltaImplCopyWithImpl<$Res>
    extends _$SseEventCopyWithImpl<$Res, _$SseTextDeltaImpl>
    implements _$$SseTextDeltaImplCopyWith<$Res> {
  __$$SseTextDeltaImplCopyWithImpl(
    _$SseTextDeltaImpl _value,
    $Res Function(_$SseTextDeltaImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SseEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? content = null}) {
    return _then(
      _$SseTextDeltaImpl(
        content: null == content
            ? _value.content
            : content // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$SseTextDeltaImpl implements SseTextDelta {
  const _$SseTextDeltaImpl({required this.content});

  /// The text to append.
  @override
  final String content;

  @override
  String toString() {
    return 'SseEvent.textDelta(content: $content)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SseTextDeltaImpl &&
            (identical(other.content, content) || other.content == content));
  }

  @override
  int get hashCode => Object.hash(runtimeType, content);

  /// Create a copy of SseEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SseTextDeltaImplCopyWith<_$SseTextDeltaImpl> get copyWith =>
      __$$SseTextDeltaImplCopyWithImpl<_$SseTextDeltaImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int messageId) started,
    required TResult Function(String content) textDelta,
    required TResult Function(String content) reasoningDelta,
    required TResult Function(String content) reasoningSignature,
    required TResult Function(String message) error,
    required TResult Function() done,
  }) {
    return textDelta(content);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int messageId)? started,
    TResult? Function(String content)? textDelta,
    TResult? Function(String content)? reasoningDelta,
    TResult? Function(String content)? reasoningSignature,
    TResult? Function(String message)? error,
    TResult? Function()? done,
  }) {
    return textDelta?.call(content);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int messageId)? started,
    TResult Function(String content)? textDelta,
    TResult Function(String content)? reasoningDelta,
    TResult Function(String content)? reasoningSignature,
    TResult Function(String message)? error,
    TResult Function()? done,
    required TResult orElse(),
  }) {
    if (textDelta != null) {
      return textDelta(content);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SseStarted value) started,
    required TResult Function(SseTextDelta value) textDelta,
    required TResult Function(SseReasoningDelta value) reasoningDelta,
    required TResult Function(SseReasoningSignature value) reasoningSignature,
    required TResult Function(SseError value) error,
    required TResult Function(SseDone value) done,
  }) {
    return textDelta(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SseStarted value)? started,
    TResult? Function(SseTextDelta value)? textDelta,
    TResult? Function(SseReasoningDelta value)? reasoningDelta,
    TResult? Function(SseReasoningSignature value)? reasoningSignature,
    TResult? Function(SseError value)? error,
    TResult? Function(SseDone value)? done,
  }) {
    return textDelta?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SseStarted value)? started,
    TResult Function(SseTextDelta value)? textDelta,
    TResult Function(SseReasoningDelta value)? reasoningDelta,
    TResult Function(SseReasoningSignature value)? reasoningSignature,
    TResult Function(SseError value)? error,
    TResult Function(SseDone value)? done,
    required TResult orElse(),
  }) {
    if (textDelta != null) {
      return textDelta(this);
    }
    return orElse();
  }
}

abstract class SseTextDelta implements SseEvent {
  const factory SseTextDelta({required final String content}) =
      _$SseTextDeltaImpl;

  /// The text to append.
  String get content;

  /// Create a copy of SseEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SseTextDeltaImplCopyWith<_$SseTextDeltaImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SseReasoningDeltaImplCopyWith<$Res> {
  factory _$$SseReasoningDeltaImplCopyWith(
    _$SseReasoningDeltaImpl value,
    $Res Function(_$SseReasoningDeltaImpl) then,
  ) = __$$SseReasoningDeltaImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String content});
}

/// @nodoc
class __$$SseReasoningDeltaImplCopyWithImpl<$Res>
    extends _$SseEventCopyWithImpl<$Res, _$SseReasoningDeltaImpl>
    implements _$$SseReasoningDeltaImplCopyWith<$Res> {
  __$$SseReasoningDeltaImplCopyWithImpl(
    _$SseReasoningDeltaImpl _value,
    $Res Function(_$SseReasoningDeltaImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SseEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? content = null}) {
    return _then(
      _$SseReasoningDeltaImpl(
        content: null == content
            ? _value.content
            : content // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$SseReasoningDeltaImpl implements SseReasoningDelta {
  const _$SseReasoningDeltaImpl({required this.content});

  /// The reasoning text to append.
  @override
  final String content;

  @override
  String toString() {
    return 'SseEvent.reasoningDelta(content: $content)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SseReasoningDeltaImpl &&
            (identical(other.content, content) || other.content == content));
  }

  @override
  int get hashCode => Object.hash(runtimeType, content);

  /// Create a copy of SseEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SseReasoningDeltaImplCopyWith<_$SseReasoningDeltaImpl> get copyWith =>
      __$$SseReasoningDeltaImplCopyWithImpl<_$SseReasoningDeltaImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int messageId) started,
    required TResult Function(String content) textDelta,
    required TResult Function(String content) reasoningDelta,
    required TResult Function(String content) reasoningSignature,
    required TResult Function(String message) error,
    required TResult Function() done,
  }) {
    return reasoningDelta(content);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int messageId)? started,
    TResult? Function(String content)? textDelta,
    TResult? Function(String content)? reasoningDelta,
    TResult? Function(String content)? reasoningSignature,
    TResult? Function(String message)? error,
    TResult? Function()? done,
  }) {
    return reasoningDelta?.call(content);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int messageId)? started,
    TResult Function(String content)? textDelta,
    TResult Function(String content)? reasoningDelta,
    TResult Function(String content)? reasoningSignature,
    TResult Function(String message)? error,
    TResult Function()? done,
    required TResult orElse(),
  }) {
    if (reasoningDelta != null) {
      return reasoningDelta(content);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SseStarted value) started,
    required TResult Function(SseTextDelta value) textDelta,
    required TResult Function(SseReasoningDelta value) reasoningDelta,
    required TResult Function(SseReasoningSignature value) reasoningSignature,
    required TResult Function(SseError value) error,
    required TResult Function(SseDone value) done,
  }) {
    return reasoningDelta(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SseStarted value)? started,
    TResult? Function(SseTextDelta value)? textDelta,
    TResult? Function(SseReasoningDelta value)? reasoningDelta,
    TResult? Function(SseReasoningSignature value)? reasoningSignature,
    TResult? Function(SseError value)? error,
    TResult? Function(SseDone value)? done,
  }) {
    return reasoningDelta?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SseStarted value)? started,
    TResult Function(SseTextDelta value)? textDelta,
    TResult Function(SseReasoningDelta value)? reasoningDelta,
    TResult Function(SseReasoningSignature value)? reasoningSignature,
    TResult Function(SseError value)? error,
    TResult Function(SseDone value)? done,
    required TResult orElse(),
  }) {
    if (reasoningDelta != null) {
      return reasoningDelta(this);
    }
    return orElse();
  }
}

abstract class SseReasoningDelta implements SseEvent {
  const factory SseReasoningDelta({required final String content}) =
      _$SseReasoningDeltaImpl;

  /// The reasoning text to append.
  String get content;

  /// Create a copy of SseEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SseReasoningDeltaImplCopyWith<_$SseReasoningDeltaImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SseReasoningSignatureImplCopyWith<$Res> {
  factory _$$SseReasoningSignatureImplCopyWith(
    _$SseReasoningSignatureImpl value,
    $Res Function(_$SseReasoningSignatureImpl) then,
  ) = __$$SseReasoningSignatureImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String content});
}

/// @nodoc
class __$$SseReasoningSignatureImplCopyWithImpl<$Res>
    extends _$SseEventCopyWithImpl<$Res, _$SseReasoningSignatureImpl>
    implements _$$SseReasoningSignatureImplCopyWith<$Res> {
  __$$SseReasoningSignatureImplCopyWithImpl(
    _$SseReasoningSignatureImpl _value,
    $Res Function(_$SseReasoningSignatureImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SseEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? content = null}) {
    return _then(
      _$SseReasoningSignatureImpl(
        content: null == content
            ? _value.content
            : content // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$SseReasoningSignatureImpl implements SseReasoningSignature {
  const _$SseReasoningSignatureImpl({required this.content});

  /// The signature string.
  @override
  final String content;

  @override
  String toString() {
    return 'SseEvent.reasoningSignature(content: $content)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SseReasoningSignatureImpl &&
            (identical(other.content, content) || other.content == content));
  }

  @override
  int get hashCode => Object.hash(runtimeType, content);

  /// Create a copy of SseEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SseReasoningSignatureImplCopyWith<_$SseReasoningSignatureImpl>
  get copyWith =>
      __$$SseReasoningSignatureImplCopyWithImpl<_$SseReasoningSignatureImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int messageId) started,
    required TResult Function(String content) textDelta,
    required TResult Function(String content) reasoningDelta,
    required TResult Function(String content) reasoningSignature,
    required TResult Function(String message) error,
    required TResult Function() done,
  }) {
    return reasoningSignature(content);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int messageId)? started,
    TResult? Function(String content)? textDelta,
    TResult? Function(String content)? reasoningDelta,
    TResult? Function(String content)? reasoningSignature,
    TResult? Function(String message)? error,
    TResult? Function()? done,
  }) {
    return reasoningSignature?.call(content);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int messageId)? started,
    TResult Function(String content)? textDelta,
    TResult Function(String content)? reasoningDelta,
    TResult Function(String content)? reasoningSignature,
    TResult Function(String message)? error,
    TResult Function()? done,
    required TResult orElse(),
  }) {
    if (reasoningSignature != null) {
      return reasoningSignature(content);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SseStarted value) started,
    required TResult Function(SseTextDelta value) textDelta,
    required TResult Function(SseReasoningDelta value) reasoningDelta,
    required TResult Function(SseReasoningSignature value) reasoningSignature,
    required TResult Function(SseError value) error,
    required TResult Function(SseDone value) done,
  }) {
    return reasoningSignature(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SseStarted value)? started,
    TResult? Function(SseTextDelta value)? textDelta,
    TResult? Function(SseReasoningDelta value)? reasoningDelta,
    TResult? Function(SseReasoningSignature value)? reasoningSignature,
    TResult? Function(SseError value)? error,
    TResult? Function(SseDone value)? done,
  }) {
    return reasoningSignature?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SseStarted value)? started,
    TResult Function(SseTextDelta value)? textDelta,
    TResult Function(SseReasoningDelta value)? reasoningDelta,
    TResult Function(SseReasoningSignature value)? reasoningSignature,
    TResult Function(SseError value)? error,
    TResult Function(SseDone value)? done,
    required TResult orElse(),
  }) {
    if (reasoningSignature != null) {
      return reasoningSignature(this);
    }
    return orElse();
  }
}

abstract class SseReasoningSignature implements SseEvent {
  const factory SseReasoningSignature({required final String content}) =
      _$SseReasoningSignatureImpl;

  /// The signature string.
  String get content;

  /// Create a copy of SseEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SseReasoningSignatureImplCopyWith<_$SseReasoningSignatureImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SseErrorImplCopyWith<$Res> {
  factory _$$SseErrorImplCopyWith(
    _$SseErrorImpl value,
    $Res Function(_$SseErrorImpl) then,
  ) = __$$SseErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$SseErrorImplCopyWithImpl<$Res>
    extends _$SseEventCopyWithImpl<$Res, _$SseErrorImpl>
    implements _$$SseErrorImplCopyWith<$Res> {
  __$$SseErrorImplCopyWithImpl(
    _$SseErrorImpl _value,
    $Res Function(_$SseErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SseEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$SseErrorImpl(
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$SseErrorImpl implements SseError {
  const _$SseErrorImpl({required this.message});

  /// A human-readable error message.
  @override
  final String message;

  @override
  String toString() {
    return 'SseEvent.error(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SseErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of SseEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SseErrorImplCopyWith<_$SseErrorImpl> get copyWith =>
      __$$SseErrorImplCopyWithImpl<_$SseErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int messageId) started,
    required TResult Function(String content) textDelta,
    required TResult Function(String content) reasoningDelta,
    required TResult Function(String content) reasoningSignature,
    required TResult Function(String message) error,
    required TResult Function() done,
  }) {
    return error(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int messageId)? started,
    TResult? Function(String content)? textDelta,
    TResult? Function(String content)? reasoningDelta,
    TResult? Function(String content)? reasoningSignature,
    TResult? Function(String message)? error,
    TResult? Function()? done,
  }) {
    return error?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int messageId)? started,
    TResult Function(String content)? textDelta,
    TResult Function(String content)? reasoningDelta,
    TResult Function(String content)? reasoningSignature,
    TResult Function(String message)? error,
    TResult Function()? done,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SseStarted value) started,
    required TResult Function(SseTextDelta value) textDelta,
    required TResult Function(SseReasoningDelta value) reasoningDelta,
    required TResult Function(SseReasoningSignature value) reasoningSignature,
    required TResult Function(SseError value) error,
    required TResult Function(SseDone value) done,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SseStarted value)? started,
    TResult? Function(SseTextDelta value)? textDelta,
    TResult? Function(SseReasoningDelta value)? reasoningDelta,
    TResult? Function(SseReasoningSignature value)? reasoningSignature,
    TResult? Function(SseError value)? error,
    TResult? Function(SseDone value)? done,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SseStarted value)? started,
    TResult Function(SseTextDelta value)? textDelta,
    TResult Function(SseReasoningDelta value)? reasoningDelta,
    TResult Function(SseReasoningSignature value)? reasoningSignature,
    TResult Function(SseError value)? error,
    TResult Function(SseDone value)? done,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class SseError implements SseEvent {
  const factory SseError({required final String message}) = _$SseErrorImpl;

  /// A human-readable error message.
  String get message;

  /// Create a copy of SseEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SseErrorImplCopyWith<_$SseErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SseDoneImplCopyWith<$Res> {
  factory _$$SseDoneImplCopyWith(
    _$SseDoneImpl value,
    $Res Function(_$SseDoneImpl) then,
  ) = __$$SseDoneImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$SseDoneImplCopyWithImpl<$Res>
    extends _$SseEventCopyWithImpl<$Res, _$SseDoneImpl>
    implements _$$SseDoneImplCopyWith<$Res> {
  __$$SseDoneImplCopyWithImpl(
    _$SseDoneImpl _value,
    $Res Function(_$SseDoneImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SseEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$SseDoneImpl implements SseDone {
  const _$SseDoneImpl();

  @override
  String toString() {
    return 'SseEvent.done()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$SseDoneImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int messageId) started,
    required TResult Function(String content) textDelta,
    required TResult Function(String content) reasoningDelta,
    required TResult Function(String content) reasoningSignature,
    required TResult Function(String message) error,
    required TResult Function() done,
  }) {
    return done();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int messageId)? started,
    TResult? Function(String content)? textDelta,
    TResult? Function(String content)? reasoningDelta,
    TResult? Function(String content)? reasoningSignature,
    TResult? Function(String message)? error,
    TResult? Function()? done,
  }) {
    return done?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int messageId)? started,
    TResult Function(String content)? textDelta,
    TResult Function(String content)? reasoningDelta,
    TResult Function(String content)? reasoningSignature,
    TResult Function(String message)? error,
    TResult Function()? done,
    required TResult orElse(),
  }) {
    if (done != null) {
      return done();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SseStarted value) started,
    required TResult Function(SseTextDelta value) textDelta,
    required TResult Function(SseReasoningDelta value) reasoningDelta,
    required TResult Function(SseReasoningSignature value) reasoningSignature,
    required TResult Function(SseError value) error,
    required TResult Function(SseDone value) done,
  }) {
    return done(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SseStarted value)? started,
    TResult? Function(SseTextDelta value)? textDelta,
    TResult? Function(SseReasoningDelta value)? reasoningDelta,
    TResult? Function(SseReasoningSignature value)? reasoningSignature,
    TResult? Function(SseError value)? error,
    TResult? Function(SseDone value)? done,
  }) {
    return done?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SseStarted value)? started,
    TResult Function(SseTextDelta value)? textDelta,
    TResult Function(SseReasoningDelta value)? reasoningDelta,
    TResult Function(SseReasoningSignature value)? reasoningSignature,
    TResult Function(SseError value)? error,
    TResult Function(SseDone value)? done,
    required TResult orElse(),
  }) {
    if (done != null) {
      return done(this);
    }
    return orElse();
  }
}

abstract class SseDone implements SseEvent {
  const factory SseDone() = _$SseDoneImpl;
}
