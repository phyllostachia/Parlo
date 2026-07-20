/// Riverpod providers and notifiers that back the chat screen.
///
/// The central piece is [CurrentConversationNotifier], a family
/// [AsyncNotifier] keyed by conversation id. It owns the visible message path
/// and the in-flight Server-Sent Events subscription. Send / stop are actions
/// on the notifier; the SSE stream is a side-effect of send, not a separate
/// state source (architecture §3.1).
///
/// The empty state (Phase 3) uses [ChatActionsNotifier.sendFirstMessage] to
/// create a conversation and queue the assistant placeholder for streaming.
/// The chat screen's notifier opens the stream when it mounts, so the
/// streaming state survives the navigation from the empty state to
/// `/c/{id}`.
library;

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/conversation.dart';
import '../../core/models/message.dart';
import '../../core/models/model.dart';
import '../../core/models/requests.dart';
import '../../core/models/sse_event.dart';
import '../../core/network/api_client.dart';
import '../../core/network/sse_parser.dart';
import '../sidebar/sidebar_providers.dart';

/// The local state of an assistant stream.
///
/// The backend's `is_complete` flag is `true` in the `finally` block no matter
/// how the stream ended, so the frontend cannot tell a clean finish from a
/// dropped connection by looking at `is_complete` alone. This enum is the
/// local truth (architecture §5.4).
enum StreamState {
  /// No stream has run yet in this session.
  idle,

  /// Tokens are arriving from the backend.
  streaming,

  /// The user pressed stop. The assistant message keeps whatever content
  /// arrived so far.
  stopped,

  /// The stream dropped or the backend sent an `error` event. The UI shows a
  /// "connection broken, retry" button.
  error,

  /// The stream finished cleanly. The assistant message is complete.
  done,
}

/// The model registry (`GET /api/models`).
class ModelsNotifier extends AsyncNotifier<ModelsResponse?> {
  @override
  Future<ModelsResponse?> build() async {
    final dio = ref.read(dioProvider);
    final response = await dio.get<Map<String, dynamic>>('/api/models');
    if (response.data == null) return null;
    return ModelsResponse.fromJson(response.data!);
  }

  /// Forces a refetch of the model list.
  void refresh() => ref.invalidateSelf();
}

/// The full models response (default + list).
final modelsProvider =
    AsyncNotifierProvider<ModelsNotifier, ModelsResponse?>(ModelsNotifier.new);

/// The flat list of models, derived from [modelsProvider]. Empty while loading.
final modelListProvider = Provider<List<ModelRead>>((ref) {
  return ref.watch(modelsProvider).valueOrNull?.models ?? const <ModelRead>[];
});

/// The configured default model id, derived from [modelsProvider].
final defaultModelIdProvider = Provider<String?>((ref) {
  return ref.watch(modelsProvider).valueOrNull?.defaultModel;
});

/// The current stream state for the viewed conversation.
///
/// A singleton because only one conversation is viewed at a time. The
/// conversation notifier resets this to [StreamState.idle] when it builds.
final streamStateProvider = StateProvider<StreamState>((ref) {
  return StreamState.idle;
});

/// A pending "open this stream when the chat screen mounts" request, set by
/// the empty state's first-send and consumed by the chat notifier's build.
///
/// The record is `(conversationId, messageId)` so the chat notifier can
/// verify the pending stream is for THIS conversation before opening it.
final pendingStreamProvider =
    StateProvider<({int conversationId, int messageId})?>((ref) {
  return null;
});

