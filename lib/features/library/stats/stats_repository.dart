import 'package:picklog/core/data/services/http/i_http_client.dart';
import 'package:picklog/core/domain/models/app_failure.dart';
import 'package:picklog/features/library/stats/library_stats_model.dart';

/// Reads the caller's library stats and year in review.
class StatsRepository {
  StatsRepository({required IHttpClient httpClient}) : _httpClient = httpClient;

  final IHttpClient _httpClient;

  /// `GET /users/me/stats`. Pass [year] to include the year summary.
  Future<UserStats> getStats({int? year}) async {
    final response = await _httpClient.get<Map<String, dynamic>>(
      '/users/me/stats',
      queryParameters: year == null ? null : {'year': year.toString()},
    );

    if (response.isError) {
      throw ApiException(
        response.error,
        fallbackMessage: 'Failed to fetch stats',
      );
    }

    return UserStats.fromJson(response.dataOrThrow);
  }
}
