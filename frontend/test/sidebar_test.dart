/// Sidebar widget tests.
///
/// These tests stub the [profilesProvider] so the sidebar does not make real
/// network calls. They verify the tree renders the folders and the empty
/// hint, which are the two visible states the user can land on.
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
import 'package:parlo/core/router/app_shell.dart';
import 'package:parlo/core/theme/app_theme.dart';
import 'package:parlo/features/chat/chat_providers.dart';
import 'package:parlo/features/sidebar/sidebar_screen.dart';
import 'package:parlo/features/sidebar/sidebar_providers.dart';

/// A [ProfilesNotifier] that returns a fixed list without hitting the
/// network, used by the sidebar tests.
class _FixedProfilesNotifier extends ProfilesNotifier {
  _FixedProfilesNotifier(this._profiles);
  final List<Profile> _profiles;

  @override
  Future<List<Profile>> build() async => _profiles;
}

/// A [ProfilesNotifier] that returns an empty list without hitting the
/// network.
class _EmptyProfilesNotifier extends ProfilesNotifier {
  @override
  Future<List<Profile>> build() async => const <Profile>[];
}

/// A [ModelsNotifier] that returns null without hitting the network.
class _EmptyModelsNotifier extends ModelsNotifier {
  @override
  Future<ModelsResponse?> build() async => null;
}

void main() {
  testWidgets('sidebar renders profile folder rows', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final profiles = <Profile>[
      Profile(
        id: 1,
        name: 'Learning',
        createdAt: DateTime.utc(2026, 7, 1),
        updatedAt: DateTime.utc(2026, 7, 2),
      ),
      Profile(
        id: 2,
        name: 'Research',
        createdAt: DateTime.utc(2026, 7, 1),
        updatedAt: DateTime.utc(2026, 7, 3),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          profilesProvider.overrideWith(() => _FixedProfilesNotifier(profiles)),
          // Stub the model registry so the empty state does not fire a real
          // network request.
          modelsProvider.overrideWith(() => _EmptyModelsNotifier()),
        ],
        child: const ParloApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Learning'), findsOneWidget);
    expect(find.text('Research'), findsOneWidget);
  });

  testWidgets('sidebar shows the empty hint when there are no folders', (
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

    // The empty hint is a single sentence, with a newline between its two
    // lines. We match on the first line to avoid tight coupling to the
    // exact wrapping.
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text && (widget.data ?? '').startsWith('No folders yet.'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('wide sidebar can collapse and expand from its panel icon', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final profiles = <Profile>[
      Profile(
        id: 1,
        name: 'Learning',
        createdAt: DateTime.utc(2026, 7, 1),
        updatedAt: DateTime.utc(2026, 7, 2),
      ),
    ];

    var collapsed = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          profilesProvider.overrideWith(() => _FixedProfilesNotifier(profiles)),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SidebarScreen(
                  currentConversationId: null,
                  onNavigate: (_) {},
                  collapsed: collapsed,
                  onToggle: () => setState(() => collapsed = !collapsed),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('收起侧栏'), findsOneWidget);
    expect(tester.getSize(find.byType(SidebarScreen)).width, 280);

    await tester.tap(find.byTooltip('收起侧栏'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('展开侧栏'), findsOneWidget);
    expect(find.text('Learning'), findsNothing);
    expect(tester.getSize(find.byType(SidebarScreen)).width, 80);

    await tester.tap(find.byTooltip('展开侧栏'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('收起侧栏'), findsOneWidget);
    expect(find.text('Learning'), findsOneWidget);
    expect(tester.getSize(find.byType(SidebarScreen)).width, 280);
  });

  testWidgets('narrow layout keeps a collapsed sidebar without a header', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      kAuthTokenKey: 'test-token',
      kBaseUrlKey: 'http://localhost:8000',
    });
    final prefs = await SharedPreferences.getInstance();
    final profiles = <Profile>[
      Profile(
        id: 1,
        name: 'Learning',
        createdAt: DateTime.utc(2026, 7, 1),
        updatedAt: DateTime.utc(2026, 7, 2),
      ),
    ];

    await tester.binding.setSurfaceSize(const Size(600, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          profilesProvider.overrideWith(() => _FixedProfilesNotifier(profiles)),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const AppShell(child: SizedBox.expand()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SidebarScreen), findsOneWidget);
    expect(tester.getSize(find.byType(SidebarScreen)).width, 80);
    expect(find.byTooltip('展开侧栏'), findsOneWidget);
    expect(find.text('Parlo'), findsNothing);

    await tester.tap(find.byTooltip('展开侧栏'));
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(SidebarScreen)).width, 280);
    expect(find.text('Learning'), findsOneWidget);
  });
}
