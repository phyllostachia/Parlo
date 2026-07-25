/// 支撑 sidebar 的 Riverpod provider 和 notifier。
///
/// Sidebar 读取两类 data：
/// - 完整 profile list（`GET /api/profiles`），显示为顶层 folder tree。
/// - 每个 expanded profile 内的 conversation（`GET /api/profiles/{id}/conversations`），
///   在 folder 打开时显示。
///
/// Mutation（create / rename / delete）都通过相同 notifier 执行，使 list state 无需手动
/// refetch 也能保持一致。
///
/// 架构文档规定 conversation list “filtered by selectedProfileId”。此实现改用以 profile id
/// 为 key 的 `family` provider，使 folder tree 可以同时显示多个 expanded profile（匹配
/// `product.md` §5.1 的 folder-tree UX）。差异很小，而 family 方案与 expand/collapse 组合更好。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/conversation.dart';
import '../../core/models/profile.dart';
import '../../core/network/api_client.dart';

/// Decode `GET /api/profiles` 返回的 JSON list。
List<Profile> _parseProfiles(List<dynamic>? raw) {
  final list = raw ?? const <dynamic>[];
  return list
      .map((e) => Profile.fromJson(e as Map<String, dynamic>))
      .toList(growable: false);
}

/// Decode `GET /api/profiles/{id}/conversations` 返回的 JSON list。
List<Conversation> _parseConversations(List<dynamic>? raw) {
  final list = raw ?? const <dynamic>[];
  return list
      .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
      .toList(growable: false);
}

/// 所有 profile 的 list，以及 create / rename / delete action。
///
/// 每次 mutation 后重新运行 `build`（通过 `ref.invalidateSelf`），使 list 反映 server 当前
/// state 和 order。Refetch in flight 时 sidebar 显示 loading shimmer。
class ProfilesNotifier extends AsyncNotifier<List<Profile>> {
  @override
  Future<List<Profile>> build() async {
    final dio = ref.read(dioProvider);
    final response = await dio.get<List<dynamic>>('/api/profiles');
    return _parseProfiles(response.data);
  }

  /// 使用给定 name 创建 profile。
  ///
  /// Backend 将 `name` 作为 query parameter（参见 `backend/app/api/profiles.py`）接收，
  /// 而不是 JSON body。
  Future<void> createProfile(String name) async {
    final dio = ref.read(dioProvider);
    state = const AsyncLoading<List<Profile>>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      await dio.post<void>(
        '/api/profiles',
        queryParameters: <String, dynamic>{'name': name},
      );
      final response = await dio.get<List<dynamic>>('/api/profiles');
      return _parseProfiles(response.data);
    });
  }

  /// 重命名 profile。新 name 放在 query string 中。
  Future<void> renameProfile(int id, String name) async {
    final dio = ref.read(dioProvider);
    state = const AsyncLoading<List<Profile>>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      await dio.patch<void>(
        '/api/profiles/$id',
        queryParameters: <String, dynamic>{'name': name},
      );
      final response = await dio.get<List<dynamic>>('/api/profiles');
      return _parseProfiles(response.data);
    });
  }

  /// 删除 profile。Backend 通过 foreign-key `ON DELETE CASCADE` rule 将删除级联到其
  /// conversation 和 message。
  Future<void> deleteProfile(int id) async {
    final dio = ref.read(dioProvider);
    state = const AsyncLoading<List<Profile>>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      await dio.delete<dynamic>('/api/profiles/$id');
      final response = await dio.get<List<dynamic>>('/api/profiles');
      return _parseProfiles(response.data);
    });
  }
}

/// Profile list 的 singleton provider。
final profilesProvider = AsyncNotifierProvider<ProfilesNotifier, List<Profile>>(
  ProfilesNotifier.new,
);

/// 一个 profile 内的 conversation，以 profile id 为 key。
///
/// 使用 `family`，使 folder tree 可以同时展开多个 profile，并分别加载各自 conversation。
/// Mutation conversation 后，调用方使用 profile id invalidate 此 provider。
final conversationsForProfileProvider =
    FutureProvider.family<List<Conversation>, int>((ref, profileId) async {
      final dio = ref.read(dioProvider);
      final response = await dio.get<List<dynamic>>(
        '/api/profiles/$profileId/conversations',
      );
      return _parseConversations(response.data);
    });

/// Sidebar 中已展开 folder 的 profile id set。
///
/// 使用 [Set]，使 membership test 为 O(1)，且不关心顺序（tree 按 `updated_at` 排序）。
final expandedProfilesProvider = StateProvider<Set<int>>((ref) {
  return <int>{};
});

/// 影响 conversation 的 cross-cutting sidebar action，需要同时 invalidate conversations
/// family 和 profile list（因为操作 conversation 会更新 profile 的 `updated_at`，并改变
/// sidebar order）。
class SidebarActionsNotifier extends Notifier<void> {
  @override
  void build() {}

  /// 重命名 conversation。需要 `profileId` 以 invalidate 正确的 conversations-family instance。
  Future<void> renameConversation({
    required int profileId,
    required int conversationId,
    required String title,
  }) async {
    final dio = ref.read(dioProvider);
    await dio.patch<Map<String, dynamic>>(
      '/api/conversations/$conversationId',
      data: <String, dynamic>{'title': title},
    );
    ref.invalidate(conversationsForProfileProvider(profileId));
    ref.invalidate(profilesProvider);
  }

  /// 删除 conversation。Backend 会根据 `message.conversation_id` 上的 `ON DELETE CASCADE`
  /// rule 删除 message。
  Future<void> deleteConversation({
    required int profileId,
    required int conversationId,
  }) async {
    final dio = ref.read(dioProvider);
    await dio.delete<dynamic>('/api/conversations/$conversationId');
    ref.invalidate(conversationsForProfileProvider(profileId));
    ref.invalidate(profilesProvider);
  }
}

/// Sidebar action notifier。
final sidebarActionsProvider = NotifierProvider<SidebarActionsNotifier, void>(
  SidebarActionsNotifier.new,
);
