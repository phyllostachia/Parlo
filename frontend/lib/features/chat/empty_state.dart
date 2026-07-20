/// The empty state — what the user sees at `/` when no conversation is open.
///
/// Per `product.md` §6.2: a centered large input with a model picker above
/// it. The user picks a model, types the first message, and sends. Sending
/// creates a conversation, posts the first message, and navigates to
/// `/c/{id}`, where the chat screen picks up the streaming.
///
/// Phase 5 adds image attachment: a paperclip button, a drag-and-drop zone,
/// and a preview bar. Image input is disabled when the selected model does
/// not support vision.
library;

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/model.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/util/image_data_url.dart';
import '../../core/widgets/error_banner.dart';
import 'chat_providers.dart';
import 'image_attachment.dart';

/// The centered empty-state widget.
class EmptyState extends ConsumerStatefulWidget {
  /// Creates the empty state.
  const EmptyState({required this.onNavigate, super.key});

  /// Called with a path like `/c/123` after the first message is sent.
  final void Function(String path) onNavigate;

  @override
  ConsumerState<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends ConsumerState<EmptyState> {
  final TextEditingController _controller = TextEditingController();
  /// The currently attached image, or `null` when none is attached.
  final ValueNotifier<ImageDataUrl?> _attachment =
      ValueNotifier<ImageDataUrl?>(null);
  String? _selectedModelId;
  bool _sending = false;
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
    if ((text.isEmpty && imageData == null) || _sending) return;

    final modelId = _selectedModelId ?? ref.read(defaultModelIdProvider);
    if (modelId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No model available. Check the backend config.'),
        ),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      final conversationId = await ref
          .read(chatActionsProvider.notifier)
          .sendFirstMessage(
            modelId: modelId,
            text: text,
            imageData: imageData,
          );
      widget.onNavigate('/c/$conversationId');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickImage() async {
    final attachment = await pickImageAttachment();
    if (attachment != null) {
      _attachment.value = attachment;
    }
  }

  Future<void> _handleDrop(DropDoneDetails details) async {
    setState(() => _isDropHovered = false);
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

  /// Whether the selected model can accept images. Reads the model registry
  /// to check the `vision` flag of the model the user picked (or the
  /// configured default).
  bool _canAttachImage(ModelRead? selectedModel) {
    if (selectedModel == null) return false;
    return selectedModel.vision;
  }

  /// Finds the [ModelRead] the user currently has selected, or `null` while
  /// the model registry is still loading.
  ModelRead? _selectedModel(List<ModelRead> models, String? defaultModel) {
    final id = _selectedModelId ?? defaultModel;
    if (id == null) return models.isNotEmpty ? models.first : null;
    for (final model in models) {
      if (model.id == id) return model;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final modelsAsync = ref.watch(modelsProvider);
    final spacing = Theme.of(context).extension<ParloSpacing>()!;
    final colors = Theme.of(context).extension<ParloColors>()!;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing.s32),
          child: modelsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => ErrorBanner(
              message: 'Could not load models.',
              error: error,
              onRetry: () => ref.invalidate(modelsProvider),
            ),
            data: (response) {
              final models = response?.models ?? const <ModelRead>[];
              final selectedModel =
                  _selectedModel(models, response?.defaultModel);
              return _PickerAndInput(
                models: models,
                defaultModelId: response?.defaultModel,
                selectedModelId: _selectedModelId,
                onModelChanged: (id) =>
                    setState(() => _selectedModelId = id),
                controller: _controller,
                attachment: _attachment,
                onRemoveAttachment: () => _attachment.value = null,
                onPickImage: _pickImage,
                onSend: _send,
                onDrop: _handleDrop,
                isDropHovered: _isDropHovered,
                onDropHoverChanged: (hovered) =>
                    setState(() => _isDropHovered = hovered),
                disabled: _sending,
                canAttachImage: _canAttachImage(selectedModel),
                accentColor: colors.clay,
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The model dropdown above the empty-state input.
class _ModelPicker extends StatelessWidget {
  const _ModelPicker({
    required this.models,
    required this.defaultModelId,
    required this.selectedId,
    required this.onChanged,
  });

  final List<ModelRead> models;
  final String? defaultModelId;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (models.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No models configured. Ask the operator to add one in the backend config.',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      );
    }
    final effectiveId = selectedId ?? defaultModelId ?? models.first.id;
    return DropdownButtonFormField<String>(
      // `initialValue` (not the deprecated `value`) so the form field owns its
      // selection. The parent only needs to know the chosen id at send time.
      initialValue: effectiveId,
      decoration: const InputDecoration(labelText: 'Model'),
      items: [
        for (final model in models)
          DropdownMenuItem<String>(
            value: model.id,
            child: Text(model.displayName),
          ),
      ],
      onChanged: (value) => onChanged(value),
    );
  }
}

/// The model picker plus the large centered input, with image attachment
/// support.
class _PickerAndInput extends StatelessWidget {
  const _PickerAndInput({
    required this.models,
    required this.defaultModelId,
    required this.selectedModelId,
    required this.onModelChanged,
    required this.controller,
    required this.attachment,
    required this.onRemoveAttachment,
    required this.onPickImage,
    required this.onSend,
    required this.onDrop,
    required this.isDropHovered,
    required this.onDropHoverChanged,
    required this.disabled,
    required this.canAttachImage,
    required this.accentColor,
  });

  final List<ModelRead> models;
  final String? defaultModelId;
  final String? selectedModelId;
  final ValueChanged<String?> onModelChanged;
  final TextEditingController controller;
  final ValueListenable<ImageDataUrl?> attachment;
  final VoidCallback onRemoveAttachment;
  final VoidCallback onPickImage;
  final VoidCallback onSend;
  final void Function(DropDoneDetails) onDrop;
  final bool isDropHovered;
  final ValueChanged<bool> onDropHoverChanged;
  final bool disabled;
  final bool canAttachImage;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<ParloSpacing>()!;
    final colors = Theme.of(context).extension<ParloColors>()!;

    return DropTarget(
      onDragDone: onDrop,
      onDragEntered: (_) => onDropHoverChanged(true),
      onDragExited: (_) => onDropHoverChanged(false),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'How can I help?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayLarge,
          ),
          SizedBox(height: spacing.s24),
          _ModelPicker(
            models: models,
            defaultModelId: defaultModelId,
            selectedId: selectedModelId,
            onChanged: onModelChanged,
          ),
          SizedBox(height: spacing.s16),
          ValueListenableBuilder<ImageDataUrl?>(
            valueListenable: attachment,
            builder: (context, attached, _) {
              if (attached == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ImageAttachmentBar(
                  attachment: attached,
                  onRemove: onRemoveAttachment,
                ),
              );
            },
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              color: isDropHovered ? colors.chalk : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: _LargeInputField(
              controller: controller,
              onSend: onSend,
              disabled: disabled,
              accentColor: accentColor,
              canAttachImage: canAttachImage,
              onPickImage: onPickImage,
            ),
          ),
        ],
      ),
    );
  }
}

/// The large centered input on the empty state.
///
/// Enter sends the message, Shift+Enter inserts a newline. The [Shortcuts]
/// widget intercepts Enter (with no modifiers) and invokes the send action
/// before the text field turns it into a newline; Shift+Enter is not matched,
/// so the field handles it normally.
class _LargeInputField extends StatelessWidget {
  const _LargeInputField({
    required this.controller,
    required this.onSend,
    required this.disabled,
    required this.accentColor,
    required this.canAttachImage,
    required this.onPickImage,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool disabled;
  final Color accentColor;
  final bool canAttachImage;
  final VoidCallback onPickImage;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        LogicalKeySet(LogicalKeyboardKey.enter): const _SendIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _SendIntent: CallbackAction<_SendIntent>(
            onInvoke: (_) {
              if (!disabled) onSend();
              return null;
            },
          ),
        },
        child: TextField(
          controller: controller,
          enabled: !disabled,
          maxLines: null,
          minLines: 3,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            hintText: 'Message Parlo…',
            border: const OutlineInputBorder(),
            prefixIcon: canAttachImage
                ? IconButton(
                    tooltip: 'Attach image',
                    icon: const Icon(Icons.attach_file),
                    onPressed: onPickImage,
                  )
                : null,
            suffixIcon: disabled
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.arrow_upward),
                    color: accentColor,
                    onPressed: onSend,
                  ),
          ),
        ),
      ),
    );
  }
}

/// The intent that fires when the user presses Enter (without shift) in the
/// empty-state input.
class _SendIntent extends Intent {
  const _SendIntent();
}
