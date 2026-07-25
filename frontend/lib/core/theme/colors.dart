/// `design.md` 中的 color palette，同时以 [ThemeExtension] 和标准 [ColorScheme] 暴露。
///
/// Design 使用暖色中性色和一个装饰 accent（clay）。v1 只提供 light palette；设计师补充
/// dark token 后，dark palette 会在阶段 9 加入。
library;

import 'package:flutter/material.dart';

/// 11 个 design color 加上 clay，以 extension 形式在 [ThemeData] 上提供。
///
/// Widget 通过 `Theme.of(context).extension<ParloColors>()!` 读取这些 value，使 hex value
/// 只保存在一个位置。下面的 [ColorScheme] 携带其中能够自然映射到 Material slot 的 value，
/// 其余 value 都保存在这里。
@immutable
class ParloColors extends ThemeExtension<ParloColors> {
  /// 创建完整 palette。
  const ParloColors({
    required this.boneParchment,
    required this.paperWhite,
    required this.softStone,
    required this.carbonInk,
    required this.graphite,
    required this.ashen,
    required this.pebble,
    required this.mist,
    required this.chalk,
    required this.obsidian,
    required this.clay,
  });

  /// `design.md` 中的 light palette。
  ///
  /// `obsidian` 为完整性而保留，但 v1 未使用（design 只将它用于 footer，而 Parlo 没有 footer）。
  static const light = ParloColors(
    boneParchment: Color(0xFFF8F8F6),
    paperWhite: Color(0xFFFFFFFF),
    softStone: Color(0xFFEFEEEB),
    carbonInk: Color(0xFF121212),
    graphite: Color(0xFF373734),
    ashen: Color(0xFF7B7974),
    pebble: Color(0xFF9C9A92),
    mist: Color(0xFFB7B7B5),
    chalk: Color(0xFFE7E6E1),
    obsidian: Color(0xFF000000),
    clay: Color(0xFFD97757),
  );

  /// Page canvas、sidebar background、大面积 flat area。
  final Color boneParchment;

  /// 位于 parchment canvas 上方的 elevated card surface。
  final Color paperWhite;

  /// Nested card 和 alternate section band。
  final Color softStone;

  /// Primary text、heading、icon fill。是暖近黑色，而不是纯黑。
  final Color carbonInk;

  /// Secondary text、button text、nav text。
  final Color graphite;

  /// Muted helper text、caption、fine print。
  final Color ashen;

  /// Tertiary text、copyright、低优先级 label。
  final Color pebble;

  /// Hairline divider 和细微 border line。
  final Color mist;

  /// Decorative illustration fill 和柔和 background tint。
  final Color chalk;

  /// Palette 中唯一的纯黑色。只用于 footer；v1 未使用。
  final Color obsidian;

  /// 用于 icon 和 small mark 的橙色 decorative accent。绝不作为 primary button 或 link
  /// color（design “Don'ts”）。
  final Color clay;

  @override
  ParloColors copyWith({
    Color? boneParchment,
    Color? paperWhite,
    Color? softStone,
    Color? carbonInk,
    Color? graphite,
    Color? ashen,
    Color? pebble,
    Color? mist,
    Color? chalk,
    Color? obsidian,
    Color? clay,
  }) {
    return ParloColors(
      boneParchment: boneParchment ?? this.boneParchment,
      paperWhite: paperWhite ?? this.paperWhite,
      softStone: softStone ?? this.softStone,
      carbonInk: carbonInk ?? this.carbonInk,
      graphite: graphite ?? this.graphite,
      ashen: ashen ?? this.ashen,
      pebble: pebble ?? this.pebble,
      mist: mist ?? this.mist,
      chalk: chalk ?? this.chalk,
      obsidian: obsidian ?? this.obsidian,
      clay: clay ?? this.clay,
    );
  }

  @override
  ParloColors lerp(ParloColors? other, double t) {
    if (other is! ParloColors) return this;
    // 当前还没有 dark theme，因此不需要 interpolation。阶段 9 加入 dark palette 后，
    // 将这里替换为每个 field 的 Color.lerp。
    return this;
  }
}

/// 构建 v1 light [ColorScheme]。
///
/// 映射遵循架构（第 9 节）：parchment canvas 是 `surface`，暖近黑色是 `onSurface` 和
/// `primary`，白色是 `onPrimary`。其余 palette color 位于 [ParloColors] 上。
ColorScheme buildLightColorScheme() {
  const c = ParloColors.light;
  return ColorScheme.light(
    // 暖色 parchment page canvas。
    surface: c.boneParchment,
    // 稍深的 surface variant，供一些 Material widget 用于 nested area。Soft stone 匹配
    // design 的 nested card color。
    surfaceContainerHighest: c.softStone,
    // Parchment surface 上的 text 和 icon。
    onSurface: c.carbonInk,
    // Secondary text（caption、helper text）。
    onSurfaceVariant: c.graphite,
    // Design 中的“filled dark button”：carbon-ink fill、white text。
    primary: c.carbonInk,
    onPrimary: c.paperWhite,
    // Outlined button 和 hairline border 使用 mist。
    outline: c.mist,
    outlineVariant: c.chalk,
  );
}
