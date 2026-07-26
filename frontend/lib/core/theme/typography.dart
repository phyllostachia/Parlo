/// Parlo 应用的 UI typography。
///
/// 字体角色和对话正文/代码字体样式统一定义在 [fonts.dart]；本文件只负责把 UI
/// 字体映射到 Flutter 的 [TextTheme]。
///
/// Design 的 type scale（design.md “Type Scale”）映射到 Flutter 的 [TextTheme]，使标准
/// text style 自动获得正确的 family、size 和 weight。
library;

import 'package:flutter/material.dart';

import 'fonts.dart';

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
      fontFamily: ParloFonts.displayFamily,
      fontSize: 30,
      fontWeight: FontWeight.w400,
      height: 1.2,
      color: carbonInk,
    ),
    // Section header 和 plan name（serif）。
    headlineMedium: TextStyle(
      fontFamily: ParloFonts.displayFamily,
      fontSize: 24,
      fontWeight: FontWeight.w400,
      height: 1.33,
      color: carbonInk,
    ),
    // 较小字号的 serif 用法（例如强调 sidebar profile name）。
    headlineSmall: TextStyle(
      fontFamily: ParloFonts.displayFamily,
      fontSize: 24,
      fontWeight: FontWeight.w400,
      height: 1.33,
      color: carbonInk,
    ),

    // Body text：16px 和 14px 是两个常用 size。
    bodyLarge: TextStyle(
      fontFamily: ParloFonts.uiFamily,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: graphite,
    ),
    bodyMedium: TextStyle(
      fontFamily: ParloFonts.uiFamily,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: graphite,
    ),
    bodySmall: TextStyle(
      fontFamily: ParloFonts.uiFamily,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: ashen,
    ),

    // Button、nav link 和强调的 label。
    labelLarge: TextStyle(
      fontFamily: ParloFonts.uiFamily,
      fontSize: 15,
      fontWeight: FontWeight.w500,
      height: 1.33,
      color: graphite,
    ),
    labelMedium: TextStyle(
      fontFamily: ParloFonts.uiFamily,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.33,
      color: ashen,
    ),
    // Caption / fine print。
    labelSmall: TextStyle(
      fontFamily: ParloFonts.uiFamily,
      fontSize: 11,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: ashen,
    ),

    // Title：sans、medium weight。
    titleLarge: TextStyle(
      fontFamily: ParloFonts.uiFamily,
      fontSize: 18,
      fontWeight: FontWeight.w500,
      height: 1.33,
      color: carbonInk,
    ),
    titleMedium: TextStyle(
      fontFamily: ParloFonts.uiFamily,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.33,
      color: carbonInk,
    ),
    titleSmall: TextStyle(
      fontFamily: ParloFonts.uiFamily,
      fontSize: 14,
      fontWeight: ParloFonts.uiHeavy,
      height: 1.33,
      color: carbonInk,
    ),
  );
}
