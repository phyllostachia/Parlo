/// Widget tests for the token dialog.
///
/// The dialog is shown by [TokenDialogHost], which watches the auth store and
/// opens the dialog when there is no token or the token was flagged as
/// unauthorized. These tests verify both triggers and that saving a token
/// closes the dialog.
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
import 'package:parlo/features/chat/chat_providers.dart';
import 'package:parlo/features/sidebar/sidebar_providers.dart';

/// A [ProfilesNotifier] that returns an empty list without hitting the
/// network, used only in tests.
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
  testWidgets('shows the token dialog on first use when no token is set',
      (tester) async {
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

    // The dialog opens because no token has been set yet.
    expect(find.text('Welcome to Parlo'), findsOneWidget);
    expect(find.text('Bearer token'), findsOneWidget);
  });

  testWidgets('saving a token closes the dialog', (tester) async {
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

    // Type a token into the dialog's text field (the empty state also has a
    // text field, so scope the finder to the dialog).
    final tokenField = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(tokenField, 'test-token');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // The dialog closes after the token is written and the auth store
    // notifies the host.
    expect(find.text('Welcome to Parlo'), findsNothing);

    // The token was persisted to SharedPreferences.
    expect(prefs.getString(kAuthTokenKey), 'test-token');
  });

  testWidgets('does not show the dialog when a token is already set',
      (tester) async {
    // Seed the preferences with a token so the auth store bootstraps with
    // it; the host should not open the dialog.
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
  });
}
