/// Image data URL converter 的 unit test。
///
/// Converter 读取图片的 leading bytes 以检测 MIME type，然后构建 backend 接受的
/// `data:<mime>;base64,<...>` string。这些 test 固定每个 supported format 的检测行为，
/// 以及 unknown data 的拒绝行为。
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:tan/core/util/image_data_url.dart';

void main() {
  group('imageDataUrlFromBytes', () {
    test('returns null for empty bytes', () {
      expect(imageDataUrlFromBytes(Uint8List(0)), isNull);
    });

    test('detects a PNG and builds the data URL', () {
      final bytes = Uint8List.fromList(<int>[
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
        0x01,
        0x02,
      ]);
      final result = imageDataUrlFromBytes(bytes);

      expect(result, isNotNull);
      expect(result!.mimeType, 'image/png');
      // Data URL prefix 与检测到的 type 匹配。
      expect(result.dataUrl, startsWith('data:image/png;base64,'));
      // Base64 body 可以 decode 回原始 bytes。
      final body = result.dataUrl.substring(result.dataUrl.indexOf(',') + 1);
      expect(base64Decode(body), bytes);
    });

    test('detects a JPEG', () {
      final bytes = Uint8List.fromList(<int>[0xFF, 0xD8, 0xFF, 0xE0, 0x00]);
      final result = imageDataUrlFromBytes(bytes);

      expect(result, isNotNull);
      expect(result!.mimeType, 'image/jpeg');
    });

    test('detects a GIF', () {
      final bytes = Uint8List.fromList(<int>[
        0x47,
        0x49,
        0x46,
        0x38,
        0x39,
        0x61,
      ]);
      final result = imageDataUrlFromBytes(bytes);

      expect(result, isNotNull);
      expect(result!.mimeType, 'image/gif');
    });

    test('detects a WebP', () {
      final bytes = Uint8List.fromList(<int>[
        0x52,
        0x49,
        0x46,
        0x46,
        0x00,
        0x00,
        0x00,
        0x00,
        0x57,
        0x45,
        0x42,
        0x50,
      ]);
      final result = imageDataUrlFromBytes(bytes);

      expect(result, isNotNull);
      expect(result!.mimeType, 'image/webp');
    });

    test('returns null for unknown byte signatures', () {
      // Text file 的 leading bytes 不匹配任何 image signature。
      final bytes = Uint8List.fromList(<int>[0x48, 0x65, 0x6C, 0x6C, 0x6F]);
      expect(imageDataUrlFromBytes(bytes), isNull);
    });
  });
}
