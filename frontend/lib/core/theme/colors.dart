/// The color palette from `design.md`, exposed both as a [ThemeExtension] and
/// as a standard [ColorScheme].
///
/// The design uses warm neutrals plus one decorative accent (clay). v1 ships
/// only the light palette; a dark palette will follow in Phase 9 once the
/// designer adds the dark tokens.
library;

import 'package:flutter/material.dart';

/// The 11 design colors, plus clay, available on [ThemeData] as an extension.
///
/// Widgets read these via `Theme.of(context).extension<ParloColors>()!` so the
/// hex values live in one place. The [ColorScheme] below carries the few of
/// these that map cleanly onto Material's slots; everything else lives here.
@immutable
class ParloColors extends ThemeExtension<ParloColors> {
  /// Creates the full palette.
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

  /// The light palette from `design.md`.
  ///
  /// `obsidian` is included for completeness but is unused in v1 (the design
  /// only uses it for the footer, and Parlo has no footer).
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

  /// Page canvas, sidebar background, large flat areas.
  final Color boneParchment;

  /// Elevated card surfaces that sit on the parchment canvas.
  final Color paperWhite;

  /// Nested cards and alternate section bands.
  final Color softStone;

  /// Primary text, headings, icon fills. A warm near-black, not pure black.
  final Color carbonInk;

  /// Secondary text, button text, nav text.
  final Color graphite;

  /// Muted helper text, captions, fine print.
  final Color ashen;

  /// Tertiary text, copyright, low-priority labels.
  final Color pebble;

  /// Hairline dividers and subtle border lines.
  final Color mist;

  /// Decorative illustration fills and soft background tints.
  final Color chalk;

  /// The only true black in the palette. Footer-only; unused in v1.
  final Color obsidian;

  /// Orange decorative accent for icons and small marks. Never used as a
  /// primary button or link color (design "Don'ts").
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
    // No dark theme yet, so no interpolation is needed. When a dark palette
    // arrives in Phase 9, replace this with Color.lerp on every field.
    return this;
  }
}

/// Builds the v1 light [ColorScheme].
///
/// The mapping follows the architecture (section 9): the parchment canvas is
/// `surface`, the warm near-black is `onSurface` and `primary`, and the white
/// is `onPrimary`. The remaining palette colors live on [ParloColors].
ColorScheme buildLightColorScheme() {
  const c = ParloColors.light;
  return ColorScheme.light(
    // The warm parchment page canvas.
    surface: c.boneParchment,
    // A slightly darker variant of the surface, used by some Material widgets
    // for nested areas. Soft stone matches the design's nested card color.
    surfaceContainerHighest: c.softStone,
    // Text and icons on the parchment surface.
    onSurface: c.carbonInk,
    // Secondary text (captions, helper text).
    onSurfaceVariant: c.graphite,
    // The "filled dark button" from the design: carbon-ink fill, white text.
    primary: c.carbonInk,
    onPrimary: c.paperWhite,
    // Outlined buttons and hairline borders use mist.
    outline: c.mist,
    outlineVariant: c.chalk,
  );
}
