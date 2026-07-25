/// Token + backend address dialog 的 widget test。
///
/// Dialog 由 [TokenDialogHost] 显示，它监听 auth store 和 base URL store，并在 token 缺失、
/// token 被标记为 unauthorized 或 base URL 为空时打开 dialog。这些 test 验证每个 trigger，
/// 以及保存两个 value 后 dialog 会关闭。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:parlo/app.dart';
import 'package:parlo/core/auth/auth_providers.dart';
import 'package:parlo/core/auth/auth_store.dart';
import 'package:parlo/core/models/model.dart';
import 'package:parlo/core/models/profile.dart';
import 'package:parlo/core/network/base_url_store.dart';
import 'package:parlo/features/chat/chat_providers.dart';
import 'package:parlo/features/sidebar/sidebar_providers.dart';

/// 返回 empty list 且不访问 network 的 [ProfilesNotifier]，仅供 test 使用。
class _EmptyProfilesNotifier extends ProfilesNotifier {
  @override
  Future<List<Profile>> build() async => const <Profile>[];
}

/// 返回 null 且不访问 network 的 [ModelsNotifier]。
class _EmptyModelsNotifier extends ModelsNotifier {
  @override
  Future<ModelsResponse?> build() async => null;
}

void main() {
  testWidgets('shows the token dialog on first use when no token is set', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          profilesProvider.overrideWith(() => _EmptyProfilesNotifier()),
          modelsProvider.overrideWith(() => _EmptyModelsNotifier()),
        ],
        child: const ParloApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Dialog 因尚未设置 token 而打开。Headline 是“first use”variant。
    expect(find.text('Welcome to Parlo'), findsOneWidget);
    expect(find.text('Bearer token'), findsOneWidget);
    expect(find.text('Backend domain'), findsOneWidget);
    expect(find.text('Port'), findsOneWidget);
  });

  testWidgets('saving a token and address closes the dialog', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          profilesProvider.overrideWith(() => _EmptyProfilesNotifier()),
          modelsProvider.overrideWith(() => _EmptyModelsNotifier()),
        ],
        child: const ParloApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Parlo'), findsOneWidget);

    // Dialog 有三个 text field：domain、port、token（按此顺序）。
    final fields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.at(0), 'parlo.example.com');
    await tester.pump();
    await tester.enterText(fields.at(1), '8000');
    await tester.pump();
    await tester.enterText(fields.at(2), 'test-token');
    await tester.pump();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // 两个 value 都写入且 store 通知 host 后，dialog 关闭。
    expect(find.text('Welcome to Parlo'), findsNothing);

    // Token 和 base URL 都已持久化到 SharedPreferences。
    expect(prefs.getString(kAuthTokenKey), 'test-token');
    expect(prefs.getString(kBaseUrlKey), 'https://parlo.example.com:8000');
  });

  testWidgets(
    'does not show the dialog when both a token and an address are set',
    (tester) async {
      // 用 token 和 base URL 初始化 preferences，使两个 store 都能从它们 bootstrap；host
      // 不应打开 dialog。
      SharedPreferences.setMockInitialValues(<String, Object>{
        kAuthTokenKey: 'already-here',
        kBaseUrlKey: 'https://parlo.example.com:8000',
      });
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            profilesProvider.overrideWith(() => _EmptyProfilesNotifier()),
            modelsProvider.overrideWith(() => _EmptyModelsNotifier()),
          ],
          child: const ParloApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Parlo'), findsNothing);
      expect(find.text('Set your backend address'), findsNothing);
    },
  );

  testWidgets('shows the "backend address" dialog when only the token is set', (
    tester,
  ) async {
    // 只初始化 token；base URL 仍缺失，因此 dialog 应以“set your backend address”headline
    // 出现（不是 first-use“Welcome”headline，因为 user 已经有 token）。
    SharedPreferences.setMockInitialValues(<String, Object>{
      kAuthTokenKey: 'already-here',
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          profilesProvider.overrideWith(() => _EmptyProfilesNotifier()),
          modelsProvider.overrideWith(() => _EmptyModelsNotifier()),
        ],
        child: const ParloApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Parlo'), findsNothing);
    expect(find.text('Set your backend address'), findsOneWidget);
    expect(find.text('Backend domain'), findsOneWidget);
    expect(find.text('Port'), findsOneWidget);
  });

  testWidgets('Save button stays disabled until all fields are filled', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          profilesProvider.overrideWith(() => _EmptyProfilesNotifier()),
          modelsProvider.overrideWith(() => _EmptyModelsNotifier()),
        ],
        child: const ParloApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Field 为空时 Save button 被禁用（onPressed 为 null）。
    FilledButton saveButton() =>
        tester.widget<FilledButton>(find.byType(FilledButton));
    expect(saveButton().onPressed, isNull);

    // 只填写 token；Save 仍禁用，因为 address 仍缺失。
    final fields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.at(2), 'test-token');
    await tester.pump();
    expect(saveButton().onPressed, isNull);

    // 填写 domain；Save 仍禁用，因为 port 缺失。
    await tester.enterText(fields.at(0), 'parlo.example.com');
    await tester.pump();
    expect(saveButton().onPressed, isNull);

    // 填写 port；Save 现在启用。
    await tester.enterText(fields.at(1), '8000');
    await tester.pump();
    expect(saveButton().onPressed, isNotNull);
  });
}
