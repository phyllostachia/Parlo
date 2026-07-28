/// Message tree data model。
///
/// Message 会在 conversation 中组成一棵 tree（架构决策 D18）。可见 path 是从 root 到
/// conversation current leaf 的 chain。同一 parent 下的 sibling message 是 alternative
/// reply；在它们之间切换就是移动 conversation 的 `current_leaf_id`。
///
/// 此文件还定义 `SendMessageResponse`，即 `POST /api/conversations/{id}/messages` 返回的
/// body。它将新的 user message 与刚创建的 assistant placeholder 组合起来，客户端随后
/// 通过 `GET /api/chat/stream` 将 token stream 到其中。
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import 'conversation.dart';

part 'message.freezed.dart';
part 'message.g.dart';

/// Message 在 conversation 中扮演的 role。
///
/// Frontend 会按 role 使用不同方式渲染 message（user message 使用 bubble，assistant message
/// 使用 markdown block，system 很少出现）。此 enum 上 `switch` 的 exhaustiveness check
/// 提供真实保护，因此架构选择将 role 作为 enum field（D4.3）。
enum MessageRole {
  /// User 输入的 message。
  user,

  /// Model 生成的 reply。
  assistant,

  /// System-level message。UI 中很少出现；为完整性而包含。
  system;

  /// 从 backend string 解析 role。未知 value 回退到 [system]，使 UI 不会因未来增加 role
  /// 而崩溃。
  static MessageRole fromString(String value) {
    switch (value) {
      case 'user':
        return MessageRole.user;
      case 'assistant':
        return MessageRole.assistant;
      default:
        return MessageRole.system;
    }
  }
}

/// Conversation tree 中的单个 message node。
///
/// Root message 的 `parentId` 为 `null`。Server 仍在向 message streaming token 时，
/// `isComplete` 为 `false`，因此 UI 可以显示 loading state。`imageUrl` 是客户端获取附加
/// image 的 path（如果存在）。
@freezed
class Message with _$Message {
  /// 创建 message。
  const factory Message({
    /// Server 分配的 identifier。
    required int id,

    /// 此 message 所属的 conversation。
    required int conversationId,

    /// Parent message id；root message 为 `null`。
    required int? parentId,

    /// 生成此 message 的 role。
    required MessageRole role,

    /// Text body。Assistant 仍在 streaming 时为空。
    required String content,

    /// Model 的 reasoning（“thinking” trace，如果有）。User message 以及 model 未生成
    /// reasoning 的 assistant message 为 `null`。
    required String? reasoning,

    /// 从开始请求到 reasoning 完成的耗时。没有 reasoning 的 message 为 `null`。
    int? reasoningDurationMs,

    /// Client 可以获取附加 image 的 URL（如果有）。`null` 表示没有 image。
    required String? imageUrl,

    /// Server 仍向此 message streaming token 时为 `false`。注意：backend 在 `finally` block
    /// 中将其设为 `true`，因此 broken stream 也会以 `is_complete = true` 结束。Frontend
    /// 维护自己的 [StreamState] 来区分二者（架构 §5.4）。
    required bool isComplete,

    /// Message 创建时间。
    required DateTime createdAt,
  }) = _Message;

  /// 根据 backend 返回的 JSON 重建 message。
  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);
}

/// 可见 path 上某个 node 的 sibling message metadata。
///
/// 使客户端无需获取整棵 tree 就能渲染 `< n / m >` version switcher。`siblings` 列出与该
/// node 共享 `parent_id` 的所有 message（包括该 node）；`activeId` 是当前可见 path 进入的
/// message。
@freezed
class SiblingInfo with _$SiblingInfo {
  /// 创建 sibling metadata。
  const factory SiblingInfo({
    /// 与该 node 的 parent 共享的所有 message id，包括该 node。
    @Default(<int>[]) List<int> siblings,

    /// 当前可见 path 经过的 sibling id。
    required int activeId,
  }) = _SiblingInfo;

  /// 根据 JSON 重建 sibling metadata。
  factory SiblingInfo.fromJson(Map<String, dynamic> json) =>
      _$SiblingInfoFromJson(json);
}

/// 可见 path 上的一条 message 及其 sibling metadata。
@freezed
class MessageTreeNode with _$MessageTreeNode {
  /// 创建 tree node。
  const factory MessageTreeNode({
    /// Path 此位置上的 message。
    required Message message,

    /// 用于渲染 version switcher 的 sibling metadata。
    required SiblingInfo siblings,
  }) = _MessageTreeNode;

  /// 根据 JSON 重建 tree node。
  factory MessageTreeNode.fromJson(Map<String, dynamic> json) =>
      _$MessageTreeNodeFromJson(json);
}

/// conversation 的可见 message path，按 root → current leaf 排序。
///
/// 这是 chat screen 用于渲染的 single source of truth。每个 entry 都是 [MessageTreeNode]，
/// 因此 version switcher 可以出现在 path 的任意 level，而不只是 leaf。
@freezed
class ConversationPath with _$ConversationPath {
  /// 创建 conversation path。
  const factory ConversationPath({
    /// 此 path 所属的 conversation。
    required Conversation conversation,

    /// 从 root 到 current leaf 的可见 message。
    @Default(<MessageTreeNode>[]) List<MessageTreeNode> path,
  }) = _ConversationPath;

  /// 根据 backend 返回的 JSON 重建 path。
  factory ConversationPath.fromJson(Map<String, dynamic> json) =>
      _$ConversationPathFromJson(json);
}

/// `POST /api/conversations/{id}/messages` 的 response。
///
/// 将刚创建的 user message 与刚创建的 assistant placeholder 组合起来，客户端应通过
/// `GET /api/chat/stream?message_id=...` 将 token stream 到 placeholder。
@freezed
class SendMessageResponse with _$SendMessageResponse {
  /// 创建 response wrapper。
  const factory SendMessageResponse({
    /// 刚持久化的 user message。
    required Message userMessage,

    /// 用于接收 token stream 的空 assistant placeholder。
    required Message assistantMessage,
  }) = _SendMessageResponse;

  /// 根据 JSON 重建 response wrapper。
  factory SendMessageResponse.fromJson(Map<String, dynamic> json) =>
      _$SendMessageResponseFromJson(json);
}
