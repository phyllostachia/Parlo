/// The platform differences the app cares about, expressed as one abstract
/// interface.
///
/// The architecture (section 8) calls this `PlatformCapabilities`. It lets the
/// rest of the app ask "can this platform drag images?" or "should the message
/// actions appear on hover or always?" without checking `Platform.isWeb` itself.
/// The web implementation lives in `web_capabilities.dart`; a mobile
/// implementation will be added in Phase 8.
library;

/// How the message action bar (copy / regenerate) is shown.
enum MessageActionsMode {
  /// Actions appear only while the pointer hovers over the message. Used on
  /// the web, where a precise pointer is always available.
  hover,

  /// Actions are always visible at the end of the message. Used on mobile,
  /// where there is no hover and a long-press is less discoverable than a
  /// always-there button row.
  always,
}

/// The platform-dependent knobs the UI reads to stay portable.
///
/// Each property answers one concrete question the UI asks. New platform
/// differences should be added here rather than scattered as `Platform.isXxx`
/// checks, so the surface stays small and obvious.
abstract class PlatformCapabilities {
  /// Whether the chat input should accept images dragged onto it.
  ///
  /// `true` on the web (a mouse can drag files). `false` on mobile (touch
  /// drag is for reordering, not file drop); mobile uses paste + file picker
  /// instead.
  bool get canDragImage;

  /// How the message action bar (copy / regenerate) is shown.
  ///
  /// [MessageActionsMode.hover] on the web, [MessageActionsMode.always] on
  /// mobile.
  MessageActionsMode get messageActions;
}
