/// Chat endpoint 的 request body。
///
/// 单独放在此 file 中，使 model file 专注于 frontend 读取的 wire shape，而不是写入的 shape。
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'requests.freezed.dart';
part 'requests.g.dart';

/// `POST /api/conversations/{id}/messages` 的 body。
///
/// 省略 `parentId` 时，server 将其默认为 conversation current leaf，这是向可见 path 追加
/// 新问题的常见情况。`imageData` 是 base64 data URL；server 会 decode 并存储它，然后在
/// message 上返回可获取的 URL。
@freezed
class UserMessageCreate with _$UserMessageCreate {
  /// 创建 request body。
  const factory UserMessageCreate({
    /// Parent message id。`null` 表示“使用 conversation current leaf”。
    int? parentId,

    /// User 的 text。即使附加了 image 也必须提供。
    required String text,

    /// 附加 image 的可选 base64 data URL。Frontend 在发送前根据 picked/pasted/dropped file
    /// 构建它。
    String? imageData,
  }) = _UserMessageCreate;

  /// 根据 JSON 重建 request body（主要用于 test）。
  factory UserMessageCreate.fromJson(Map<String, dynamic> json) =>
      _$UserMessageCreateFromJson(json);
}
