/// 流式 assistant message 的微交互测试。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tan/core/models/conversation.dart';
import 'package:tan/core/models/message.dart';
import 'package:tan/core/models/model.dart';
import 'package:tan/core/theme/app_theme.dart';
import 'package:tan/features/chat/chat_providers.dart';
import 'package:tan/features/chat/message_bubble.dart';

void main() {
  testWidgets('streaming text fades in without a Thinking spinner', (
    tester,
  ) async {
    var content = '';
    late void Function(String) updateContent;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [modelListProvider.overrideWithValue(const <ModelRead>[])],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                updateContent = (newContent) {
                  setState(() => content = newContent);
                };
                return MessageBubble(
                  message: _assistantMessage(content),
                  conversation: _conversation,
                  siblings: const SiblingInfo(
                    siblings: <int>[11],
                    activeId: 11,
                  ),
                  isStreaming: true,
                  isLast: true,
                  streamState: StreamState.streaming,
                  onRegenerate: (_) {},
                  onSwitchBranch: (_) {},
                );
              },
            ),
          ),
        ),
      ),
    );

    final fadeFinder = find.byKey(
      const ValueKey<String>('streaming-markdown-fade'),
    );
    expect(fadeFinder, findsNothing);
    expect(find.text('Thinking…'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    updateContent('Hello');
    await tester.pump();
    expect(fadeFinder, findsOneWidget);
    expect(
      tester.widget<FadeTransition>(fadeFinder).opacity.value,
      lessThan(1),
    );

    await tester.pump(const Duration(milliseconds: 140));
    expect(tester.widget<FadeTransition>(fadeFinder).opacity.value, 1);

    updateContent('Hello world');
    await tester.pump();
    expect(
      tester.widget<FadeTransition>(fadeFinder).opacity.value,
      lessThan(1),
    );

    await tester.pump(const Duration(milliseconds: 140));
    expect(tester.widget<FadeTransition>(fadeFinder).opacity.value, 1);
  });
}

final _conversation = Conversation(
  id: 1,
  profileId: 1,
  title: 'Test conversation',
  modelId: 'test-model',
  thinkingEnabled: false,
  currentLeafId: 11,
  createdAt: DateTime.utc(2026, 7, 28),
  updatedAt: DateTime.utc(2026, 7, 28),
);

Message _assistantMessage(String content) {
  return Message(
    id: 11,
    conversationId: 1,
    parentId: 10,
    role: MessageRole.assistant,
    content: content,
    reasoning: null,
    imageUrl: null,
    isComplete: false,
    createdAt: DateTime.utc(2026, 7, 28),
  );
}
