/// 将原始 image bytes 转换为 backend 接受的 base64 data URL。
///
/// `POST /api/conversations/{id}/messages` endpoint 接受可选的 `image_data` field，其值为
/// base64 data URL（例如 `data:image/png;base64,....`）。此 utility 使用 file picker、drop
/// zone 或 paste handler 返回的 raw bytes 构建该 string。
///
/// 它还会根据图片的 leading bytes 检测 MIME type，使 data URL 携带正确 type，backend 需要
/// 该 type 才能正确 decode 和 store file。
library;

import 'dart:convert';
import 'dart:typed_data';

/// 将 raw bytes 转换为可用附件 data URL 的结果。
class ImageDataUrl {
  /// 创建结果。
  const ImageDataUrl({required this.dataUrl, required this.mimeType});

  /// 要发送给 backend 的完整 `data:<mime>;base64,<...>` string。
  final String dataUrl;

  /// 检测到的 MIME type，例如 `image/png`。
  final String mimeType;
}

/// 将 [bytes] 转换为 backend 接受的 base64 data URL。
///
/// 当 [bytes] 为空或无法检测 MIME type 时返回 `null`。此时调用方应显示 error，而不是发送
/// backend 会拒绝的附件。
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

/// 根据 leading “magic” bytes 检测 image MIME type。
///
/// Backend 通过 decode data URL 存储图片，因此 MIME type 必须匹配实际 file。这里读取 file
/// signature（前几个 bytes），而不是信任用户可能重命名过的 file extension。
String? _detectMimeType(Uint8List bytes) {
  // PNG：89 50 4E 47 0D 0A 1A 0A
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47) {
    return 'image/png';
  }
  // JPEG：FF D8 FF
  if (bytes.length >= 3 &&
      bytes[0] == 0xFF &&
      bytes[1] == 0xD8 &&
      bytes[2] == 0xFF) {
    return 'image/jpeg';
  }
  // GIF：47 49 46 38（GIF8）
  if (bytes.length >= 6 &&
      bytes[0] == 0x47 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x38) {
    return 'image/gif';
  }
  // WebP：52 49 46 46 ?? ?? ?? ?? 57 45 42 50（RIFF....WEBP）
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
