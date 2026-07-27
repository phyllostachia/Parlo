/// 没有打开 conversation 时，用户在 `/` 看到的 empty state。
///
/// 根据 `product.md` §6.2：居中的 large input，上方放 model picker。User 选择 model，输入
/// 第一条 message 并发送。发送会创建 conversation、post 第一条 message，并 navigation
/// 到 `/c/{id}`，chat screen 会在那里接管 streaming。
///
/// 阶段 5 增加 image attachment：paperclip button、drag-and-drop zone 和 preview bar。
/// 所选 model 不支持 vision 时，image input 被禁用。
library;

import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/model.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/fonts.dart';
import '../../core/theme/spacing.dart';
import '../../core/util/image_data_url.dart';
import '../../core/widgets/drop_target.dart';
import '../../core/widgets/error_banner.dart';
import 'chat_providers.dart';
import 'image_attachment.dart';

/// 居中的 empty-state widget。
class EmptyState extends ConsumerStatefulWidget {
  /// 创建 empty state。
  const EmptyState({required this.onNavigate, super.key});

  /// 第一条 message 发送后，以 `/c/123` 形式的 path 调用。
  final void Function(String path) onNavigate;

  @override
  ConsumerState<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends ConsumerState<EmptyState> {
  final TextEditingController _controller = TextEditingController();

  /// 当前附加的 image；没有 attachment 时为 `null`。
  final ValueNotifier<ImageDataUrl?> _attachment = ValueNotifier<ImageDataUrl?>(
    null,
  );
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
          .sendFirstMessage(modelId: modelId, text: text, imageData: imageData);
      widget.onNavigate('/c/$conversationId');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not send: $error')));
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

  Future<void> _handleDrop(List<XFile> files) async {
    setState(() => _isDropHovered = false);
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

  /// 所选 model 是否接受 image。读取 model registry，检查 user 选择的 model（或已配置
  /// default）的 `vision` flag。
  bool _canAttachImage(ModelRead? selectedModel) {
    if (selectedModel == null) return false;
    return selectedModel.vision;
  }

  /// 查找 user 当前选择的 [ModelRead]；model registry 仍在 loading 时为 `null`。
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
    final spacing = Theme.of(context).extension<TanSpacing>()!;
    final colors = Theme.of(context).extension<TanColors>()!;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: spacing.s32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
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
              final selectedModel = _selectedModel(
                models,
                response?.defaultModel,
              );
              return _PickerAndInput(
                models: models,
                defaultModelId: response?.defaultModel,
                selectedModelId: _selectedModelId,
                onModelChanged: (id) => setState(() => _selectedModelId = id),
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

/// Empty-state input 上方的 model dropdown。
///
/// 匹配 design 的“Model Selector”：带 border 的 capsule、sparkles icon、model name 和 chevron。
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
    final colors = Theme.of(context).extension<TanColors>()!;
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: colors.paperWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.mist, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: effectiveId,
          isDense: true,
          borderRadius: BorderRadius.circular(8),
          icon: Icon(Icons.expand_more, size: 16, color: colors.ashen),
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(color: colors.graphite),
          selectedItemBuilder: (context) => [
            for (final model in models)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, size: 15, color: colors.graphite),
                  const SizedBox(width: 6),
                  Text(model.displayName),
                ],
              ),
          ],
          items: [
            for (final model in models)
              DropdownMenuItem<String>(
                value: model.id,
                child: Text(model.displayName),
              ),
          ],
          onChanged: (value) => onChanged(value),
        ),
      ),
    );
  }
}

/// Model picker 和居中的 large input，并支持 image attachment。
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
  final Future<void> Function(List<XFile>) onDrop;
  final bool isDropHovered;
  final ValueChanged<bool> onDropHoverChanged;
  final bool disabled;
  final bool canAttachImage;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<TanColors>()!;

    return TanDropTarget(
      onDrop: onDrop,
      onDragEntered: () => onDropHoverChanged(true),
      onDragExited: () => onDropHoverChanged(false),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModelPicker(
            models: models,
            defaultModelId: defaultModelId,
            selectedId: selectedModelId,
            onChanged: onModelChanged,
          ),
          SizedBox(height: 20),
          Text(
            '今天想聊些什么？',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayLarge,
          ),
          SizedBox(height: 20),
          AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              color: colors.paperWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDropHovered ? colors.graphite : colors.mist,
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                _LargeInputField(
                  controller: controller,
                  onSend: onSend,
                  disabled: disabled,
                  accentColor: accentColor,
                  canAttachImage: canAttachImage,
                  onPickImage: onPickImage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state 中居中的 large input。
///
/// Enter 发送 message，Shift+Enter 插入 newline。Field 和 action 共用一个水平 row，使 input
/// 匹配 prototype 中的 compact paper input。
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
    final colors = Theme.of(context).extension<TanColors>()!;

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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (canAttachImage)
              IconButton(
                tooltip: 'Attach image',
                icon: const Icon(Icons.attach_file),
                iconSize: 20,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                color: colors.graphite,
                onPressed: onPickImage,
              )
            else
              const SizedBox(width: 34, height: 34),
            const SizedBox(width: 4),
            Expanded(
              child: Transform.translate(
                offset: const Offset(0, -4),
                child: TextField(
                  controller: controller,
                  enabled: !disabled,
                  maxLines: null,
                  minLines: 1,
                  textInputAction: TextInputAction.newline,
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    hintText: '输入你的问题...',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    isCollapsed: true,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                    hintStyle: TanFonts.naturalLanguageStyle.copyWith(
                      color: colors.pebble,
                      fontSize: 16,
                    ),
                  ),
                  style: TanFonts.naturalLanguageStyle.copyWith(
                    color: colors.carbonInk,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: colors.chalk,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: disabled ? null : onSend,
                child: SizedBox(
                  width: 34,
                  height: 34,
                  child: disabled
                      ? const Padding(
                          padding: EdgeInsets.all(9),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          Icons.arrow_upward,
                          size: 16,
                          color: colors.pebble,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// User 在 empty-state input 中按下 Enter（不带 shift）时触发的 intent。
class _SendIntent extends Intent {
  const _SendIntent();
}
