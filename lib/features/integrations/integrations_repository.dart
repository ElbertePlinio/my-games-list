import 'package:picklog/core/data/services/http/i_http_client.dart';
import 'package:picklog/core/domain/models/api_error.dart';
import 'package:picklog/core/domain/models/app_failure.dart';
import 'package:picklog/features/integrations/integrations_models.dart';

/// Failure categories for linked accounts and achievements. The UI maps each
/// one to a localized message.
enum IntegrationErrorKind {
  /// 503 `error.integration.unavailable`.
  unavailable,

  /// 404 `error.integration.account_not_found`.
  accountNotFound,

  /// 422 `error.integration.private_profile`.
  privateProfile,

  /// 429 `error.integration.sync_too_soon`.
  syncTooSoon,

  /// 400 `error.validation.integration.identifier.invalid`.
  invalidIdentifier,

  /// 404 `error.integration.game_not_found`.
  gameNotFound,

  /// 502 `error.integration.upstream`.
  upstream,

  /// The device could not reach the server.
  network,

  /// Anything else.
  unknown;

  static IntegrationErrorKind from(Object error) {
    if (error is IntegrationException) return error.kind;
    final apiError = error is ApiException
        ? error.error
        : (error is ApiError ? error : null);
    return fromApiError(apiError);
  }

  static IntegrationErrorKind fromApiError(ApiError? error) {
    if (error == null) return IntegrationErrorKind.unknown;
    switch (error.errorCode) {
      case 'error.integration.unavailable':
        return IntegrationErrorKind.unavailable;
      case 'error.integration.account_not_found':
        return IntegrationErrorKind.accountNotFound;
      case 'error.integration.private_profile':
        return IntegrationErrorKind.privateProfile;
      case 'error.integration.sync_too_soon':
        return IntegrationErrorKind.syncTooSoon;
      case 'error.validation.integration.identifier.invalid':
        return IntegrationErrorKind.invalidIdentifier;
      case 'error.integration.game_not_found':
        return IntegrationErrorKind.gameNotFound;
      case 'error.integration.upstream':
        return IntegrationErrorKind.upstream;
    }
    if (error.errorCode.startsWith('error.network')) {
      return IntegrationErrorKind.network;
    }
    return switch (error.statusCode) {
      503 => IntegrationErrorKind.unavailable,
      422 => IntegrationErrorKind.privateProfile,
      429 => IntegrationErrorKind.syncTooSoon,
      502 => IntegrationErrorKind.upstream,
      _ => IntegrationErrorKind.unknown,
    };
  }
}

/// Thrown by [IntegrationsRepository] when a call fails.
class IntegrationException implements Exception {
  const IntegrationException(this.kind, [this.error]);

  final IntegrationErrorKind kind;
  final ApiError? error;

  @override
  String toString() => 'IntegrationException($kind)';
}

/// API access for linked gaming accounts and achievements.
class IntegrationsRepository {
  IntegrationsRepository({required IHttpClient httpClient})
    : _httpClient = httpClient;

  final IHttpClient _httpClient;

  static const String _accountsPath = '/users/me/linked-accounts';

  /// `GET /users/me/linked-accounts`.
  Future<List<LinkedProvider>> getLinkedAccounts() async {
    final response = await _httpClient.get<Map<String, dynamic>>(_accountsPath);
    if (response.isError) _throw(response.error);
    return LinkedProvider.listFromJson(response.dataOrThrow);
  }

  /// `POST /users/me/linked-accounts`.
  Future<LinkedAccount> link(GameProvider provider, String identifier) async {
    final response = await _httpClient.post<Map<String, dynamic>>(
      _accountsPath,
      data: {'provider': provider.apiValue, 'identifier': identifier.trim()},
    );
    if (response.isError) _throw(response.error);
    return LinkedAccount.fromJson(response.dataOrThrow);
  }

  /// `DELETE /users/me/linked-accounts/{provider}`.
  Future<void> unlink(GameProvider provider) async {
    final response = await _httpClient.delete<void>(
      '$_accountsPath/${provider.apiValue}',
    );
    if (response.isError) _throw(response.error);
  }

  /// `POST /users/me/linked-accounts/{provider}/sync`.
  Future<void> sync(GameProvider provider, {bool importLibrary = false}) async {
    final response = await _httpClient.post<Map<String, dynamic>>(
      '$_accountsPath/${provider.apiValue}/sync',
      data: {'import_library': importLibrary},
    );
    if (response.isError) _throw(response.error);
  }

  /// `GET /users/me/achievements/summary`.
  Future<AchievementSummary> getSummary() async {
    final response = await _httpClient.get<Map<String, dynamic>>(
      '/users/me/achievements/summary',
    );
    if (response.isError) _throw(response.error);
    return AchievementSummary.fromJson(response.dataOrThrow);
  }

  /// `GET /users/me/achievements/games/{provider}/{external_game_id}`.
  Future<GameAchievements> getGameAchievements(
    GameProvider provider,
    String externalGameId,
  ) async {
    final response = await _httpClient.get<Map<String, dynamic>>(
      '/users/me/achievements/games/${provider.apiValue}/'
      '${Uri.encodeComponent(externalGameId)}',
    );
    if (response.isError) _throw(response.error);
    return GameAchievements.fromJson(response.dataOrThrow);
  }

  /// `GET /games/{igdbId}/achievements`. Empty when nothing is mapped.
  Future<List<GameAchievements>> getAchievementsForGame(int igdbId) async {
    final response = await _httpClient.get<Map<String, dynamic>>(
      '/games/$igdbId/achievements',
    );
    if (response.isError) _throw(response.error);
    final games = response.dataOrThrow['games'] as List<dynamic>? ?? const [];
    return [
      for (final g in games.cast<Map<String, dynamic>>())
        GameAchievements.fromJson(g),
    ];
  }

  Never _throw(ApiError? error) => throw IntegrationException(
    IntegrationErrorKind.fromApiError(error),
    error,
  );
}
