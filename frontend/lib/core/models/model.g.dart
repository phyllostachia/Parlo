// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ModelReadImpl _$$ModelReadImplFromJson(Map<String, dynamic> json) =>
    _$ModelReadImpl(
      id: json['id'] as String,
      displayName: json['display_name'] as String,
      family: json['family'] as String,
      protocol: json['protocol'] as String,
      vision: json['vision'] as bool,
      thinkingEffort:
          (json['thinking_effort'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
    );

Map<String, dynamic> _$$ModelReadImplToJson(_$ModelReadImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'display_name': instance.displayName,
      'family': instance.family,
      'protocol': instance.protocol,
      'vision': instance.vision,
      'thinking_effort': instance.thinkingEffort,
    };

_$ModelsResponseImpl _$$ModelsResponseImplFromJson(Map<String, dynamic> json) =>
    _$ModelsResponseImpl(
      defaultModel: json['default_model'] as String,
      models:
          (json['models'] as List<dynamic>?)
              ?.map((e) => ModelRead.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ModelRead>[],
    );

Map<String, dynamic> _$$ModelsResponseImplToJson(
  _$ModelsResponseImpl instance,
) => <String, dynamic>{
  'default_model': instance.defaultModel,
  'models': instance.models.map((e) => e.toJson()).toList(),
};
