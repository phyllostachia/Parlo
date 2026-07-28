/// 深度思考开关按钮的 widget 测试。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tan/core/theme/app_theme.dart';
import 'package:tan/features/chat/thinking_toggle_button.dart';

void main() {
  testWidgets('深度思考按钮可切换状态', (tester) async {
    var thinkingEnabled = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: Center(
              child: ThinkingToggleButton(
                enabled: thinkingEnabled,
                onPressed: () => setState(() {
                  thinkingEnabled = !thinkingEnabled;
                }),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('开启深度思考'));
    await tester.pump();

    expect(find.byTooltip('关闭深度思考'), findsOneWidget);
  });
}
