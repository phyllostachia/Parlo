/// Conversation page 底部显示的 chat input。
///
/// 根据 `product.md` §6.4：Enter 发送，Shift+Enter 插入 newline（没有 configuration option）。
/// Assistant streaming 时，send button 变为 stop button，并取消 Server-Sent Events stream。
///
/// 阶段 5 增加 image attachment：paperclip button 打开 file picker，drag-and-drop zone 包裹
/// field，[ImageAttachmentBar] 显示 preview。Conversation 绑定的 model 不支持 vision 时，
/// image input 会被禁用。
library;

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/fonts.dart';
import '../../core/theme/spacing.dart';
import '../../core/util/image_data_url.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/drop_target.dart';
import 'chat_providers.dart';
import 'image_attachment.dart';
import 'thinking_toggle_button.dart';

/// 底部 input widget。
class ChatInput extends ConsumerStatefulWidget {
  /// 创建 input。
  const ChatInput({required this.conversationId, super.key});

  /// 此 input 要发送到的 conversation。
  final int conversationId;

  @override
  ConsumerState<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends ConsumerState<ChatInput> {
  final TextEditingController _controller = TextEditingController();

  /// 当前附加的 image；没有 attachment 时为 `null`。使用 [ValueNotifier]，使
  /// [ImageAttachmentBar] 只在 attachment 变化时 rebuild，而不是每次按键都 rebuild。
  final ValueNotifier<ImageDataUrl?> _attachment = ValueNotifier<ImageDataUrl?>(
    null,
  );

  /// Drag-and-drop zone 当前是否处于 hover。它驱动 border highlight，让用户知道 drop
  /// 会被接受。
  bool _isDropHovered = false;

  @override
  void dispose() {
    _controller.dispose();
    _attachment.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    final imageData = _attachment.value?.dataUrl;
    if (text.isEmpty && imageData == null) return;
    _controller.clear();
    final attachmentCopy = _attachment.value;
    _attachment.value = null;
    try {
      await ref
          .read(currentConversationProvider(widget.conversationId).notifier)
          .send(text: text, imageData: imageData);
    } catch (error) {
      // 恢复 attachment，使用户无需重新选择即可 retry。
      _attachment.value = attachmentCopy;
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not send: $error')));
      }
    }
  }

  Future<void> _stop() async {
    await ref
        .read(currentConversationProvider(widget.conversationId).notifier)
        .stop();
  }

