/// 流式 assistant message 的微交互测试。
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tan/core/models/conversation.dart';
import 'package:tan/core/models/message.dart';
import 'package:tan/core/models/model.dart';
import 'package:tan/core/network/api_client.dart';
import 'package:tan/core/theme/app_theme.dart';
import 'package:tan/core/theme/colors.dart';
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
                  onEdit: (_, _) async {},
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

  testWidgets('assistant footer keeps its height when hover actions appear', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [modelListProvider.overrideWithValue(const <ModelRead>[])],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: MessageBubble(
                message: _completeAssistantMessage('Completed response'),
                conversation: _conversation,
                siblings: const SiblingInfo(siblings: <int>[11], activeId: 11),
                isStreaming: false,
                isLast: true,
                streamState: StreamState.idle,
                onRegenerate: (_) {},
                onSwitchBranch: (_) {},
                onEdit: (_, _) async {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final bubble = find.byType(MessageBubble);
    final originalHeight = tester.getSize(bubble).height;
    expect(find.byTooltip('复制'), findsNothing);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer();
    await mouse.moveTo(tester.getCenter(bubble));
    await tester.pump();

    expect(find.byTooltip('复制'), findsOneWidget);
    expect(find.byTooltip('重新生成'), findsOneWidget);
    expect(tester.getSize(bubble).height, originalHeight);

    await mouse.removePointer();
  });

  testWidgets('user message edits through the pencil button', (tester) async {
    Message? editedMessage;
    String? editedText;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [baseUrlProvider.overrideWithValue('')],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: MessageBubble(
              message: _userMessage('Original question'),
              conversation: _conversation,
              siblings: const SiblingInfo(siblings: <int>[10], activeId: 10),
              isStreaming: false,
              isLast: false,
              streamState: StreamState.idle,
              onRegenerate: (_) {},
              onSwitchBranch: (_) {},
              onEdit: (message, text) async {
                editedMessage = message;
                editedText = text;
              },
            ),
          ),
        ),
      ),
    );

    final bubble = find.byType(MessageBubble);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer();
    await mouse.moveTo(tester.getCenter(bubble));
    await tester.pump(const Duration(milliseconds: 120));

    final editButton = find.byTooltip('编辑消息');
    expect(editButton, findsOneWidget);
    await tester.tap(editButton);
    await tester.pumpAndSettle();

    final editor = find.byType(TextField);
    expect(editor, findsOneWidget);
    final editorWidget = tester.widget<TextField>(editor);
    expect(editorWidget.decoration?.border, same(InputBorder.none));
    expect(editorWidget.decoration?.focusedBorder, same(InputBorder.none));
    expect(editorWidget.decoration?.filled, isTrue);
    expect(editorWidget.decoration?.fillColor, TanColors.light.softStone);
    await tester.enterText(editor, 'Revised question');
    await tester.tap(find.text('发送'));
    await tester.pumpAndSettle();

    expect(editedMessage?.id, 10);
    expect(editedText, 'Revised question');
    await mouse.removePointer();
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

Message _userMessage(String content) {
  return Message(
    id: 10,
    conversationId: 1,
    parentId: null,
    role: MessageRole.user,
    content: content,
    reasoning: null,
    imageUrl: null,
    isComplete: true,
    createdAt: DateTime.utc(2026, 7, 28),
  );
}

Message _completeAssistantMessage(String content) {
  return Message(
    id: 11,
    conversationId: 1,
    parentId: 10,
    role: MessageRole.assistant,
    content: content,
    reasoning: null,
    imageUrl: null,
    isComplete: true,
    createdAt: DateTime.utc(2026, 7, 28),
  );
}
