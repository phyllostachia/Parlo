/// Chat input 的 image attachment UI。
///
/// 根据 `product.md` §6.4，input 接受三种 image source：click-to-pick button、drag-and-drop
/// zone 和 paste。此 file 提供：
/// - [ImageAttachmentBar]：附加 image 时显示在 input 上方的小型 preview row，带 remove button。
/// - [pickImageAttachment]：打开 file picker，并返回可发送的 [ImageDataUrl] 的 helper。
/// - [imageDataUrlFromXFile]：读取 `XFile`（来自 file picker 或 drop zone）并将其转换为
///   [ImageDataUrl] 的 helper。
///
/// Image paste 由 input widget 自身通过 keyboard listener 处理；Web 上实际的 paste-to-image
/// conversion 在读取 bytes 后使用同一个 [imageDataUrlFromBytes] helper。
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/util/image_data_url.dart';

/// 附加 image 时显示在 input 上方的 preview row。
///
/// 显示附加 image 的小 thumbnail 和 remove button。Thumbnail 根据 data URL 构建，因此无需
/// separate fetch 就能在所有 platform 上工作。
class ImageAttachmentBar extends StatelessWidget {
  /// 创建 bar。
  const ImageAttachmentBar({
    required this.attachment,
    required this.onRemove,
    super.key,
  });

  /// 当前附加的 image；没有 attachment 时为 `null`。调用方在 `null` 时隐藏此 bar。
  final ImageDataUrl attachment;

  /// User 点击 remove button 时调用。
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ParloColors>()!;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.softStone,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.memory(
              _bytesFromDataUrl(attachment.dataUrl),
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Image attached',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            iconSize: 18,
            color: colors.graphite,
            tooltip: 'Remove image',
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

/// 将 base64 data URL 解码为 thumbnail 使用的 bytes。保留在这里，使 [ImageAttachmentBar]
/// 不依赖 raw `Uint8List`（backend 接收的是 data URL）。
Uint8List _bytesFromDataUrl(String dataUrl) {
  final commaIndex = dataUrl.indexOf(',');
  final base64Body = dataUrl.substring(commaIndex + 1);
  return base64Decode(base64Body);
}

/// 打开 platform file picker 选择 image，并将 picked file 作为 [ImageDataUrl] 返回；User
/// cancel 时返回 `null`。
Future<ImageDataUrl?> pickImageAttachment() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    allowMultiple: false,
  );
  if (result == null || result.files.isEmpty) return null;
  return imageDataUrlFromXFile(result.files.first.xFile);
}

/// 读取 `XFile`（由 file picker 或 drop zone 返回），并将其 bytes 转换为 [ImageDataUrl]。
/// File 为空或 image type 无法识别时返回 `null`。
Future<ImageDataUrl?> imageDataUrlFromXFile(XFile file) async {
  final bytes = await file.readAsBytes();
  return imageDataUrlFromBytes(Uint8List.fromList(bytes));
}
