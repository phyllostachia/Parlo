// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ConversationImpl _$$ConversationImplFromJson(Map<String, dynamic> json) =>
    _$ConversationImpl(
      id: (json['id'] as num).toInt(),
      profileId: (json['profile_id'] as num).toInt(),
      title: json['title'] as String,
      modelId: json['model_id'] as String,
      thinkingEffort: json['thinking_effort'] as String,
      currentLeafId: (json['current_leaf_id'] as num?)?.toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$ConversationImplToJson(_$ConversationImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'profile_id': instance.profileId,
      'title': instance.title,
      'model_id': instance.modelId,
      'thinking_effort': instance.thinkingEffort,
      'current_leaf_id': instance.currentLeafId,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

_$ConversationCreateImpl _$$ConversationCreateImplFromJson(
  Map<String, dynamic> json,
) => _$ConversationCreateImpl(
  modelId: json['model_id'] as String,
  title: json['title'] as String? ?? '',
  thinkingEffort: json['thinking_effort'] as String?,
);

Map<String, dynamic> _$$ConversationCreateImplToJson(
  _$ConversationCreateImpl instance,
) => <String, dynamic>{
  'model_id': instance.modelId,
  'title': instance.title,
  'thinking_effort': instance.thinkingEffort,
};

_$ConversationUpdateImpl _$$ConversationUpdateImplFromJson(
  Map<String, dynamic> json,
) => _$ConversationUpdateImpl(
  title: json['title'] as String?,
  thinkingEffort: json['thinking_effort'] as String?,
);

Map<String, dynamic> _$$ConversationUpdateImplToJson(
  _$ConversationUpdateImpl instance,
) => <String, dynamic>{
  'title': instance.title,
  'thinking_effort': instance.thinkingEffort,
};
