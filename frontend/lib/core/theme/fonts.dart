/// Tan 的字体配置。
///
/// 字体按使用场景分为三类：
/// - [uiFamily]：应用 UI 字体。它是产品的一部分，不随用户设置变化。
/// - [naturalLanguageFamily]：对话中的自然语言字体，供用户消息和 AI 回复使用。
/// - [codeFamily]：Markdown 代码块和行内代码使用的等宽字体。
///
/// 字体文件由 `pubspec.yaml` 注册。代码字体来自 `gpt_markdown` 自带的字体资源，
/// 因此需要同时指定 [codePackage] 才能在应用中正确解析。
library;

import 'package:flutter/material.dart';

/// 应用的字体配置。
///
/// 所有字段和样式都是 [const]，避免字体配置在运行时被 widget 局部修改。UI 字体
/// 尤其是固定的；自然语言和代码字体的入口集中在这里，后续如需更换字体只需修改本文件。
abstract final class TanFonts {
  /// UI 字体：固定使用 Source Han Serif SC，不提供用户可变配置。
  static const String uiFamily = 'SourceHanSerifSC';

  /// UI display 标题使用的思源宋体。
  static const String displayFamily = 'SourceHanSerifSC';

  /// 对话中用户消息和 AI 回复的自然语言字体。
  ///
  /// 使用 Source Han Serif SC；Medium/Bold 字重在 `pubspec.yaml` 中注册。
  static const String naturalLanguageFamily = 'SourceHanSerifSC';

  /// gpt_markdown 包内注册的代码字体。
  static const String codeFamily = 'JetBrainsMono';

  /// [codeFamily] 所属的 package。应用自身没有重复打包这套字体。
  static const String codePackage = 'gpt_markdown';

  /// UI 使用的最大字重。设计令牌中的 580 在 Flutter 中映射到 600 插槽。
  static const FontWeight uiHeavy = FontWeight.w600;

  /// 对话自然语言正文的基础样式。
  static const TextStyle naturalLanguageStyle = TextStyle(
    fontFamily: naturalLanguageFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  /// Markdown 代码块和行内代码的基础样式。
  static const TextStyle codeStyle = TextStyle(
    fontFamily: codeFamily,
    package: codePackage,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );
}