/// The visible message path for one conversation, with send / stop actions.
///
/// Auto-disposes when the user leaves the conversation so the SSE subscription
/// is cancelled cleanly. The `build` method also opens a pending stream (set
/// by the empty state) so streaming starts as soon as the chat screen mounts.
class CurrentConversationNotifier
    extends AutoDisposeFamilyAsyncNotifier<ConversationPath, int> {
  /// The in-flight SSE subscription, or `null` when no stream is running.
  StreamSubscription<SseEvent>? _sub;

  @override
  Future<ConversationPath> build(int conversationId) async {
    // Cancel any previous stream from a reused notifier instance.
    await _sub?.cancel();
    _sub = null;
    ref.read(streamStateProvider.notifier).state = StreamState.idle;

    // Cancel the stream if the notifier disposes (user leaves the page).
    ref.onDispose(() {
      _sub?.cancel();
      _sub = null;
    });

    final dio = ref.read(dioProvider);
    final response = await dio.get<Map<String, dynamic>>(
      '/api/conversations/$conversationId/messages',
    );
    final path = ConversationPath.fromJson(response.data!);

    // If the empty state queued a stream for this conversation, open it now.
    final pending = ref.read(pendingStreamProvider);
    if (pending != null && pending.conversationId == conversationId) {
      ref.read(pendingStreamProvider.notifier).state = null;
      unawaited(_openStream(pending.messageId));
    }
    return path;
  }

  /// Sends a user message and opens the SSE for the new assistant reply.
  ///
  /// The backend creates both the user message and an empty assistant
  /// placeholder in one call; we append both to the local path immediately so
  /// the UI shows them without waiting for a refetch, then stream tokens into
  /// the assistant placeholder.
  Future<void> send({required String text, String? imageData}) async {
    if (ref.read(streamStateProvider) == StreamState.streaming) return;

    final conversationId = arg;
    final dio = ref.read(dioProvider);

    // We need the current path so we can append to it. `future` resolves
    // immediately if the build already finished.
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

  /// Stops the in-flight stream. The assistant message keeps its partial
  /// content; the local stream state is set to [StreamState.stopped].
  Future<void> stop() async {
    // Set the state to `stopped` BEFORE cancelling the subscription. The
    // stream's `onDone` callback fires during `cancel` and would otherwise
    // see `streaming` and overwrite the state with `error`.
    ref.read(streamStateProvider.notifier).state = StreamState.stopped;
    await _sub?.cancel();
    _sub = null;
    _markAssistantComplete();
  }

  /// Regenerates an assistant reply.
  ///
  /// The backend creates a new empty assistant placeholder as a sibling of
  /// [assistantMessageId] (both share the same parent user message), moves
  /// the conversation's current leaf to the placeholder, and returns the
  /// placeholder. This notifier replaces the old assistant node with the new
  /// placeholder on the visible path, records the new sibling id so the
  /// version switcher can move back to the old reply, and opens the SSE
  /// stream to fill the placeholder.
  ///
  /// Regenerating a middle assistant shortens the visible path: every message
  /// after the new placeholder's parent stays in the tree but is no longer
  /// on the visible path until the user switches back to that branch.
  ///
  /// `retry` (for a broken or stopped stream) is the same call: a new sibling
  /// is created, and the broken partial reply is preserved as a sibling the
  /// user can switch back to (architecture §5.4 and §7).
  Future<void> regenerate({required int assistantMessageId}) async {
    if (ref.read(streamStateProvider) == StreamState.streaming) return;

    final conversationId = arg;
    final current = await future;
    final index = current.path
        .indexWhere((node) => node.message.id == assistantMessageId);
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

    // Build the new visible path: keep every node before the old assistant
    // (this includes the parent user message), then append the new
    // placeholder. The old assistant and any of its descendants leave the
    // visible path but stay in the tree.
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

  /// Switches the visible path to end at the given leaf message.
  ///
  /// The backend moves the conversation's `current_leaf_id` to [leafId] and
  /// returns the full path with fresh sibling metadata for every node. This
  /// notifier replaces its state with that path. No SSE stream is opened:
  /// the switched-to message is already complete.
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

  /// Opens the SSE for the given assistant message id and patches the local
  /// path on every event.
  Future<void> _openStream(int assistantMessageId) async {
    await _sub?.cancel();
    final dio = ref.read(dioProvider);
    final response = await dio.get<ResponseBody>(
      '/api/chat/stream',
      queryParameters: <String, dynamic>{'message_id': assistantMessageId},
      options: Options(responseType: ResponseType.stream),
    );
    final body = response.data;
    if (body == null) {
      ref.read(streamStateProvider.notifier).state = StreamState.error;
      return;
    }
    ref.read(streamStateProvider.notifier).state = StreamState.streaming;
    _sub = parseSseStream(body.stream).listen(
      _onEvent,
      onError: (Object error) {
        ref.read(streamStateProvider.notifier).state = StreamState.error;
        _sub = null;
      },
      onDone: () {
        // If the stream closed without a `done` event, treat it as a drop.
        if (ref.read(streamStateProvider) == StreamState.streaming) {
          ref.read(streamStateProvider.notifier).state = StreamState.error;
        }
        _sub = null;
      },
      cancelOnError: false,
    );
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
        // The signature is replayed by the backend on later turns; the UI
        // does not show it. Nothing to do here.
        break;
      case SseError():
        ref.read(streamStateProvider.notifier).state = StreamState.error;
        _sub?.cancel();
        _sub = null;
      case SseDone():
        _markAssistantComplete();
        ref.read(streamStateProvider.notifier).state = StreamState.done;
        _sub?.cancel();
        _sub = null;
    }
  }

  /// Appends text to the last assistant message's `content`.
  void _appendAssistantContent(String delta) {
    _patchLastAssistant(
      (message) => message.copyWith(
        content: message.content + delta,
      ),
    );
  }

  /// Appends text to the last assistant message's `reasoning`.
  void _appendAssistantReasoning(String delta) {
    _patchLastAssistant(
      (message) => message.copyWith(
        reasoning: (message.reasoning ?? '') + delta,
      ),
    );
  }

  /// Marks the last assistant message as complete.
  void _markAssistantComplete() {
    _patchLastAssistant(
      (message) => message.copyWith(isComplete: true),
    );
  }

  /// Applies `update` to the last assistant message in the path and emits the
  /// new state. Does nothing if the path is empty or the last message is not
  /// an assistant message.
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

/// The conversation path notifier, keyed by conversation id.
///
/// Auto-dispose cancels the SSE when the user leaves the conversation.
final currentConversationProvider =
    AsyncNotifierProvider.autoDispose.family<
        CurrentConversationNotifier,
        ConversationPath,
        int>(CurrentConversationNotifier.new);

/// Cross-conversation chat actions that do not belong to a single
/// conversation's notifier (e.g. creating a conversation from the empty
/// state, before there is an id to key on).
class ChatActionsNotifier extends Notifier<void> {
  @override
  void build() {}

  /// Creates a conversation, sends the first user message, and queues the
  /// assistant placeholder for streaming. Returns the new conversation id so
  /// the caller can navigate to `/c/{id}`.
  ///
  /// The conversation is created in the most-recently-updated profile. If
  /// there are no profiles yet, a default "Chats" folder is created first so
  /// the first-time experience works without forcing the user to manage
  /// folders before they can chat.
  Future<int> sendFirstMessage({
    required String modelId,
    required String text,
    String? imageData,
  }) async {
    final profileId = await _resolveProfileId();
    final dio = ref.read(dioProvider);

    // 1. Create the conversation bound to the chosen model.
    final createResp = await dio.post<Map<String, dynamic>>(
      '/api/profiles/$profileId/conversations',
      data: <String, dynamic>{'model_id': modelId},
    );
    final conversation = Conversation.fromJson(createResp.data!);

    // 2. Post the first user message → creates user + assistant placeholder.
    final body = UserMessageCreate(text: text, imageData: imageData).toJson();
    final sendResp = await dio.post<Map<String, dynamic>>(
      '/api/conversations/${conversation.id}/messages',
      data: body,
    );
    final sendMessage = SendMessageResponse.fromJson(sendResp.data!);

    // 3. Queue the assistant placeholder for streaming when the chat screen
    //    mounts.
    ref.read(pendingStreamProvider.notifier).state = (
      conversationId: conversation.id,
      messageId: sendMessage.assistantMessage.id,
    );

    // 4. Refresh the sidebar so the new conversation shows up.
    ref.invalidate(conversationsForProfileProvider(profileId));
    ref.invalidate(profilesProvider);

    return conversation.id;
  }

  /// Picks the profile to create a new conversation in.
  ///
  /// Uses the most-recently-updated profile (the sidebar is sorted that way,
  /// so `first` is the newest). If there are no profiles, creates a "Chats"
  /// folder and returns its id.
  Future<int> _resolveProfileId() async {
    var profiles = await ref.read(profilesProvider.future);
    if (profiles.isNotEmpty) return profiles.first.id;
    await ref.read(profilesProvider.notifier).createProfile('Chats');
    profiles = await ref.read(profilesProvider.future);
    return profiles.first.id;
  }
}

/// The chat actions notifier.
final chatActionsProvider =
    NotifierProvider<ChatActionsNotifier, void>(ChatActionsNotifier.new);
