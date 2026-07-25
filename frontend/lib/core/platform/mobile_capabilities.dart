/// [PlatformCapabilities] 的 mobile 实现。
///
/// 在 mobile（Android 和 iOS）上：
/// - Touch drag 用于排序而不是 file drop，因此 image input 不注册 drop zone。Mobile 改用
///   attach button 和 system file picker。
/// - 没有 hover，因此 message action bar（copy、regenerate）始终显示在 assistant message 末尾。
///
/// 所有 platform 都由 token dialog 收集 backend address，因此不需要 mobile-specific flag。
library;

import 'platform_capabilities.dart';

/// Mobile platform capabilities（Android 和 iOS）。
class MobilePlatformCapabilities implements PlatformCapabilities {
  /// 创建 mobile capabilities。
  const MobilePlatformCapabilities();

  @override
  bool get canDragImage => false;

  @override
  MessageActionsMode get messageActions => MessageActionsMode.always;
}
