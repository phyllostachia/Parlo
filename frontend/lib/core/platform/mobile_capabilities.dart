/// The mobile implementation of [PlatformCapabilities].
///
/// On mobile (Android and iOS):
/// - The app is not same-origin with the API, so the user must enter a
///   backend URL. The token dialog shows the field because
///   [canInputBackendUrl] is `true`.
/// - Touch drag is for reordering, not file drop, so the image input does not
///   register a drop zone. Mobile uses the attach button and the system file
///   picker instead.
/// - There is no hover, so the message action bar (copy, regenerate) is
///   always visible at the end of an assistant message.
library;

import 'platform_capabilities.dart';

/// Mobile platform capabilities (Android and iOS).
class MobilePlatformCapabilities implements PlatformCapabilities {
  /// Creates mobile capabilities.
  const MobilePlatformCapabilities();

  @override
  bool get canInputBackendUrl => true;

  @override
  bool get canDragImage => false;

  @override
  MessageActionsMode get messageActions => MessageActionsMode.always;
}
