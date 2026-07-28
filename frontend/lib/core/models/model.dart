/// Model registry data model。
///
/// `GET /api/models` 返回 backend `config.yaml` 中声明的 model list 和已配置 default。
/// Frontend 用它填充 model selector，而无需内置 protocol knowledge。
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'model.freezed.dart';
part 'model.g.dart';

/// Backend config 中一个 model definition 的 client-facing view。
///
/// 有意省略 `api_key`、`base_url`（secret 或客户端不需要）以及仅供后端使用的 thinking
/// effort 配置。
@freezed
class ModelRead with _$ModelRead {
  /// 创建 model entry。
  const factory ModelRead({
    /// 创建 conversation 时使用的 model id。
    required String id,

    /// 在 model selector 和 assistant message 下方的 model badge 中显示的可读名称。
    required String displayName,

    /// Model family，例如 “gpt” 或 “claude”。仅用于提供上下文；frontend 不根据它分支
    /// （决策 D4.3）。
    required String family,

    /// Upstream protocol，例如 “openai-response” 或 “anthropic-message”。保持为 string；
    /// frontend 不根据它分支。
    required String protocol,

    /// 此 model 是否接受 image attachment。
    required bool vision,
  }) = _ModelRead;

  /// 根据 JSON 重建 model entry。
  factory ModelRead.fromJson(Map<String, dynamic> json) =>
      _$ModelReadFromJson(json);
}

/// `GET /api/models` 的 response。
///
/// 携带已配置的 default model id 和完整 available model list，使客户端无需 hard-coded
/// protocol knowledge 就能渲染 selector。
@freezed
class ModelsResponse with _$ModelsResponse {
  /// 创建 models response。
  const factory ModelsResponse({
    /// 已配置的 default model id。用作 empty state model picker 的初始选择。
    required String defaultModel,

    /// Backend config 中声明的所有 model。
    @Default(<ModelRead>[]) List<ModelRead> models,
  }) = _ModelsResponse;

  /// 根据 JSON 重建 response。
  factory ModelsResponse.fromJson(Map<String, dynamic> json) =>
      _$ModelsResponseFromJson(json);
}
