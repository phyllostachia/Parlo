/// `Conversation` data model 及其 create/update request body。
///
/// Conversation 是属于一个 profile、并在整个生命周期内绑定单个 model 的 chat thread
///（架构决策 D03）。创建后只能修改 title 和深度思考开关。
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'conversation.freezed.dart';
part 'conversation.g.dart';

/// Profile 内绑定单个 model 的 chat thread。
///
/// `currentLeafId` 指向可见 path 上的最后一条 message；server 从该 leaf 沿 `parent_id`
/// 回溯到 root 来重建 path。`null` 表示 conversation 还没有 message。
@freezed
class Conversation with _$Conversation {
  /// 创建 conversation。
  const factory Conversation({
    /// Server 分配的 identifier，用于 `/c/{id}` URL。
    required int id,

    /// 此 conversation 所属的 profile。
    required int profileId,

    /// 可读的 title。发送第一条 message 前为空。
    required String title,

    /// `config.yaml` 中的 model id。创建时固定；如需使用其他 model，请创建新 conversation。
    required String modelId,

    /// 此 conversation 是否启用深度思考。上游 effort 由 backend 的 model 配置解析。
    required bool thinkingEnabled,

    /// 可见 path 上最后一条 message 的 id；conversation 尚无 message 时为 `null`。
    required int? currentLeafId,

    /// Conversation 创建时间。
    required DateTime createdAt,

    /// Conversation 最近更新时间。用于 sidebar sorting。
    required DateTime updatedAt,
  }) = _Conversation;

  /// 根据 backend 返回的 JSON 重建 conversation。
  factory Conversation.fromJson(Map<String, dynamic> json) =>
      _$ConversationFromJson(json);
}

/// `POST /api/profiles/{id}/conversations` request 的 body。
///
/// `thinkingEnabled` 默认关闭；backend 会根据此开关选择模型配置的对应 effort。
@freezed
class ConversationCreate with _$ConversationCreate {
  /// 创建 request body。
  const factory ConversationCreate({
    /// 要绑定到此 conversation 的 model id。
    required String modelId,

    /// 可选的初始 title。通常在第一个 turn 前保持为空。
    @Default('') String title,

    /// 是否为新会话开启深度思考。
    @Default(false) bool thinkingEnabled,
  }) = _ConversationCreate;

  /// 根据 JSON 重建 request body（主要用于 test）。
  factory ConversationCreate.fromJson(Map<String, dynamic> json) =>
      _$ConversationCreateFromJson(json);
}

/// `PATCH /api/conversations/{id}` request 的 body。
///
/// 两个 field 都是 optional。Server 只应用实际提供的 field。这里有意不包含 `modelId`，
/// 因为 model 在 conversation 生命周期内固定（决策 D09）。
@freezed
class ConversationUpdate with _$ConversationUpdate {
  /// 创建 request body。
  const factory ConversationUpdate({
    /// 要修改的新 title。
    String? title,

    /// 要修改的深度思考开关；`null` 表示不变。
    bool? thinkingEnabled,
  }) = _ConversationUpdate;

  /// 根据 JSON 重建 request body（主要用于 test）。
  factory ConversationUpdate.fromJson(Map<String, dynamic> json) =>
      _$ConversationUpdateFromJson(json);
}