  Future<void> _toggleThinking() async {
    final conversation = ref
        .read(currentConversationProvider(widget.conversationId))
        .valueOrNull
        ?.conversation;
    if (conversation == null) return;

    try {
      await ref
          .read(dioProvider)
          .patch<Map<String, dynamic>>(
            '/api/conversations/${widget.conversationId}',
            data: <String, dynamic>{
              'thinking_enabled': !conversation.thinkingEnabled,
            },
          );
      ref.invalidate(currentConversationProvider(widget.conversationId));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update thinking: $error')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final attachment = await pickImageAttachment();
    if (attachment != null) {
      _attachment.value = attachment;
    }
  }

  Future<void> _handleDrop(List<XFile> files) async {
    setState(() => _isDropHovered = false);
    // 取 drop 中第一个 image-only file。虽然下面的 type filter 使 drop zone 只接受 image，
    // 但增加防御性处理的成本很低。
    for (final file in files) {
      final attachment = await imageDataUrlFromXFile(file);
      if (attachment != null) {
        _attachment.value = attachment;
        return;
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That file is not a supported image.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final streamState = ref.watch(streamStateProvider);
    final isStreaming = streamState == StreamState.streaming;
    final conversationAsync = ref.watch(
      currentConversationProvider(widget.conversationId),
    );
    final conversation = conversationAsync.valueOrNull?.conversation;
    // 必须 watch（而非 read）model list：models 异步加载完成后会触发 rebuild，否则
    // attach button 会在 models 尚未就绪时隐藏，且之后永不出现。
    final models = ref.watch(modelListProvider);
    final spacing = Theme.of(context).extension<TanSpacing>()!;
    final colors = Theme.of(context).extension<TanColors>()!;

    /// Conversation 绑定的 model 是否接受 image。任一数据仍在 loading 或 model 不是
    /// vision model 时为 `false`。
    final modelId = conversation?.modelId;
    final canAttachImage =
        modelId != null &&
        models.any((model) => model.id == modelId && model.vision);

    return TanDropTarget(
      onDrop: _handleDrop,
      onDragEntered: () => setState(() => _isDropHovered = true),
      onDragExited: () => setState(() => _isDropHovered = false),
      child: Padding(
        // Design “Input Wrap”：上方 16px、下方 24px，居中的 720px column。
        padding: EdgeInsets.fromLTRB(
          spacing.s16,
          spacing.s16,
          spacing.s16,
          spacing.s24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Shortcuts(
              shortcuts: <ShortcutActivator, Intent>{
                LogicalKeySet(LogicalKeyboardKey.enter): const _SendIntent(),
              },
              child: Actions(
                actions: <Type, Action<Intent>>{
                  _SendIntent: CallbackAction<_SendIntent>(
                    onInvoke: (_) {
                      if (!isStreaming) _send();
                      return null;
                    },
                  ),
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  decoration: BoxDecoration(
                    color: colors.paperWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isDropHovered ? colors.graphite : colors.mist,
                      width: 1,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.04),
                        blurRadius: 20,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ValueListenableBuilder<ImageDataUrl?>(
                        valueListenable: _attachment,
                        builder: (context, attachment, _) {
                          if (attachment == null) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ImageAttachmentBar(
                              attachment: attachment,
                              onRemove: () => _attachment.value = null,
                            ),
                          );
                        },
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (canAttachImage)
                            _AttachButton(onPressed: _pickImage)
                          else
                            const SizedBox(width: 32, height: 32),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Transform.translate(
                              offset: const Offset(0, -4),
                              child: TextField(
                                controller: _controller,
                                // Streaming 时 field 仍可编辑，使用户可以输入下一条 message；
                                // 只有 send button 被禁用。
                                enabled: true,
                                maxLines: null,
                                minLines: 1,
                                textInputAction: TextInputAction.newline,
                                textAlignVertical: TextAlignVertical.center,
                                decoration: InputDecoration(
                                  hintText: '输入消息...',
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  isCollapsed: true,
                                  contentPadding: EdgeInsets.zero,
                                  isDense: true,
                                  hintStyle: TanFonts.naturalLanguageStyle
                                      .copyWith(
                                        color: colors.pebble,
                                        fontSize: 15,
                                      ),
                                ),
                                style: TanFonts.naturalLanguageStyle.copyWith(
                                  color: colors.carbonInk,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          if (conversation != null) ...[
                            const SizedBox(width: 8),
                            ThinkingToggleButton(
                              enabled: conversation.thinkingEnabled,
                              onPressed: isStreaming ? null : _toggleThinking,
                            ),
                          ],
                          const SizedBox(width: 8),
                          _SendButton(
                            isStreaming: isStreaming,
                            onSend: _send,
                            onStop: _stop,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 用户在 chat input 中按下 Enter（不带 shift）时触发的 intent。
class _SendIntent extends Intent {
  const _SendIntent();
}

/// 打开 image picker 的 paperclip button。匹配 design 的“Attach Image Button”：17px icon、
/// 6px padding 和 8px radius。
class _AttachButton extends StatelessWidget {
  const _AttachButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<TanColors>()!;
    return IconButton(
      tooltip: 'Attach image',
      icon: const Icon(Icons.attach_file),
      iconSize: 20,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      color: colors.graphite,
      onPressed: onPressed,
    );
  }
}

/// Design 中的 send button：32x32 carbon-ink square、8px radius 和 white arrow-up glyph。
/// Streaming 时它变为 stop button，并取消 SSE stream。
class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.isStreaming,
    required this.onSend,
    required this.onStop,
  });

  final bool isStreaming;
  final VoidCallback onSend;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<TanColors>()!;
    return Material(
      color: colors.carbonInk,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: isStreaming ? onStop : onSend,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            isStreaming ? Icons.stop : Icons.arrow_upward,
            size: 16,
            color: colors.boneParchment,
          ),
        ),
      ),
    );
  }
}
