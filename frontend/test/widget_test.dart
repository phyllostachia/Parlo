/// Phase 3 smoke test.
///
/// Verifies that [ParloApp] builds with the router wired up and renders the
/// empty-state headline. The sidebar's profile list and the model registry
/// are stubbed so the test does not make real network calls.
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

/// A [ProfilesNotifier] that returns an empty list without hitting the
/// network, used only in tests.
class _EmptyProfilesNotifier extends ProfilesNotifier {
  @override
  Future<List<Profile>> build() async => const <Profile>[];
}

/// A [ModelsNotifier] that returns a fixed empty response without hitting the
/// network, used only in tests.
class _EmptyModelsNotifier extends ModelsNotifier {
  @override
  Future<ModelsResponse?> build() async => null;
}

void main() {
  testWidgets('ParloApp renders the empty-state headline', (tester) async {
    // Use an in-memory SharedPreferences so the auth store does not touch the
    // platform channel during the test.
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          // Stub the profile list to empty so the sidebar does not fire a real
          // network request (which would hang the test's fake async).
          profilesProvider.overrideWith(() => _EmptyProfilesNotifier()),
          // Stub the model registry so the empty state does not call
          // GET /api/models either.
          modelsProvider.overrideWith(() => _EmptyModelsNotifier()),
        ],
        child: const ParloApp(),
      ),
    );

    // Let the async providers settle.
    await tester.pumpAndSettle();

    // The empty-state headline ("How can I help?") should be on the screen.
    expect(find.text('How can I help?'), findsOneWidget);
  });
}
