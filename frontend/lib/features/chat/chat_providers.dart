/// 支撑 chat screen 的 Riverpod provider 和 notifier。
///
/// 核心是 [CurrentConversationNotifier]，它是以 conversation id 为 key 的 family
/// [AsyncNotifier]。它拥有 visible message path 和正在处理的 Server-Sent Events subscription。
/// Send / stop 是 notifier 上的 action；SSE stream 是 send 的 side effect，而不是独立的
/// state source（架构 §3.1）。
///
/// Empty state（阶段 3）使用 [ChatActionsNotifier.sendFirstMessage] 创建 conversation，并
/// queue assistant placeholder 以便 streaming。Chat screen 的 notifier 在 mount 时打开
/// stream，因此 streaming state 会跨越从 empty state 到 `/c/{id}` 的 navigation。
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/models/conversation.dart';
import '../../core/models/message.dart';
import '../../core/models/model.dart';
import '../../core/models/requests.dart';
import '../../core/models/sse_event.dart';
import '../../core/network/api_client.dart';
import '../../core/network/sse_connection.dart';
import '../../core/network/sse_parser.dart';
import '../sidebar/sidebar_providers.dart';

/// Assistant stream 的 local state。
///
/// 无论 stream 如何结束，backend 都会在 `finally` block 中将 `is_complete` flag 设为 `true`，
/// 因此 frontend 仅凭 `is_complete` 无法区分正常完成和 connection drop。此 enum 是 local
/// truth（架构 §5.4）。
enum StreamState {
  /// 此 session 中尚未运行 stream。
  idle,

  /// Backend 正在发送 token。
  streaming,

  /// User 按下 stop。Assistant message 保留目前已经收到的 content。
  stopped,

  /// Stream drop 或 backend 发送了 `error` event。UI 显示“connection broken, retry” button。
  error,

  /// Stream 正常完成。Assistant message 已完成。
  done,
}

/// Model registry（`GET /api/models`）。
class ModelsNotifier extends AsyncNotifier<ModelsResponse?> {
  @override
  Future<ModelsResponse?> build() async {
    final dio = ref.read(dioProvider);
    final response = await dio.get<Map<String, dynamic>>('/api/models');
    if (response.data == null) return null;
    return ModelsResponse.fromJson(response.data!);
  }

  /// 强制 refetch model list。
  void refresh() => ref.invalidateSelf();
}

/// 完整 models response（default + list）。
final modelsProvider = AsyncNotifierProvider<ModelsNotifier, ModelsResponse?>(
  ModelsNotifier.new,
);

/// 从 [modelsProvider] 派生的 flat model list。Loading 时为空。
final modelListProvider = Provider<List<ModelRead>>((ref) {
  return ref.watch(modelsProvider).valueOrNull?.models ?? const <ModelRead>[];
});

/// 从 [modelsProvider] 派生的已配置 default model id。
final defaultModelIdProvider = Provider<String?>((ref) {
  return ref.watch(modelsProvider).valueOrNull?.defaultModel;
});

/// 当前查看 conversation 的 stream state。
///
/// 这是 singleton，因为一次只查看一个 conversation。Conversation notifier build 时会将其
/// reset 为 [StreamState.idle]。
final streamStateProvider = StateProvider<StreamState>((ref) {
  return StreamState.idle;
});

/// 由 empty state first-send 设置、并由 chat notifier build 消费的 pending request，表示
///“chat screen mount 时打开此 stream”。
///
/// Record 是 `(conversationId, messageId)`，因此 chat notifier 在打开前可以验证 pending
/// stream 是否属于当前 conversation。
final pendingStreamProvider =
    StateProvider<({int conversationId, int messageId})?>((ref) {
      return null;
    });

