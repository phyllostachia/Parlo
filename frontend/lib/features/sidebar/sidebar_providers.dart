/// Riverpod providers and notifiers that back the sidebar.
///
/// The sidebar reads two kinds of data:
/// - The full list of profiles (`GET /api/profiles`), shown as the top-level
///   folder tree.
/// - The conversations inside each expanded profile
///   (`GET /api/profiles/{id}/conversations`), shown when a folder is open.
///
/// Mutations (create / rename / delete) go through the same notifiers so the
/// list state stays consistent without a manual refetch.
///
/// The architecture says the conversations list is "filtered by
/// selectedProfileId". This implementation uses a `family` provider keyed by
/// profile id instead, so the folder tree can show several expanded profiles
/// at once (matching the folder-tree UX in `product.md` §5.1). The difference
/// is small and the family approach composes better with expand/collapse.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/conversation.dart';
import '../../core/models/profile.dart';
import '../../core/network/api_client.dart';

/// Decodes the JSON list returned by `GET /api/profiles`.
List<Profile> _parseProfiles(List<dynamic>? raw) {
  final list = raw ?? const <dynamic>[];
  return list
      .map((e) => Profile.fromJson(e as Map<String, dynamic>))
      .toList(growable: false);
}

/// Decodes the JSON list returned by `GET /api/profiles/{id}/conversations`.
List<Conversation> _parseConversations(List<dynamic>? raw) {
  final list = raw ?? const <dynamic>[];
  return list
      .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
      .toList(growable: false);
}

/// The list of all profiles, with create / rename / delete actions.
///
/// After every mutation we re-run `build` (via `ref.invalidateSelf`) so the
/// list reflects the server's current state and ordering. The sidebar shows a
/// loading shimmer while the refetch is in flight.
class ProfilesNotifier extends AsyncNotifier<List<Profile>> {
  @override
  Future<List<Profile>> build() async {
    final dio = ref.read(dioProvider);
    final response = await dio.get<List<dynamic>>('/api/profiles');
    return _parseProfiles(response.data);
  }

  /// Creates a profile with the given name.
  ///
  /// The backend takes `name` as a query parameter (see
  /// `backend/app/api/profiles.py`), not as a JSON body.
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

  /// Renames a profile. The new name goes in the query string.
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

  /// Deletes a profile. The backend cascades the delete to its conversations
  /// and their messages via the foreign-key `ON DELETE CASCADE` rules.
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

/// The singleton provider for the profile list.
final profilesProvider =
    AsyncNotifierProvider<ProfilesNotifier, List<Profile>>(
  ProfilesNotifier.new,
);

/// The conversations inside one profile, keyed by profile id.
///
/// A `family` so the folder tree can have several profiles expanded at once,
/// each loading its conversations independently. Callers invalidate this
/// provider (with the profile id) after mutating a conversation.
final conversationsForProfileProvider =
    FutureProvider.family<List<Conversation>, int>((ref, profileId) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get<List<dynamic>>(
    '/api/profiles/$profileId/conversations',
  );
  return _parseConversations(response.data);
});

/// The set of profile ids whose folder is expanded in the sidebar.
///
/// Kept as a [Set] so membership tests are O(1) and the order does not matter
/// (the tree orders by `updated_at`).
final expandedProfilesProvider = StateProvider<Set<int>>((ref) {
  return <int>{};
});

/// Cross-cutting sidebar actions that affect conversations and need to
/// invalidate both the conversations family and the profile list (because
/// touching a conversation bumps the profile's `updated_at` and reorders the
/// sidebar).
class SidebarActionsNotifier extends Notifier<void> {
  @override
  void build() {}

  /// Renames a conversation. `profileId` is needed to invalidate the right
  /// conversations-family instance.
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

  /// Deletes a conversation. Messages are removed by the backend's
  /// `ON DELETE CASCADE` rule on `message.conversation_id`.
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

/// The sidebar actions notifier.
final sidebarActionsProvider =
    NotifierProvider<SidebarActionsNotifier, void>(SidebarActionsNotifier.new);
