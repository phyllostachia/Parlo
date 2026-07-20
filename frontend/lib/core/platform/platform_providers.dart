/// The Riverpod provider that hands the rest of the app its
/// [PlatformCapabilities].
///
/// The default is the web implementation. Mobile overrides this provider in
/// `main_mobile.dart` via `ProviderScope.overrides` (Phase 8 of the plan).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'platform_capabilities.dart';
import 'web_capabilities.dart';

/// The platform capabilities for the running app.
///
/// Defaults to [WebPlatformCapabilities]. Mobile overrides this provider at
/// startup so the rest of the app gets the mobile implementation without
/// touching any feature code.
final platformCapabilitiesProvider = Provider<PlatformCapabilities>((ref) {
  return const WebPlatformCapabilities();
});
