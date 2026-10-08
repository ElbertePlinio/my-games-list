import 'package:picklog/core/data/services/http/i_http_client.dart';
import 'package:picklog/core/domain/models/app_failure.dart';
import 'package:picklog/features/library/library_entry_model.dart';
import 'package:picklog/features/library/library_query.dart';

/// Repository for managing user's game library
class LibraryRepository {
  LibraryRepository({required IHttpClient httpClient})
    : _httpClient = httpClient;

  final IHttpClient _httpClient;

  /// Fetches the user's library entries
  ///
  /// [userId] - The ID of the user whose library to fetch
  /// [favoritesOnly] - If true, only returns favorites
  /// [status] - Filter by game status (e.g., 'playing', 'finished')
  Future<List<LibraryEntry>> getLibrary(
    String userId, {
    bool favoritesOnly = false,
    GameStatus? status,
  }) async {
    var path = '/users/$userId/library';
    final queryParams = <String, String>{};

    if (favoritesOnly) {
      queryParams['favorites_only'] = 'true';
    }
    if (status != null) {
      queryParams['status'] = status.toApiString();
    }

    if (queryParams.isNotEmpty) {
      path +=
          '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    }

    final response = await _httpClient.get<Map<String, dynamic>>(path);

    if (response.isError) {
      throw ApiException(
        response.error,
        fallbackMessage: 'Failed to fetch library',
      );
    }

    final libraryResponse = LibraryEntriesResponse.fromJson(
      response.dataOrThrow,
    );
    return libraryResponse.entries;
  }

  /// Fetches one page of the library with server-side [filters] and sort.
  ///
  /// Without [limit] the API returns every match. `total_count` in the
  /// response is the match count before paging.
  Future<LibraryEntriesResponse> queryLibrary(
    String userId,
    LibraryFilters filters, {
    int? limit,
    int? offset,
  }) async {
    final response = await _httpClient.get<Map<String, dynamic>>(
      '/users/$userId/library',
      queryParameters: filters.toQueryParameters(limit: limit, offset: offset),
    );

    if (response.isError) {
      throw ApiException(
        response.error,
        fallbackMessage: 'Failed to fetch library',
      );
    }

    return LibraryEntriesResponse.fromJson(response.dataOrThrow);
  }

  /// Adds a game to the user's library
  ///
  /// [igdbId] - The IGDB ID of the game to add
  /// [status] - The initial status for the game
  /// [igdbPlatformId] - Optional IGDB platform ID
  /// [score] - Optional score (0-100)
  /// [playtimeMinutes] - Optional playtime in minutes
  /// [startDate] - Optional start date (YYYY-MM-DD)
  /// [endDate] - Optional end date (YYYY-MM-DD)
  /// [difficulty] - Optional difficulty description
  /// [isFavorite] - Whether this is a favorite game
  /// [notes] - Optional notes about the game
  Future<LibraryEntry> addToLibrary({
    required int igdbId,
    required GameStatus status,
    int? igdbPlatformId,
    int? score,
    int? playtimeMinutes,
    String? startDate,
    String? endDate,
    String? difficulty,
    bool isFavorite = false,
    String? notes,
  }) async {
    final data = <String, dynamic>{
      'igdb_id': igdbId,
      'status': status.toApiString(),
      'is_favorite': isFavorite,
    };

    if (igdbPlatformId != null) data['igdb_platform_id'] = igdbPlatformId;
    if (score != null) data['score'] = score;
    if (playtimeMinutes != null) data['playtime_minutes'] = playtimeMinutes;
    if (startDate != null) data['start_date'] = startDate;
    if (endDate != null) data['end_date'] = endDate;
    if (difficulty != null) data['difficulty'] = difficulty;
    if (notes != null) data['notes'] = notes;

    final response = await _httpClient.post<Map<String, dynamic>>(
      '/library',
      data: data,
    );

    if (response.isError) {
      throw ApiException(
        response.error,
        fallbackMessage: 'Failed to add game to library',
      );
    }

    return LibraryEntry.fromJson(response.dataOrThrow);
  }

  /// Gets a specific library entry by ID
  Future<LibraryEntry> getLibraryEntry(String entryId) async {
    final response = await _httpClient.get<Map<String, dynamic>>(
      '/library/$entryId',
    );

    if (response.isError) {
      throw ApiException(
        response.error,
        fallbackMessage: 'Failed to fetch library entry',
      );
    }

    return LibraryEntry.fromJson(response.dataOrThrow);
  }

  /// Updates [current] on the server and returns the saved entry.
  ///
  /// Null [status], [igdbPlatformId], [playtimeMinutes] and [isFavorite]
  /// keep their current values on the server. The API replaces score, dates,
  /// difficulty and notes, so they are always sent: from [details] when given,
  /// otherwise from [current]. Pass [details] only from a full edit form,
  /// where a null field means the user cleared it.
  Future<LibraryEntry> updateLibraryEntry(
    LibraryEntry current, {
    GameStatus? status,
    int? igdbPlatformId,
    int? playtimeMinutes,
    bool? isFavorite,
    LibraryEntryDetails? details,
  }) async {
    final data = <String, dynamic>{
      'status': ?status?.toApiString(),
      'igdb_platform_id': ?igdbPlatformId,
      'playtime_minutes': ?playtimeMinutes,
      'is_favorite': ?isFavorite,
      ...(details ?? LibraryEntryDetails.of(current)).toJson(),
    };

    final response = await _httpClient.put<Map<String, dynamic>>(
      '/library/${current.id}',
      data: data,
    );

    if (response.isError) {
      throw ApiException(
        response.error,
        fallbackMessage: 'Failed to update library entry',
      );
    }

    return LibraryEntry.fromJson(response.dataOrThrow);
  }

  /// Toggles the favorite status of a library entry
  Future<LibraryEntry> toggleFavorite(String entryId) async {
    final response = await _httpClient.post<Map<String, dynamic>>(
      '/library/$entryId/favorite',
    );

    if (response.isError) {
      throw ApiException(
        response.error,
        fallbackMessage: 'Failed to toggle favorite',
      );
    }

    return LibraryEntry.fromJson(response.dataOrThrow);
  }

  /// Deletes a library entry
  Future<void> deleteLibraryEntry(String entryId) async {
    final response = await _httpClient.delete<Map<String, dynamic>>(
      '/library/$entryId',
    );

    if (response.isError) {
      throw ApiException(
        response.error,
        fallbackMessage: 'Failed to delete library entry',
      );
    }
  }
}
