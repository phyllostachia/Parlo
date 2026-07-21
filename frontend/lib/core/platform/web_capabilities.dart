/// The web implementation of [PlatformCapabilities].
///
/// On the web the mouse can drag images onto the input, and messages reveal
/// their action bar on hover. The backend address is collected by the token
/// dialog on every platform, so there is no web-specific flag for it.
library;

import 'platform_capabilities.dart';

/// Web platform capabilities.
class WebPlatformCapabilities implements PlatformCapabilities {
  /// Creates web capabilities.
  const WebPlatformCapabilities();

  @override
  bool get canDragImage => true;

  @override
  MessageActionsMode get messageActions => MessageActionsMode.hover;
}
