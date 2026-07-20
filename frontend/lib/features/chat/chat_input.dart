/// The bottom chat input shown on a conversation page.
///
/// Per `product.md` §6.4: Enter sends, Shift+Enter inserts a newline (no
/// configuration option). While the assistant is streaming, the send button
/// becomes a stop button that cancels the Server-Sent Events stream.
///
/// Phase 5 adds image attachment: a paperclip button opens the file picker,
/// a drag-and-drop zone wraps the field, and an [ImageAttachmentBar] shows
/// the preview. Image input is disabled when the conversation's bound model
/// does not support vision.
library;

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/util/image_data_url.dart';
import 'chat_providers.dart';
import 'image_attachment.dart';

/// The bottom input widget.
class ChatInput extends ConsumerStatefulWidget {
  /// Creates the input.
  const ChatInput({required this.conversationId, super.key});

  /// The conversation this input posts into.
  final int conversationId;

  @override
  ConsumerState<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends ConsumerState<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  /// The currently attached image, or `null` when none is attached. Kept as
  /// a [ValueNotifier] so the [ImageAttachmentBar] rebuilds only when the
  /// attachment changes, not on every keystroke.
  final ValueNotifier<ImageDataUrl?> _attachment =
      ValueNotifier<ImageDataUrl?>(null);

  /// Whether the drag-and-drop zone is currently being hovered. Drives the
  /// border highlight so the user gets feedback that a drop is accepted.
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
      // Restore the attachment so the user can retry without re-picking.
      _attachment.value = attachmentCopy;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send: $error')),
        );
      }
    }
  }

  Future<void> _stop() async {
    await ref
        .read(currentConversationProvider(widget.conversationId).notifier)
        .stop();
  }

  Future<void> _pickImage() async {
    final attachment = await pickImageAttachment();
    if (attachment != null) {
      _attachment.value = attachment;
    }
  }

  Future<void> _handleDrop(DropDoneDetails details) async {
    setState(() => _isDropHovered = false);
    // Take the first image-only file from the drop. The drop zone only
    // accepts images because of the type filter below, but being defensive
    // is cheap.
    for (final file in details.files) {
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

  /// Whether the conversation's bound model can accept images. Reads the
  /// current path and the model registry; `false` while either is loading
  /// or when the model is not a vision model.
  bool get _canAttachImage {
    final path = ref
        .read(currentConversationProvider(widget.conversationId))
        .valueOrNull;
    final modelId = path?.conversation.modelId;
    if (modelId == null) return false;
    final models = ref.read(modelListProvider);
    for (final model in models) {
      if (model.id == modelId) return model.vision;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final streamState = ref.watch(streamStateProvider);
    final isStreaming = streamState == StreamState.streaming;
    final spacing = Theme.of(context).extension<ParloSpacing>()!;
    final colors = Theme.of(context).extension<ParloColors>()!;
    final canAttachImage = _canAttachImage;

    return DropTarget(
      onDragDone: _handleDrop,
      onDragEntered: (_) => setState(() => _isDropHovered = true),
      onDragExited: (_) => setState(() => _isDropHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: _isDropHovered ? colors.chalk : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: EdgeInsets.fromLTRB(
          spacing.s32,
          spacing.s8,
          spacing.s32,
          spacing.s16,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
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
                    TextField(
                      controller: _controller,
                      // The field stays editable while streaming so the user
                      // can type the next message; only the send button is
                      // disabled.
                      enabled: true,
                      maxLines: null,
                      minLines: 1,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: 'Message Parlo…',
                        prefixIcon: canAttachImage
                            ? IconButton(
                                tooltip: 'Attach image',
                                icon: const Icon(Icons.attach_file),
                                onPressed: _pickImage,
                              )
                            : null,
                        suffixIcon: isStreaming
                            ? IconButton(
                                tooltip: 'Stop',
                                icon:
                                    const Icon(Icons.stop_circle_outlined),
                                color: colors.clay,
                                onPressed: _stop,
                              )
                            : IconButton(
                                tooltip: 'Send',
                                icon: const Icon(Icons.arrow_upward),
                                color: colors.clay,
                                onPressed: _send,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The intent that fires when the user presses Enter (without shift) in the
/// chat input.
class _SendIntent extends Intent {
  const _SendIntent();
}
