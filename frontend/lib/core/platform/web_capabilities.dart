/// [PlatformCapabilities] 的 Web 实现。
///
/// Web 上 mouse 可以将图片拖到 input，message 会在 hover 时显示 action bar。所有 platform
/// 都由 token dialog 收集 backend address，因此不需要 Web-specific flag。
library;

import 'platform_capabilities.dart';

/// Web platform capabilities。
class WebPlatformCapabilities implements PlatformCapabilities {
  /// 创建 Web capabilities。
  const WebPlatformCapabilities();

  @override
  bool get canDragImage => true;

  @override
  MessageActionsMode get messageActions => MessageActionsMode.hover;
}
