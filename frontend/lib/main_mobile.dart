/// The mobile entry point for the Parlo app (Android and iOS).
///
/// Run with `flutter run -t lib/main_mobile.dart` to start the app with the
/// mobile platform capabilities. The mobile build systems (`android/` and
/// `ios/`) can be configured to point at this entry point so a normal
/// `flutter run` on a device uses it automatically.
///
/// This file mirrors [main.dart] (the web entry point) and adds one override:
/// [platformCapabilitiesProvider] is replaced with [MobilePlatformCapabilities]
/// so the rest of the app gets the mobile behavior (no drag-and-drop,
/// always-visible message actions) without touching feature code.
///
/// The backend address is collected by the token dialog and the settings panel
/// on every platform, so no capability flag is needed for it. The base URL
/// provider reads from the persisted store, so the dio client picks the new
/// host up automatically.
///
/// Note: this entry point is analyzable and compiles, but the device build
/// (Android APK / iOS IPA) has not been run in this session. Verifying the
/// mobile build requires a connected device or emulator and is left to a
/// dedicated mobile verification pass.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/auth/auth_providers.dart';
import 'core/platform/mobile_capabilities.dart';
import 'core/platform/platform_providers.dart';

/// Starts the Parlo app with mobile platform capabilities.
Future<void> main() async {
  // Required before any async work that touches platform channels, including
  // `SharedPreferences.getInstance()`.
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        // Hand the real preferences instance to the rest of the app.
        sharedPreferencesProvider.overrideWithValue(prefs),
        // Swap in the mobile capabilities so the UI hides the drag zone and
        // keeps message actions visible.
        platformCapabilitiesProvider
            .overrideWithValue(const MobilePlatformCapabilities()),
      ],
      child: const ParloApp(),
    ),
  );
}
