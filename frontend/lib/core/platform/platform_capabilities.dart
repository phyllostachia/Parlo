/// 应用关心的平台差异，以一个 abstract interface 表达。
///
/// 架构文档（第 8 节）将其称为 `PlatformCapabilities`。它让应用其余部分能够询问“该
/// platform 是否可以 drag image？”或“message action 应在 hover 时还是始终显示？”，而
/// 不需要直接检查 `Platform.isWeb`。Web 实现在 `web_capabilities.dart` 中，mobile 实现
/// 会在阶段 8 加入。
library;

/// 如何显示 message action bar（copy / regenerate）。
enum MessageActionsMode {
  /// 只有 pointer hover 在 message 上时才显示 action。用于始终有精确 pointer 的 Web。
  hover,

  /// Action 始终显示在 message 末尾。用于没有 hover 的 mobile，因为长按不如始终存在的
  /// button row 容易发现。
  always,
}

/// UI 读取的 platform-dependent knob，使应用保持可移植。
///
/// 每个 property 都回答 UI 的一个具体问题。新的 platform difference 应添加到这里，而不
/// 是分散为 `Platform.isXxx` check，使 abstraction surface 保持小而清晰。
abstract class PlatformCapabilities {
  /// chat input 是否接受拖到其上的图片。
  ///
  /// Web 上为 `true`（mouse 可以拖动 file）。Mobile 上为 `false`（touch drag 用于排序，
  /// 而不是 file drop）；mobile 改用 paste + file picker。
  bool get canDragImage;

  /// 如何显示 message action bar（copy / regenerate）。
  ///
  /// Web 上为 [MessageActionsMode.hover]，mobile 上为 [MessageActionsMode.always]。
  MessageActionsMode get messageActions;
}
