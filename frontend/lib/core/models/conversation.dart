/// `Conversation` data model 及其 create/update request body。
///
/// Conversation 是属于一个 profile、并在整个生命周期内绑定单个 model 的 chat thread
///（架构决策 D03）。创建后只能修改 title 和 thinking-effort level。
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

    /// 此 conversation 的 thinking-effort level。必须是绑定 model 的 `thinking_effort` field
    /// 中列出的 level 之一。可以通过 `PATCH` 修改。
    required String thinkingEffort,

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
/// `thinkingEffort` 是 optional；省略时 backend 使用 model 的 `thinking_effort` list 中的
/// 第一个 level（决策 D05）。
@freezed
class ConversationCreate with _$ConversationCreate {
  /// 创建 request body。
  const factory ConversationCreate({
    /// 要绑定到此 conversation 的 model id。
    required String modelId,

    /// 可选的初始 title。通常在第一个 turn 前保持为空。
    @Default('') String title,

    /// 可选的 thinking-effort level。必须是 model 列出的 level 之一；`null` 表示“使用
    /// model default”。
    String? thinkingEffort,
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

    /// 要修改的新 thinking-effort level。必须是 model 支持的 level 之一。
    String? thinkingEffort,
  }) = _ConversationUpdate;

  /// 根据 JSON 重建 request body（主要用于 test）。
  factory ConversationUpdate.fromJson(Map<String, dynamic> json) =>
      _$ConversationUpdateFromJson(json);
}
