/// Widget tests for the settings panel.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:parlo/core/auth/auth_providers.dart';
import 'package:parlo/core/auth/auth_store.dart';
import 'package:parlo/core/network/base_url_store.dart';
import 'package:parlo/core/theme/app_theme.dart';
import 'package:parlo/features/sidebar/settings_panel.dart';

void main() {
  testWidgets('matches the desktop panel layout and saves all settings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues(<String, Object>{
      kAuthTokenKey: 'previous-token',
      kBaseUrlKey: 'http://localhost:8000',
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => const SettingsPanelDialog(),
                  ),
                  child: const Text('Open settings'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byKey(const ValueKey('settings-modal'))),
      const Size(720, 700),
    );
    expect(find.text('Clear token'), findsNothing);
    expect(find.text('Clear address'), findsNothing);
    expect(find.text('Save'), findsOneWidget);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'updated-token');
    await tester.enterText(fields.at(1), 'api.example.com');
    await tester.enterText(fields.at(2), '8443');
    await tester.pump();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsNothing);
    expect(prefs.getString(kAuthTokenKey), 'updated-token');
    expect(prefs.getString(kBaseUrlKey), 'https://api.example.com:8443');
  });
}
