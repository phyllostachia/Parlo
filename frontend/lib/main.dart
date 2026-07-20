/// Entry point for the Parlo Flutter frontend.
///
/// The app is wrapped in a [ProviderScope] so every Riverpod provider has a
/// container to live in. Fonts are declared in `pubspec.yaml` and registered
/// by Flutter automatically, so there is no manual font registration here.
///
/// We eagerly load [SharedPreferences] before `runApp` and override the
/// `sharedPreferencesProvider` with the instance. The auth store reads it
/// synchronously afterwards, so the token can be restored without an async
/// wait at first paint.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/auth/auth_providers.dart';

/// Starts the Parlo app.
///
/// Keeping `main` tiny makes the app easier to test: a test can construct a
/// [ParloApp] widget directly and pump it without running `main`.
Future<void> main() async {
  // Required before any async work that touches platform channels, including
  // `SharedPreferences.getInstance()`.
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        // Hand the real preferences instance to the rest of the app. The
        // default factory in `auth_providers.dart` throws, so forgetting this
        // override fails loudly.
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const ParloApp(),
    ),
  );
}