/// 一个 conversation 的 visible message path，以及 send / stop action。
///
/// User 离开 conversation 时会 auto-dispose，使 SSE subscription 被正确取消。`build` method
/// 还会打开 pending stream（由 empty state 设置），使 streaming 在 chat screen mount 后立即开始。
class CurrentConversationNotifier
    extends AutoDisposeFamilyAsyncNotifier<ConversationPath, int> {
  /// 正在运行的 SSE subscription；没有 stream 运行时为 `null`。
  StreamSubscription<SseEvent>? _sub;

  @override
  Future<ConversationPath> build(int conversationId) async {
    // 取消复用 notifier instance 中可能存在的 previous stream。
    await _sub?.cancel();
    _sub = null;
    ref.read(streamStateProvider.notifier).state = StreamState.idle;

    // Notifier dispose 时取消 stream（用户离开 page）。
    ref.onDispose(() {
      _sub?.cancel();
      _sub = null;
    });

    final dio = ref.read(dioProvider);
    final response = await dio.get<Map<String, dynamic>>(
      '/api/conversations/$conversationId/messages',
    );
    final path = ConversationPath.fromJson(response.data!);

    // 如果 empty state 为此 conversation queue 了 stream，现在打开它。
    final pending = ref.read(pendingStreamProvider);
    if (pending != null && pending.conversationId == conversationId) {
      ref.read(pendingStreamProvider.notifier).state = null;
      unawaited(_openStream(pending.messageId));
    }
    return path;
  }

  /// 发送 user message，并为新的 assistant reply 打开 SSE。
  ///
  /// Backend 在一次 call 中同时创建 user message 和空 assistant placeholder；我们立即将
  /// 二者追加到 local path，使 UI 无需等待 refetch 即可显示它们，然后将 token stream 到
  /// assistant placeholder。
  Future<void> send({required String text, String? imageData}) async {
    if (ref.read(streamStateProvider) == StreamState.streaming) return;

    final conversationId = arg;
    final dio = ref.read(dioProvider);

    // 需要 current path 才能追加内容。如果 build 已完成，`future` 会立即 resolve。
    final current = await future;

    final body = UserMessageCreate(text: text, imageData: imageData).toJson();
    final response = await dio.post<Map<String, dynamic>>(
      '/api/conversations/$conversationId/messages',
      data: body,
    );
    final sendMessage = SendMessageResponse.fromJson(response.data!);

    final userNode = MessageTreeNode(
      message: sendMessage.userMessage,
      siblings: SiblingInfo(
        siblings: <int>[sendMessage.userMessage.id],
        activeId: sendMessage.userMessage.id,
      ),
    );
    final assistantNode = MessageTreeNode(
      message: sendMessage.assistantMessage,
      siblings: SiblingInfo(
        siblings: <int>[sendMessage.assistantMessage.id],
        activeId: sendMessage.assistantMessage.id,
      ),
    );

    state = AsyncData(
      current.copyWith(
        path: <MessageTreeNode>[...current.path, userNode, assistantNode],
      ),
    );

    unawaited(_openStream(sendMessage.assistantMessage.id));
  }

  /// 停止正在处理的 stream。Assistant message 保留 partial content；local stream state 设置
  /// 为 [StreamState.stopped]。
  Future<void> stop() async {
    // 在取消 subscription 之前将 state 设置为 `stopped`。Stream 的 `onDone` callback 会在
    // `cancel` 期间触发，否则它会看到 `streaming` 并将 state 覆盖为 `error`。
    ref.read(streamStateProvider.notifier).state = StreamState.stopped;
    await _sub?.cancel();
    _sub = null;
    _markAssistantComplete();
  }

  /// 重新生成 assistant reply。
  ///
  /// Backend 创建一个作为 [assistantMessageId] sibling 的新空 assistant placeholder（二者
  /// 共享同一个 parent user message），将 conversation current leaf 移动到 placeholder，
  /// 并返回 placeholder。此 notifier 在 visible path 上用新 placeholder 替换旧 assistant
  /// node，记录新的 sibling id，使 version switcher 能切回旧 reply，并打开 SSE stream 填充
  /// placeholder。
  ///
  /// Regenerate middle assistant 会缩短 visible path：新 placeholder 的 parent 之后的每条
  /// message 仍留在 tree 中，但在用户切回该 branch 前不再位于 visible path。
  ///
  /// `retry`（用于 broken 或 stopped stream）使用同一个 call：创建新 sibling，并将 broken
  /// partial reply 保留为可切回的 sibling（架构 §5.4 和 §7）。
  Future<void> regenerate({required int assistantMessageId}) async {
    if (ref.read(streamStateProvider) == StreamState.streaming) return;

    final conversationId = arg;
    final current = await future;
    final index = current.path.indexWhere(
      (node) => node.message.id == assistantMessageId,
    );
    if (index == -1) return;
    final oldNode = current.path[index];
    if (oldNode.message.role != MessageRole.assistant) return;
    final parentId = oldNode.message.parentId;
    if (parentId == null) return;

    final dio = ref.read(dioProvider);
    final response = await dio.post<Map<String, dynamic>>(
      '/api/conversations/$conversationId/messages/$parentId/regenerate',
    );
    final newAssistant = Message.fromJson(response.data!);

    // 构建新的 visible path：保留旧 assistant 之前的每个 node（包括 parent user message），
    // 然后追加新 placeholder。旧 assistant 及其 descendants 离开 visible path，但仍保留在 tree 中。
    final newNode = MessageTreeNode(
      message: newAssistant,
      siblings: SiblingInfo(
        siblings: <int>[...oldNode.siblings.siblings, newAssistant.id],
        activeId: newAssistant.id,
      ),
    );
    final newPath = <MessageTreeNode>[
      ...current.path.sublist(0, index),
      newNode,
    ];
    state = AsyncData(current.copyWith(path: newPath));

    unawaited(_openStream(newAssistant.id));
  }

  /// 将 visible path 切换为以给定 leaf message 结束。
  ///
  /// Backend 将 conversation 的 `current_leaf_id` 移动到 [leafId]，并返回带有每个 node 的
  /// 最新 sibling metadata 的完整 path。此 notifier 用该 path 替换自身 state。不打开 SSE
  /// stream，因为切换到的 message 已经完成。
  Future<void> switchBranch({required int leafId}) async {
    if (ref.read(streamStateProvider) == StreamState.streaming) return;

    final conversationId = arg;
    final dio = ref.read(dioProvider);
    final response = await dio.post<Map<String, dynamic>>(
      '/api/conversations/$conversationId/messages/$leafId/switch',
    );
    final newPath = ConversationPath.fromJson(response.data!);
    state = AsyncData(newPath);
  }

  /// 为给定 assistant message id 打开 SSE，并在每个 event 到达时 patch local path。
  Future<void> _openStream(int assistantMessageId) async {
    await _sub?.cancel();
    final dio = ref.read(dioProvider);
    final authStore = ref.read(authStoreProvider);

    try {
      final byteStream = await openSseByteStream(
        dio: dio,
        messageId: assistantMessageId,
        bearerToken: authStore.read(),
        onUnauthorized: authStore.markUnauthorized,
      );
      ref.read(streamStateProvider.notifier).state = StreamState.streaming;
      _sub = parseSseStream(byteStream).listen(
        _onEvent,
        onError: (Object error) {
          ref.read(streamStateProvider.notifier).state = StreamState.error;
          _sub = null;
        },
        onDone: () {
          // 如果 stream 在没有 `done` event 的情况下关闭，则视为 drop。
          if (ref.read(streamStateProvider) == StreamState.streaming) {
            ref.read(streamStateProvider.notifier).state = StreamState.error;
          }
          _sub = null;
        },
        cancelOnError: false,
      );
    } catch (_) {
      ref.read(streamStateProvider.notifier).state = StreamState.error;
    }
  }

  void _onEvent(SseEvent event) {
    switch (event) {
      case SseStarted():
        ref.read(streamStateProvider.notifier).state = StreamState.streaming;
      case SseTextDelta(:final content):
        _appendAssistantContent(content);
      case SseReasoningDelta(:final content):
        _appendAssistantReasoning(content);
      case SseReasoningSignature():
        // Backend 会在后续 turn replay signature；UI 不显示它。这里无需处理。
        break;
      case SseError():
        ref.read(streamStateProvider.notifier).state = StreamState.error;
        _sub?.cancel();
        _sub = null;
      case SseDone(:final reasoningDurationMs):
        _markAssistantComplete(reasoningDurationMs: reasoningDurationMs);
        ref.read(streamStateProvider.notifier).state = StreamState.done;
        _sub?.cancel();
        _sub = null;
    }
  }

  /// 将 text 追加到最后一条 assistant message 的 `content`。
  void _appendAssistantContent(String delta) {
    _patchLastAssistant(
      (message) => message.copyWith(content: message.content + delta),
    );
  }

  /// 将 text 追加到最后一条 assistant message 的 `reasoning`。
  void _appendAssistantReasoning(String delta) {
    _patchLastAssistant(
      (message) =>
          message.copyWith(reasoning: (message.reasoning ?? '') + delta),
    );
  }

  /// 将最后一条 assistant message 标记为 complete。
  void _markAssistantComplete({int? reasoningDurationMs}) {
    _patchLastAssistant((message) {
      if (reasoningDurationMs == null) {
        return message.copyWith(isComplete: true);
      }
      return message.copyWith(
        isComplete: true,
        reasoningDurationMs: reasoningDurationMs,
      );
    });
  }

  /// 对 path 中最后一条 assistant message 应用 `update` 并 emit new state。如果 path 为空，
  /// 或最后一条 message 不是 assistant message，则不执行任何操作。
  void _patchLastAssistant(Message Function(Message) update) {
    final path = state.value;
    if (path == null || path.path.isEmpty) return;
    final lastIndex = path.path.length - 1;
    final lastNode = path.path[lastIndex];
    if (lastNode.message.role != MessageRole.assistant) return;
    final updatedMessage = update(lastNode.message);
    final updatedNode = lastNode.copyWith(message: updatedMessage);
    final newList = List<MessageTreeNode>.from(path.path);
    newList[lastIndex] = updatedNode;
    state = AsyncData(path.copyWith(path: newList));
  }
}

