/// The model registry data models.
///
/// `GET /api/models` returns the list of models declared in the backend
/// `config.yaml` together with the configured default. The frontend uses this
/// to populate the model selector and the thinking-effort selector without any
/// protocol knowledge baked in.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'model.freezed.dart';
part 'model.g.dart';

/// A client-facing view of one model definition from the backend's config.
///
/// Deliberately omits `api_key` (a secret) and `base_url` (not useful to the
/// client). The `thinkingEffort` list drives the thinking-effort selector in
/// the top bar.
@freezed
class ModelRead with _$ModelRead {
  /// Creates a model entry.
  const factory ModelRead({
    /// The model id, used when creating a conversation.
    required String id,

    /// The human-readable name shown in the model selector and the model badge
    /// under assistant messages.
    required String displayName,

    /// The model family, e.g. "gpt" or "claude". Shown for context only; the
    /// frontend never branches on it (decision D4.3).
    required String family,

    /// The upstream protocol, e.g. "openai-response" or "anthropic-message".
    /// Kept as a string; the frontend never branches on it.
    required String protocol,

    /// Whether this model can accept image attachments.
    required bool vision,

    /// The supported thinking-effort levels, in the order the UI should show
    /// them. The first entry is the default for new conversations.
    @Default(<String>[]) List<String> thinkingEffort,
  }) = _ModelRead;

  /// Rebuilds a model entry from JSON.
  factory ModelRead.fromJson(Map<String, dynamic> json) =>
      _$ModelReadFromJson(json);
}

/// The response of `GET /api/models`.
///
/// Carries the configured default model id and the full list of available
/// models so the client can render its selectors without any hard-coded
/// protocol knowledge.
@freezed
class ModelsResponse with _$ModelsResponse {
  /// Creates the models response.
  const factory ModelsResponse({
    /// The configured default model id. Used as the initial selection in the
    /// empty state's model picker.
    required String defaultModel,

    /// All models declared in the backend config.
    @Default(<ModelRead>[]) List<ModelRead> models,
  }) = _ModelsResponse;

  /// Rebuilds the response from JSON.
  factory ModelsResponse.fromJson(Map<String, dynamic> json) =>
      _$ModelsResponseFromJson(json);
}
