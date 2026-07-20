/// Converts raw image bytes into a base64 data URL the backend accepts.
///
/// The `POST /api/conversations/{id}/messages` endpoint takes an optional
/// `image_data` field as a base64 data URL (e.g.
/// `data:image/png;base64,....`). This utility builds that string from the
/// raw bytes the file picker, drop zone, or paste handler returns.
///
/// It also detects the MIME type from the leading bytes of the image so the
/// data URL carries the right type, which the backend needs to decode and
/// store the file correctly.
library;

import 'dart:convert';
import 'dart:typed_data';

/// The result of converting raw bytes into an attachment-ready data URL.
class ImageDataUrl {
  /// Creates the result.
  const ImageDataUrl({required this.dataUrl, required this.mimeType});

  /// The full `data:<mime>;base64,<...>` string to send to the backend.
  final String dataUrl;

  /// The detected MIME type, e.g. `image/png`.
  final String mimeType;
}

/// Converts [bytes] into a base64 data URL the backend accepts.
///
/// Returns `null` when [bytes] is empty or the MIME type cannot be detected.
/// In those cases the caller should show an error rather than send an
/// attachment the backend would reject.
ImageDataUrl? imageDataUrlFromBytes(Uint8List bytes) {
  if (bytes.isEmpty) return null;
  final mimeType = _detectMimeType(bytes);
  if (mimeType == null) return null;
  final base64Body = base64Encode(bytes);
  return ImageDataUrl(
    dataUrl: 'data:$mimeType;base64,$base64Body',
    mimeType: mimeType,
  );
}

/// Detects the image MIME type from the leading "magic" bytes.
///
/// The backend stores images by decoding the data URL, so the MIME type must
/// match the actual file. We read the file signature (the first few bytes)
/// rather than trusting a file extension the user might have renamed.
String? _detectMimeType(Uint8List bytes) {
  // PNG: 89 50 4E 47 0D 0A 1A 0A
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47) {
    return 'image/png';
  }
  // JPEG: FF D8 FF
  if (bytes.length >= 3 &&
      bytes[0] == 0xFF &&
      bytes[1] == 0xD8 &&
      bytes[2] == 0xFF) {
    return 'image/jpeg';
  }
  // GIF: 47 49 46 38 (GIF8)
  if (bytes.length >= 6 &&
      bytes[0] == 0x47 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x38) {
    return 'image/gif';
  }
  // WebP: 52 49 46 46 ?? ?? ?? ?? 57 45 42 50 (RIFF....WEBP)
  if (bytes.length >= 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return 'image/webp';
  }
  return null;
}
