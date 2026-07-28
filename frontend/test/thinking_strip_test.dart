/// Thinking trace 的紧凑与展开式呈现。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tan/core/theme/app_theme.dart';
import 'package:tan/features/chat/thinking_strip.dart';

void main() {
  testWidgets('shows a compact elapsed label and animates the reasoning open', (
    tester,
  ) async {
    const reasoning = '先确认题目要求，再检查论据与主题句的关联。';

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const Scaffold(
          body: ThinkingStrip(
            reasoning: reasoning,
            reasoningDuration: Duration(seconds: 12),
            isStreaming: false,
          ),
        ),
      ),
    );

    expect(find.text('已思考 12 秒'), findsOneWidget);
    expect(find.text(reasoning), findsNothing);

    await tester.tap(find.text('已思考 12 秒'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text(reasoning), findsOneWidget);
    expect(find.byIcon(Icons.expand_more), findsOneWidget);
  });
}
