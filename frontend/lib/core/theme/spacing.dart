/// Spacing and corner-radius tokens, exposed as a [ThemeExtension] so widgets
/// can write `Theme.of(context).extension<ParloSpacing>()!.s16` instead of
/// hardcoding 16.
///
/// The base unit is 8px (design.md "Spacing & Shapes"). Every value in the
/// scale is a multiple of 8. Corner radii are kept separately because they are
/// not "spacing" semantically.
library;

import 'package:flutter/material.dart';

/// The 8px-based spacing scale from `design.md`.
@immutable
class ParloSpacing extends ThemeExtension<ParloSpacing> {
  /// Creates the spacing scale.
  const ParloSpacing({
    required this.s8,
    required this.s16,
    required this.s24,
    required this.s32,
    required this.s40,
    required this.s64,
    required this.s80,
    required this.s96,
  });

  /// The design's spacing scale.
  static const light = ParloSpacing(
    s8: 8,
    s16: 16,
    s24: 24,
    s32: 32,
    s40: 40,
    s64: 64,
    s80: 80,
    s96: 96,
  );

  /// 8px — the base unit, used for tight gaps inside a component.
  final double s8;
  /// 16px — medium gaps between elements.
  final double s16;
  /// 24px — padding inside a card or accordion.
  final double s24;
  /// 32px — card padding (design.md).
  final double s32;
  /// 40px — gap between major sections when slightly tighter than 64.
  final double s40;
  /// 64px — standard section gap.
  final double s64;
  /// 80px — wide section gap.
  final double s80;
  /// 96px — very wide section gap.
  final double s96;

  @override
  ParloSpacing copyWith({
    double? s8,
    double? s16,
    double? s24,
    double? s32,
    double? s40,
    double? s64,
    double? s80,
    double? s96,
  }) {
    return ParloSpacing(
      s8: s8 ?? this.s8,
      s16: s16 ?? this.s16,
      s24: s24 ?? this.s24,
      s32: s32 ?? this.s32,
      s40: s40 ?? this.s40,
      s64: s64 ?? this.s64,
      s80: s80 ?? this.s80,
      s96: s96 ?? this.s96,
    );
  }

  @override
  ParloSpacing lerp(ParloSpacing? other, double t) => this;
}

/// The corner-radius scale from `design.md`.
@immutable
class ParloRadius extends ThemeExtension<ParloRadius> {
  /// Creates the radius scale.
  const ParloRadius({
    required this.nav,
    required this.input,
    required this.button,
    required this.card,
    required this.elevatedCard,
  });

  /// The design's radius scale.
  static const light = ParloRadius(
    // Nav links, inputs, buttons all share 8px in the design.
    nav: 8,
    input: 8,
    button: 8,
    // Cards are 16px; elevated/featured cards are 24px.
    card: 16,
    elevatedCard: 24,
  );

  /// 8px — nav links.
  final double nav;
  /// 8px — input fields.
  final double input;
  /// 8px — buttons.
  final double button;
  /// 16px — nested/secondary cards.
  final double card;
  /// 24px — elevated and featured cards.
  final double elevatedCard;

  @override
  ParloRadius copyWith({
    double? nav,
    double? input,
    double? button,
    double? card,
    double? elevatedCard,
  }) {
    return ParloRadius(
      nav: nav ?? this.nav,
      input: input ?? this.input,
      button: button ?? this.button,
      card: card ?? this.card,
      elevatedCard: elevatedCard ?? this.elevatedCard,
    );
  }

  @override
  ParloRadius lerp(ParloRadius? other, double t) => this;
}
