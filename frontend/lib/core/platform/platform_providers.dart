/// 向应用其余部分提供 [PlatformCapabilities] 的 Riverpod provider。
///
/// 默认使用 Web 实现。Mobile 在 `main_mobile.dart` 中通过 `ProviderScope.overrides` override
/// 此 provider（计划的阶段 8）。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'platform_capabilities.dart';
import 'web_capabilities.dart';

/// 当前运行应用的平台 capabilities。
///
/// 默认使用 [WebPlatformCapabilities]。Mobile 在启动时 override 此 provider，使应用其余
/// 部分获得 mobile implementation，而无需修改任何 feature code。
final platformCapabilitiesProvider = Provider<PlatformCapabilities>((ref) {
  return const WebPlatformCapabilities();
});
