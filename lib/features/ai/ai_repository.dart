import 'package:picklog/core/data/services/http/i_http_client.dart';
import 'package:picklog/core/domain/models/api_error.dart';
import 'package:picklog/core/domain/models/app_failure.dart';
import 'package:picklog/features/ai/ai_models.dart';

/// Failure categories for AI calls. The UI maps each one to a localized
/// message, so raw server text never reaches the screen.
enum AiErrorKind {
  /// 503 `error.ai.unavailable`: no key configured or the feature is off.
  unavailable,

  /// 403 `error.ai.consent_required`: the user has not opted in.
  consentRequired,

  /// 429 `error.ai.quota_exceeded`: the daily limit is used up.
  quotaExceeded,

  /// 502 `error.ai.upstream`: the model provider failed.
  upstream,

  /// The device could not reach the server.
  network,

  /// Anything else.
  unknown;

  /// Maps any thrown object to a kind.
  static AiErrorKind from(Object error) {
    if (error is AiException) return error.kind;
    final apiError = error is ApiException
        ? error.error
        : (error is ApiError ? error : null);
    return apiError == null ? AiErrorKind.unknown : fromApiError(apiError);
  }

  static AiErrorKind fromApiError(ApiError? error) {
    if (error == null) return AiErrorKind.unknown;
    switch (error.errorCode) {
      case 'error.ai.unavailable':
        return AiErrorKind.unavailable;
      case 'error.ai.consent_required':
        return AiErrorKind.consentRequired;
      case 'error.ai.quota_exceeded':
        return AiErrorKind.quotaExceeded;
      case 'error.ai.upstream':
        return AiErrorKind.upstream;
    }
    if (error.errorCode.startsWith('error.network')) return AiErrorKind.network;
    return switch (error.statusCode) {
      503 => AiErrorKind.unavailable,
      403 => AiErrorKind.consentRequired,
      429 => AiErrorKind.quotaExceeded,
      502 => AiErrorKind.upstream,
      _ => AiErrorKind.unknown,
    };
  }
}

/// Thrown by [AiRepository] when a call fails.
class AiException implements Exception {
  const AiException(this.kind, [this.error]);

  final AiErrorKind kind;
  final ApiError? error;

  @override
  String toString() => 'AiException($kind)';
}

/// API access for the AI suggestions feature.
class AiRepository {
  AiRepository({required IHttpClient httpClient}) : _httpClient = httpClient;

  final IHttpClient _httpClient;

  /// `GET /ai/status`.
  Future<AiStatus> getStatus() async {
    final response = await _httpClient.get<Map<String, dynamic>>('/ai/status');
    if (response.isError) _throw(response.error);
    return AiStatus.fromJson(response.dataOrThrow);
  }

  /// `PUT /users/me/ai-consent`.
  Future<AiConsentResult> setConsent({required bool granted}) async {
    final response = await _httpClient.put<Map<String, dynamic>>(
      '/users/me/ai-consent',
      data: {'granted': granted},
    );
    if (response.isError) _throw(response.error);
    return AiConsentResult.fromJson(response.dataOrThrow);
  }

  /// `POST /ai/play-next`.
  Future<PlayNextResult> playNext(PlayNextRequest request) async {
    final response = await _httpClient.post<Map<String, dynamic>>(
      '/ai/play-next',
      data: request.toJson(),
    );
    if (response.isError) _throw(response.error);
    return PlayNextResult.fromJson(response.dataOrThrow);
  }

  /// `POST /ai/discover`.
  Future<DiscoverResult> discover({String? prompt, int? count}) async {
    final trimmed = prompt?.trim();
    final response = await _httpClient.post<Map<String, dynamic>>(
      '/ai/discover',
      data: {
        if (trimmed != null && trimmed.isNotEmpty) 'prompt': trimmed,
        if (count != null) 'count': count,
      },
    );
    if (response.isError) _throw(response.error);
    return DiscoverResult.fromJson(response.dataOrThrow);
  }

  Never _throw(ApiError? error) =>
      throw AiException(AiErrorKind.fromApiError(error), error);
}
