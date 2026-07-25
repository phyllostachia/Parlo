/// 阶段 3 smoke test。
///
/// 验证 [ParloApp] 在 router 接入后可以 build，并渲染 empty-state headline。Sidebar 的
/// profile list 和 model registry 都被 stub，使 test 不会发起真实 network call。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:parlo/app.dart';
import 'package:parlo/core/auth/auth_providers.dart';
import 'package:parlo/core/models/model.dart';
import 'package:parlo/core/models/profile.dart';
import 'package:parlo/features/chat/chat_providers.dart';
import 'package:parlo/features/sidebar/sidebar_providers.dart';

/// 返回 empty list 且不访问 network 的 [ProfilesNotifier]，仅供 test 使用。
class _EmptyProfilesNotifier extends ProfilesNotifier {
  @override
  Future<List<Profile>> build() async => const <Profile>[];
}

/// 返回固定 empty response 且不访问 network 的 [ModelsNotifier]，仅供 test 使用。
class _EmptyModelsNotifier extends ModelsNotifier {
  @override
  Future<ModelsResponse?> build() async => null;
}

void main() {
  testWidgets('ParloApp renders the empty-state headline', (tester) async {
    // 使用 in-memory SharedPreferences，使 auth store 在 test 期间不触碰 platform channel。
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          // Stub profile list 为空，使 sidebar 不会发起真实 network request（这会使 test
          // 的 fake async 卡住）。
          profilesProvider.overrideWith(() => _EmptyProfilesNotifier()),
          // Stub model registry，使 empty state 也不会调用 GET /api/models。
          modelsProvider.overrideWith(() => _EmptyModelsNotifier()),
        ],
        child: const ParloApp(),
      ),
    );

    // 等待 async provider settle。
    await tester.pumpAndSettle();

    // Empty-state headline（“今天想聊些什么？”）应显示在 screen 上。
    expect(find.text('今天想聊些什么？'), findsOneWidget);
  });
}
