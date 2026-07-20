/// The image attachment UI for the chat input.
///
/// Per `product.md` §6.4 the input accepts images from three sources: a
/// click-to-pick button, a drag-and-drop zone, and paste. This file
/// provides:
/// - [ImageAttachmentBar], a small preview row shown above the input when an
///   image is attached, with a remove button.
/// - [pickImageAttachment], a helper that opens the file picker and returns
///   an [ImageDataUrl] ready to send.
/// - [imageDataUrlFromXFile], a helper that reads an `XFile` (from the file
///   picker or the drop zone) and converts it to an [ImageDataUrl].
///
/// Paste of images is handled in the input widgets themselves via a keyboard
/// listener; the actual paste-to-image conversion on the web uses the same
/// [imageDataUrlFromBytes] helper once the bytes are read.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/util/image_data_url.dart';

/// A preview row shown above the input when an image is attached.
///
/// Shows a small thumbnail of the attached image and a remove button. The
/// thumbnail is built from the data URL so it works on every platform
/// without a separate fetch.
class ImageAttachmentBar extends StatelessWidget {
  /// Creates the bar.
  const ImageAttachmentBar({
    required this.attachment,
    required this.onRemove,
    super.key,
  });

  /// The currently attached image, or `null` when nothing is attached. The
  /// caller hides this bar when `null`.
  final ImageDataUrl attachment;

  /// Called when the user clicks the remove button.
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

/// Decodes a base64 data URL into bytes for the thumbnail. Kept here so the
/// [ImageAttachmentBar] does not depend on the raw `Uint8List` (the data URL
/// is what the backend receives).
Uint8List _bytesFromDataUrl(String dataUrl) {
  final commaIndex = dataUrl.indexOf(',');
  final base64Body = dataUrl.substring(commaIndex + 1);
  return base64Decode(base64Body);
}

/// Opens the platform file picker for images and returns the picked file as
/// an [ImageDataUrl], or `null` when the user cancels.
Future<ImageDataUrl?> pickImageAttachment() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    allowMultiple: false,
  );
  if (result == null || result.files.isEmpty) return null;
  return imageDataUrlFromXFile(result.files.first.xFile);
}

/// Reads an `XFile` (returned by the file picker and the drop zone) and
/// converts its bytes into an [ImageDataUrl]. Returns `null` when the file
/// is empty or the image type is not recognized.
Future<ImageDataUrl?> imageDataUrlFromXFile(XFile file) async {
  final bytes = await file.readAsBytes();
  return imageDataUrlFromBytes(Uint8List.fromList(bytes));
}
