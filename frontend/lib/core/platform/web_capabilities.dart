/// The web implementation of [PlatformCapabilities].
///
/// On the web, the app is served from the same origin as the API, so the user
/// never needs to enter a backend URL. The mouse can drag images onto the
/// input, and messages reveal their action bar on hover.
library;

import 'platform_capabilities.dart';

/// Web platform capabilities.
class WebPlatformCapabilities implements PlatformCapabilities {
  /// Creates web capabilities.
  const WebPlatformCapabilities();

  @override
  bool get canInputBackendUrl => false;

  @override
  bool get canDragImage => true;

  @override
  MessageActionsMode get messageActions => MessageActionsMode.hover;
}
