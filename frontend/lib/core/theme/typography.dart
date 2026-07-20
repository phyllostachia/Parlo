/// Typography for the Parlo app.
///
/// Two font families, both self-hosted in `assets/fonts/` (see `pubspec.yaml`):
/// - Source Serif 4 (called `SourceSerif4` in the font family) for display
///   headlines only.
/// - Inter (called `Inter`) for everything else.
///
/// The design's type scale (design.md "Type Scale") is mapped onto Flutter's
/// [TextTheme] so standard text styles pick up the right family, size, and
/// weight automatically.
library;

import 'package:flutter/material.dart';

/// The font family name for Source Serif 4, as declared in `pubspec.yaml`.
const String kSerifFamily = 'SourceSerif4';

/// The font family name for Inter, as declared in `pubspec.yaml`.
const String kSansFamily = 'Inter';

/// The heaviest sans weight the design uses.
///
/// The design calls this weight "580". Flutter only accepts standard 100-step
/// weights in `pubspec.yaml`, so the 580-weight Inter file is exposed at the
/// 600 slot. Using this constant keeps the intent readable in code while
/// pulling the glyphs from the right file.
const FontWeight kInterHeavy = FontWeight.w600;

/// Builds the v1 light [TextTheme].
///
/// The mapping follows design.md "Type Scale":
/// - display / heading (30px serif): [TextTheme.displayLarge]
/// - heading-sm (24px serif): [TextTheme.headlineMedium]
/// - body (14-16px sans): [TextTheme.bodyLarge] / [TextTheme.bodyMedium]
/// - caption (11px sans): [TextTheme.labelSmall]
///
/// The colors are set here so widgets using `Theme.of(context).textTheme.X`
/// get the right color without restating it. Widgets that need a different
/// color (e.g. muted helper text) override `style.color` locally.
TextTheme buildTextTheme(Color carbonInk, Color graphite, Color ashen) {
  return TextTheme(
    // Display / editorial hero headlines (serif).
    displayLarge: TextStyle(
      fontFamily: kSerifFamily,
      fontSize: 30,
      fontWeight: FontWeight.w400,
      height: 1.2,
      color: carbonInk,
    ),
    // Section headers and plan names (serif).
    headlineMedium: TextStyle(
      fontFamily: kSerifFamily,
      fontSize: 24,
      fontWeight: FontWeight.w400,
      height: 1.33,
      color: carbonInk,
    ),
    // Smaller serif usage (e.g. sidebar profile names when emphasised).
    headlineSmall: TextStyle(
      fontFamily: kSerifFamily,
      fontSize: 24,
      fontWeight: FontWeight.w400,
      height: 1.33,
      color: carbonInk,
    ),

    // Body text — 16px and 14px are the two workhorse sizes.
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

    // Buttons, nav links, and emphasised labels.
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
    // Caption / fine print.
    labelSmall: TextStyle(
      fontFamily: kSansFamily,
      fontSize: 11,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: ashen,
    ),

    // Titles — sans, medium weight.
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
