// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'requests.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserMessageCreateImpl _$$UserMessageCreateImplFromJson(
  Map<String, dynamic> json,
) => _$UserMessageCreateImpl(
  parentId: (json['parent_id'] as num?)?.toInt(),
  text: json['text'] as String,
  imageData: json['image_data'] as String?,
);

Map<String, dynamic> _$$UserMessageCreateImplToJson(
  _$UserMessageCreateImpl instance,
) => <String, dynamic>{
  'parent_id': instance.parentId,
  'text': instance.text,
  'image_data': instance.imageData,
};
