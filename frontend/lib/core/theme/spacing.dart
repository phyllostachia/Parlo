/// Spacing 和 corner-radius token，以 [ThemeExtension] 暴露，使 widget 可以写
/// `Theme.of(context).extension<TanSpacing>()!.s16`，而不是 hardcode 16。
///
/// Base unit 是 8px（design.md “Spacing & Shapes”）。Scale 中每个 value 都是 8 的倍数。
/// Corner radius 单独保存，因为从语义上说它不是“spacing”。
library;

import 'package:flutter/material.dart';

/// `design.md` 中基于 8px 的 spacing scale。
@immutable
class TanSpacing extends ThemeExtension<TanSpacing> {
  /// 创建 spacing scale。
  const TanSpacing({
    required this.s8,
    required this.s16,
    required this.s24,
    required this.s32,
    required this.s40,
    required this.s64,
    required this.s80,
    required this.s96,
  });

  /// Design 的 spacing scale。
  static const light = TanSpacing(
    s8: 8,
    s16: 16,
    s24: 24,
    s32: 32,
    s40: 40,
    s64: 64,
    s80: 80,
    s96: 96,
  );

  /// 8px：base unit，用于 component 内部的紧凑 gap。
  final double s8;

  /// 16px：element 之间的中等 gap。
  final double s16;

  /// 24px：card 或 accordion 内部的 padding。
  final double s24;

  /// 32px：card padding（design.md）。
  final double s32;

  /// 40px：major section 之间比 64 更紧凑时使用的 gap。
  final double s40;

  /// 64px：standard section gap。
  final double s64;

  /// 80px：wide section gap。
  final double s80;

  /// 96px：very wide section gap。
  final double s96;

  @override
  TanSpacing copyWith({
    double? s8,
    double? s16,
    double? s24,
    double? s32,
    double? s40,
    double? s64,
    double? s80,
    double? s96,
  }) {
    return TanSpacing(
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
  TanSpacing lerp(TanSpacing? other, double t) => this;
}

/// `design.md` 中的 corner-radius scale。
@immutable
class TanRadius extends ThemeExtension<TanRadius> {
  /// 创建 radius scale。
  const TanRadius({
    required this.nav,
    required this.input,
    required this.button,
    required this.card,
    required this.elevatedCard,
  });

  /// Design 的 radius scale。
  static const light = TanRadius(
    // Design 中 nav link、input、button 都使用 8px。
    nav: 8,
    input: 8,
    button: 8,
    // Card 使用 16px；elevated/featured card 使用 24px。
    card: 16,
    elevatedCard: 24,
  );

  /// 8px：nav link。
  final double nav;

  /// 8px：input field。
  final double input;

  /// 8px：button。
  final double button;

  /// 16px：nested/secondary card。
  final double card;

  /// 24px：elevated 和 featured card。
  final double elevatedCard;

  @override
  TanRadius copyWith({
    double? nav,
    double? input,
    double? button,
    double? card,
    double? elevatedCard,
  }) {
    return TanRadius(
      nav: nav ?? this.nav,
      input: input ?? this.input,
      button: button ?? this.button,
      card: card ?? this.card,
      elevatedCard: elevatedCard ?? this.elevatedCard,
    );
  }

  @override
  TanRadius lerp(TanRadius? other, double t) => this;
}
