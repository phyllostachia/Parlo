// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MessageImpl _$$MessageImplFromJson(Map<String, dynamic> json) =>
    _$MessageImpl(
      id: (json['id'] as num).toInt(),
      conversationId: (json['conversation_id'] as num).toInt(),
      parentId: (json['parent_id'] as num?)?.toInt(),
      role: $enumDecode(_$MessageRoleEnumMap, json['role']),
      content: json['content'] as String,
      reasoning: json['reasoning'] as String?,
      imageUrl: json['image_url'] as String?,
      isComplete: json['is_complete'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$MessageImplToJson(_$MessageImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'conversation_id': instance.conversationId,
      'parent_id': instance.parentId,
      'role': _$MessageRoleEnumMap[instance.role]!,
      'content': instance.content,
      'reasoning': instance.reasoning,
      'image_url': instance.imageUrl,
      'is_complete': instance.isComplete,
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$MessageRoleEnumMap = {
  MessageRole.user: 'user',
  MessageRole.assistant: 'assistant',
  MessageRole.system: 'system',
};

_$SiblingInfoImpl _$$SiblingInfoImplFromJson(Map<String, dynamic> json) =>
    _$SiblingInfoImpl(
      siblings:
          (json['siblings'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const <int>[],
      activeId: (json['active_id'] as num).toInt(),
    );

Map<String, dynamic> _$$SiblingInfoImplToJson(_$SiblingInfoImpl instance) =>
    <String, dynamic>{
      'siblings': instance.siblings,
      'active_id': instance.activeId,
    };

_$MessageTreeNodeImpl _$$MessageTreeNodeImplFromJson(
  Map<String, dynamic> json,
) => _$MessageTreeNodeImpl(
  message: Message.fromJson(json['message'] as Map<String, dynamic>),
  siblings: SiblingInfo.fromJson(json['siblings'] as Map<String, dynamic>),
);

Map<String, dynamic> _$$MessageTreeNodeImplToJson(
  _$MessageTreeNodeImpl instance,
) => <String, dynamic>{
  'message': instance.message.toJson(),
  'siblings': instance.siblings.toJson(),
};

_$ConversationPathImpl _$$ConversationPathImplFromJson(
  Map<String, dynamic> json,
) => _$ConversationPathImpl(
  conversation: Conversation.fromJson(
    json['conversation'] as Map<String, dynamic>,
  ),
  path:
      (json['path'] as List<dynamic>?)
          ?.map((e) => MessageTreeNode.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <MessageTreeNode>[],
);

Map<String, dynamic> _$$ConversationPathImplToJson(
  _$ConversationPathImpl instance,
) => <String, dynamic>{
  'conversation': instance.conversation.toJson(),
  'path': instance.path.map((e) => e.toJson()).toList(),
};

_$SendMessageResponseImpl _$$SendMessageResponseImplFromJson(
  Map<String, dynamic> json,
) => _$SendMessageResponseImpl(
  userMessage: Message.fromJson(json['user_message'] as Map<String, dynamic>),
  assistantMessage: Message.fromJson(
    json['assistant_message'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$$SendMessageResponseImplToJson(
  _$SendMessageResponseImpl instance,
) => <String, dynamic>{
  'user_message': instance.userMessage.toJson(),
  'assistant_message': instance.assistantMessage.toJson(),
};
