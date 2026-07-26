/// Parlo 应用组装后的 v1 light [ThemeData]。
///
/// 组合 [ColorScheme]（colors.dart）、[TextTheme]（typography.dart）以及 spacing/radius
/// extension（spacing.dart）。Component theme（Card、AppBar 等）经过调整，以匹配
/// `design.md` 中的“printed-paper” aesthetic：hairline border、充足 radius、不使用厚重 shadow。
library;

import 'package:flutter/material.dart';

import 'colors.dart';
import 'fonts.dart';
import 'spacing.dart';
import 'typography.dart';

/// Card 在 hover 或 featured 时使用的 shadow。
///
/// 来自 `design.md` 的“Shadows”：4% opacity 的柔和 4px-20px wash。设计不会使用更厚重的 shadow。
const List<BoxShadow> kParloCardShadow = [
  BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.04),
    blurRadius: 20,
    offset: Offset(0, 4),
  ),
];

/// 构建 v1 light [ThemeData]。
ThemeData buildAppTheme() {
  const colors = ParloColors.light;
  final colorScheme = buildLightColorScheme();
  final textTheme = buildTextTheme(
    colors.carbonInk,
    colors.graphite,
    colors.ashen,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    // UI 字体固定；display serif 和对话正文/代码字体由各自的 TextStyle 覆盖。
    fontFamily: ParloFonts.uiFamily,
    textTheme: textTheme,
    scaffoldBackgroundColor: colors.boneParchment,
    // 通过 ThemeData extension 将 spacing 和 radius scale 提供给 widget。
    extensions: const [
      ParloColors.light,
      ParloSpacing.light,
      ParloRadius.light,
    ],
    // Card：paper-white surface、16px radius，默认无 shadow，使用 hairline border。匹配
    // design 的 flat printed-paper look。
    cardTheme: CardThemeData(
      color: colors.paperWhite,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ParloRadius.light.card),
        side: BorderSide(color: colors.chalk, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    // App bar：透明且平面，不使用 shadow。
    appBarTheme: AppBarTheme(
      backgroundColor: colors.boneParchment,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: textTheme.titleMedium,
    ),
    // Button：8px radius，不使用 uppercase，label 使用 medium weight。
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colors.carbonInk,
        foregroundColor: colors.paperWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ParloRadius.light.button),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.graphite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ParloRadius.light.button),
        ),
        side: BorderSide(color: colors.mist, width: 1),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colors.graphite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ParloRadius.light.button),
        ),
      ),
    ),
    // Input field：透明 fill、8px radius、mist border。
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.paperWhite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ParloRadius.light.input),
        borderSide: BorderSide(color: colors.mist, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ParloRadius.light.input),
        borderSide: BorderSide(color: colors.mist, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ParloRadius.light.input),
        borderSide: BorderSide(color: colors.graphite, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      labelStyle: textTheme.bodyMedium,
      hintStyle: textTheme.bodyMedium?.copyWith(color: colors.pebble),
    ),
    // Divider：hairline mist。
    dividerTheme: DividerThemeData(color: colors.mist, thickness: 1, space: 1),
  );
}
