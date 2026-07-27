/// 主内容 route 切换动画的 widget test。
///
/// 验证通过 sidebar 选择不同 conversation 时，旧屏先完全淡出，再显示新屏，避免两个会话
/// 内容同时可见。
library;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tan/app.dart';
import 'package:tan/core/auth/auth_providers.dart';
import 'package:tan/core/auth/auth_store.dart';
import 'package:tan/core/models/model.dart';
import 'package:tan/core/models/profile.dart';
import 'package:tan/core/network/api_client.dart';
import 'package:tan/core/network/base_url_store.dart';
import 'package:tan/core/router/app_shell.dart';
import 'package:tan/features/chat/chat_providers.dart';
import 'package:tan/features/sidebar/sidebar_providers.dart';

/// Router test 使用的 mock Dio。
class _MockDio extends Mock implements Dio {}

/// 返回固定 empty response 且不访问 network 的 [ModelsNotifier]。
class _EmptyModelsNotifier extends ModelsNotifier {
  @override
  Future<ModelsResponse?> build() async => null;
}

/// 返回固定 empty list 且不访问 network 的 [ProfilesNotifier]。
class _EmptyProfilesNotifier extends ProfilesNotifier {
  @override
  Future<List<Profile>> build() async => const <Profile>[];
}

void main() {
  testWidgets('conversation screens fade out before the next screen fades in', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      kAuthTokenKey: 'test-token',
      kBaseUrlKey: 'http://localhost:8000',
    });
    final prefs = await SharedPreferences.getInstance();
    final dio = _MockDio();
    _stubConversationPath(dio, id: 1, title: 'First conversation');
    _stubConversationPath(dio, id: 2, title: 'Second conversation');

    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          dioProvider.overrideWithValue(dio),
          modelsProvider.overrideWith(() => _EmptyModelsNotifier()),
          profilesProvider.overrideWith(() => _EmptyProfilesNotifier()),
        ],
        child: const TanApp(),
      ),
    );
    await tester.pumpAndSettle();

    final router = GoRouter.of(tester.element(find.byType(AppShell)));
    router.go('/c/1');
    await tester.pumpAndSettle();
    expect(find.text('First conversation'), findsOneWidget);

    router.go('/c/2');
    // 先处理新 route 的异步 conversation load，但不推进 transition clock。
    await tester.pump();
    await tester.pump();
    expect(find.text('Second conversation'), findsOneWidget);

    // 前半段：旧屏仍在淡出，新屏必须完全透明。
    await tester.pump(const Duration(milliseconds: 60));
    expect(_effectiveOpacity(tester, 'First conversation'), greaterThan(0));
    expect(_effectiveOpacity(tester, 'Second conversation'), lessThan(0.01));

    // 中点：两个屏幕都完全透明，主区域短暂留白。
    await tester.pump(const Duration(milliseconds: 60));
    expect(_effectiveOpacity(tester, 'First conversation'), lessThan(0.01));
    expect(_effectiveOpacity(tester, 'Second conversation'), lessThan(0.01));

    // 后半段：旧屏保持不可见，新屏开始淡入。
    await tester.pump(const Duration(milliseconds: 60));
    expect(_effectiveOpacity(tester, 'First conversation'), lessThan(0.01));
    expect(_effectiveOpacity(tester, 'Second conversation'), greaterThan(0));
  });
}

/// 返回 [text] 所在页面中所有 [FadeTransition] 合成后的透明度。
double _effectiveOpacity(WidgetTester tester, String text) {
  final transitions = tester.widgetList<FadeTransition>(
    find.ancestor(of: find.text(text), matching: find.byType(FadeTransition)),
  );
  return transitions.fold<double>(
    1,
    (opacity, transition) => opacity * transition.opacity.value,
  );
}

/// Stub 一个空 message path，使 chat screen 可以显示指定的 conversation title。
void _stubConversationPath(
  _MockDio dio, {
  required int id,
  required String title,
}) {
  final path = '/api/conversations/$id/messages';
  when(() => dio.get<Map<String, dynamic>>(path)).thenAnswer(
    (_) async => Response<Map<String, dynamic>>(
      data: <String, dynamic>{
        'conversation': <String, dynamic>{
          'id': id,
          'profile_id': 1,
          'title': title,
          'model_id': 'test-model',
          'thinking_effort': 'low',
          'current_leaf_id': null,
          'created_at': '2026-07-01T00:00:00Z',
          'updated_at': '2026-07-01T00:00:00Z',
        },
        'path': <Object>[],
      },
      requestOptions: RequestOptions(path: path),
    ),
  );
}
