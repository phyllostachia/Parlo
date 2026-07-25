/// Parlo 应用的 typography。
///
/// 两个 font family 都 self-hosted 在 `assets/fonts/` 中（参见 `pubspec.yaml`）：
/// - Source Serif 4（font family 中称为 `SourceSerif4`）仅用于 display headline。
/// - Inter（称为 `Inter`）用于其他所有内容。
///
/// Design 的 type scale（design.md “Type Scale”）映射到 Flutter 的 [TextTheme]，使标准
/// text style 自动获得正确的 family、size 和 weight。
library;

import 'package:flutter/material.dart';

/// `pubspec.yaml` 中声明的 Source Serif 4 font family name。
const String kSerifFamily = 'SourceSerif4';

/// `pubspec.yaml` 中声明的 Inter font family name。
const String kSansFamily = 'Inter';

/// Design 使用的最大 sans weight。
///
/// Design 将此 weight 称为“580”。Flutter 在 `pubspec.yaml` 中只接受标准的 100-step
/// weight，因此 580-weight Inter file 暴露在 600 slot。使用此 constant 可以让代码中的
/// 意图清晰，同时从正确的 file 获取 glyph。
const FontWeight kInterHeavy = FontWeight.w600;

/// 构建 v1 light [TextTheme]。
///
/// 映射遵循 design.md “Type Scale”：
/// - display / heading (30px serif): [TextTheme.displayLarge]
/// - heading-sm (24px serif): [TextTheme.headlineMedium]
/// - body (14-16px sans): [TextTheme.bodyLarge] / [TextTheme.bodyMedium]
/// - caption (11px sans): [TextTheme.labelSmall]
///
/// Color 在这里设置，使使用 `Theme.of(context).textTheme.X` 的 widget 无需重复声明即可
/// 获得正确 color。需要其他 color 的 widget（例如 muted helper text）在本地 override
/// `style.color`。
TextTheme buildTextTheme(Color carbonInk, Color graphite, Color ashen) {
  return TextTheme(
    // Display / editorial hero headline（serif）。
    displayLarge: TextStyle(
      fontFamily: kSerifFamily,
      fontSize: 30,
      fontWeight: FontWeight.w400,
      height: 1.2,
      color: carbonInk,
    ),
    // Section header 和 plan name（serif）。
    headlineMedium: TextStyle(
      fontFamily: kSerifFamily,
      fontSize: 24,
      fontWeight: FontWeight.w400,
      height: 1.33,
      color: carbonInk,
    ),
    // 较小字号的 serif 用法（例如强调 sidebar profile name）。
    headlineSmall: TextStyle(
      fontFamily: kSerifFamily,
      fontSize: 24,
      fontWeight: FontWeight.w400,
      height: 1.33,
      color: carbonInk,
    ),

    // Body text：16px 和 14px 是两个常用 size。
    bodyLarge: TextStyle(
      fontFamily: kSansFamily,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: graphite,
    ),
    bodyMedium: TextStyle(
      fontFamily: kSansFamily,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: graphite,
    ),
    bodySmall: TextStyle(
      fontFamily: kSansFamily,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: ashen,
    ),

    // Button、nav link 和强调的 label。
    labelLarge: TextStyle(
      fontFamily: kSansFamily,
      fontSize: 15,
      fontWeight: FontWeight.w500,
      height: 1.33,
      color: graphite,
    ),
    labelMedium: TextStyle(
      fontFamily: kSansFamily,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.33,
      color: ashen,
    ),
    // Caption / fine print。
    labelSmall: TextStyle(
      fontFamily: kSansFamily,
      fontSize: 11,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: ashen,
    ),

    // Title：sans、medium weight。
    titleLarge: TextStyle(
      fontFamily: kSansFamily,
      fontSize: 18,
      fontWeight: FontWeight.w500,
      height: 1.33,
      color: carbonInk,
    ),
    titleMedium: TextStyle(
      fontFamily: kSansFamily,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.33,
      color: carbonInk,
    ),
    titleSmall: TextStyle(
      fontFamily: kSansFamily,
      fontSize: 14,
      fontWeight: kInterHeavy,
      height: 1.33,
      color: carbonInk,
    ),
  );
}
