/// Widget tests for the token + backend address dialog.
///
/// The dialog is shown by [TokenDialogHost], which watches the auth store and
/// the base URL store and opens the dialog when there is no token, the token
/// was flagged as unauthorized, or the base URL is empty. These tests verify
/// each trigger and that saving both values closes the dialog.
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

    // The dialog opens because no token has been set yet. The headline is the
    // "first use" variant.
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

    // The dialog has three text fields: domain, port, token (in order).
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

    // The dialog closes after both values are written and the stores notify
    // the host.
    expect(find.text('Welcome to Parlo'), findsNothing);

    // The token and base URL were both persisted to SharedPreferences.
    expect(prefs.getString(kAuthTokenKey), 'test-token');
    expect(prefs.getString(kBaseUrlKey), 'https://parlo.example.com:8000');
  });

  testWidgets(
      'does not show the dialog when both a token and an address are set',
      (tester) async {
    // Seed the preferences with a token and a base URL so both stores
    // bootstrap with them; the host should not open the dialog.
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
  });

  testWidgets('shows the "backend address" dialog when only the token is set',
      (tester) async {
    // Seed only the token; the base URL is still missing, so the dialog
    // should appear with the "set your backend address" headline (not the
    // first-use "Welcome" headline, because the user already has a token).
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

  testWidgets('Save button stays disabled until all fields are filled',
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

    // The Save button is disabled (onPressed is null) when fields are empty.
    FilledButton saveButton() =>
        tester.widget<FilledButton>(find.byType(FilledButton));
    expect(saveButton().onPressed, isNull);

    // Fill only the token — Save stays disabled because the address is
    // still missing.
    final fields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.at(2), 'test-token');
    await tester.pump();
    expect(saveButton().onPressed, isNull);

    // Fill the domain — Save still disabled because the port is missing.
    await tester.enterText(fields.at(0), 'parlo.example.com');
    await tester.pump();
    expect(saveButton().onPressed, isNull);

    // Fill the port — Save is now enabled.
    await tester.enterText(fields.at(1), '8000');
    await tester.pump();
    expect(saveButton().onPressed, isNotNull);
  });
}