/// 以 conversation id 为 key 的 conversation path notifier。
///
/// User 离开 conversation 时，auto-dispose 会取消 SSE。
final currentConversationProvider = AsyncNotifierProvider.autoDispose
    .family<CurrentConversationNotifier, ConversationPath, int>(
      CurrentConversationNotifier.new,
    );

/// 不属于单个 conversation notifier 的 cross-conversation chat action（例如在还没有可作为
/// key 的 id 前，从 empty state 创建 conversation）。
class ChatActionsNotifier extends Notifier<void> {
  @override
  void build() {}

  /// 创建 conversation，发送第一条 user message，并 queue assistant placeholder 以便
  /// streaming。返回新的 conversation id，使调用方可以 navigation 到 `/c/{id}`。
  ///
  /// Conversation 会创建在最近更新的 profile 中。如果还没有 profile，会先创建默认的
  /// “Chats” folder，使首次使用时用户无需先管理 folder 就可以 chat。
  Future<int> sendFirstMessage({
    required String modelId,
    required String text,
    String? imageData,
    bool thinkingEnabled = false,
  }) async {
    final profileId = await _resolveProfileId();
    final dio = ref.read(dioProvider);

    // 1. 创建绑定到所选 model 的 conversation。
    final createResp = await dio.post<Map<String, dynamic>>(
      '/api/profiles/$profileId/conversations',
      data: <String, dynamic>{
        'model_id': modelId,
        'thinking_enabled': thinkingEnabled,
      },
    );
    final conversation = Conversation.fromJson(createResp.data!);

    // 2. Post 第一条 user message → 创建 user + assistant placeholder。
    final body = UserMessageCreate(text: text, imageData: imageData).toJson();
    final sendResp = await dio.post<Map<String, dynamic>>(
      '/api/conversations/${conversation.id}/messages',
      data: body,
    );
    final sendMessage = SendMessageResponse.fromJson(sendResp.data!);

    // 3. Queue assistant placeholder，使 chat screen mount 时开始 streaming。
    ref.read(pendingStreamProvider.notifier).state = (
      conversationId: conversation.id,
      messageId: sendMessage.assistantMessage.id,
    );

    // 4. Refresh sidebar，使新 conversation 显示出来。
    ref.invalidate(conversationsForProfileProvider(profileId));
    ref.invalidate(profilesProvider);

    return conversation.id;
  }

  /// 选择用于创建新 conversation 的 profile。
  ///
  /// 使用最近更新的 profile（sidebar 按此方式排序，因此 `first` 是最新的）。如果没有
  /// profile，则创建“Chats”folder 并返回其 id。
  Future<int> _resolveProfileId() async {
    var profiles = await ref.read(profilesProvider.future);
    if (profiles.isNotEmpty) return profiles.first.id;
    await ref.read(profilesProvider.notifier).createProfile('Chats');
    profiles = await ref.read(profilesProvider.future);
    return profiles.first.id;
  }
}

/// Chat action notifier。
final chatActionsProvider = NotifierProvider<ChatActionsNotifier, void>(
  ChatActionsNotifier.new,
);
