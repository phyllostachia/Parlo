/// The assembled v1 light [ThemeData] for the Parlo app.
///
/// Pulls together the [ColorScheme] (colors.dart), the [TextTheme]
/// (typography.dart), and the spacing/radius extensions (spacing.dart). The
/// component themes (Card, AppBar, etc.) are tuned to match the
/// "printed-paper" aesthetic from `design.md`: hairline borders, generous
/// radii, no heavy shadows.
library;

import 'package:flutter/material.dart';

import 'colors.dart';
import 'spacing.dart';
import 'typography.dart';

/// The shadow used by cards on hover or when featured.
///
/// From `design.md` "Shadows": a soft 4px-20px wash at 4% opacity. The design
/// never uses heavier shadows.
const List<BoxShadow> kParloCardShadow = [
  BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.04),
    blurRadius: 20,
    offset: Offset(0, 4),
  ),
];

/// Builds the v1 light [ThemeData].
ThemeData buildAppTheme() {
  const colors = ParloColors.light;
  final colorScheme = buildLightColorScheme();
  final textTheme = buildTextTheme(colors.carbonInk, colors.graphite, colors.ashen);

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    // Inter is the default for all text; serif overrides per-style.
    fontFamily: kSansFamily,
    textTheme: textTheme,
    scaffoldBackgroundColor: colors.boneParchment,
    // Hand the spacing and radius scales to widgets via ThemeData extensions.
    extensions: const [
      ParloColors.light,
      ParloSpacing.light,
      ParloRadius.light,
    ],
    // Cards: paper-white surface, 16px radius, no shadow by default, hairline
    // border. Matches the design's flat printed-paper look.
    cardTheme: CardThemeData(
      color: colors.paperWhite,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ParloRadius.light.card),
        side: BorderSide(color: colors.chalk, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    // App bars: transparent and flat, no shadow.
    appBarTheme: AppBarTheme(
      backgroundColor: colors.boneParchment,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: textTheme.titleMedium,
    ),
    // Buttons: 8px radius, no uppercase, medium-weight labels.
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
    // Input fields: transparent fill, 8px radius, mist border.
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
    // Dividers: hairline mist.
    dividerTheme: DividerThemeData(
      color: colors.mist,
      thickness: 1,
      space: 1,
    ),
  );
}
