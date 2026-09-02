import 'package:picklog/core/data/services/http/i_http_client.dart';
import 'package:picklog/features/games/anticipated_game_model.dart';
import 'package:picklog/features/games/collection_model.dart';
import 'package:picklog/features/games/discovery_game_model.dart';
import 'package:picklog/features/games/featured_banner_model.dart';
import 'package:picklog/features/games/game_detail_model.dart';
import 'package:picklog/features/games/i_games_repository.dart';
import 'package:picklog/features/games/search_game_model.dart';

/// Repository for fetching game-related data from the API
class GamesRepository implements IGamesRepository {
  GamesRepository({required IHttpClient httpClient}) : _httpClient = httpClient;

  final IHttpClient _httpClient;

  /// Fetches the most anticipated upcoming games
  @override
  Future<List<AnticipatedGame>> getAnticipatedGames() async {
    final response = await _httpClient.get<Map<String, dynamic>>(
      '/games/anticipated',
    );

    if (response.isError) {
      throw Exception(
        response.error?.userMessage ?? 'Failed to fetch anticipated games',
      );
    }

    final gamesResponse = AnticipatedGamesResponse.fromJson(
      response.dataOrThrow,
    );
    return gamesResponse.games;
  }

  /// Fetches the editorial featured banners for the home screen
  @override
  Future<List<FeaturedBanner>> getFeaturedBanners() async {
    final response = await _httpClient.get<Map<String, dynamic>>(
      '/home/featured',
    );

    if (response.isError) {
      throw Exception(
        response.error?.userMessage ?? 'Failed to fetch featured banners',
      );
    }

    final bannersResponse = FeaturedBannersResponse.fromJson(
      response.dataOrThrow,
    );
    return bannersResponse.banners;
  }

  /// Fetches personalized recommendations for the authenticated user.
  @override
  Future<List<DiscoveryGame>> getRecommendations() async {
    final response = await _httpClient.get<Map<String, dynamic>>(
      '/games/recommendations',
    );

    if (response.isError) {
      throw Exception(
        response.error?.userMessage ?? 'Failed to fetch recommendations',
      );
    }

    return DiscoveryGamesResponse.fromJson(response.dataOrThrow).games;
  }

  /// Fetches the curated game collections for the home screen.
  @override
  Future<List<GameCollection>> getCollections() async {
    final response = await _httpClient.get<Map<String, dynamic>>(
      '/home/collections',
    );

    if (response.isError) {
      throw Exception(
        response.error?.userMessage ?? 'Failed to fetch collections',
      );
    }

    return CollectionsResponse.fromJson(response.dataOrThrow).collections;
  }

  /// Fetches discovery games based on the discovery type with pagination
  @override
  Future<DiscoveryGamesResponse> getDiscoveryGames(
    DiscoveryType type, {
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _httpClient.get<Map<String, dynamic>>(
      '/games/discovery',
      queryParameters: {
        'type': type.queryParam,
        'limit': limit.toString(),
        'offset': offset.toString(),
      },
    );

    if (response.isError) {
      throw Exception(
        response.error?.userMessage ?? 'Failed to fetch discovery games',
      );
    }

    return DiscoveryGamesResponse.fromJson(response.dataOrThrow);
  }

  /// Fetches the list of game genres for the browse hub.
  @override
  Future<List<Genre>> getGenres() async {
    final response = await _httpClient.get<Map<String, dynamic>>(
      '/games/genres',
    );

    if (response.isError) {
      throw Exception(response.error?.userMessage ?? 'Failed to fetch genres');
    }

    final genres = response.dataOrThrow['genres'] as List<dynamic>;
    return genres
        .map((e) => Genre.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches top-rated games for a specific [genreId].
  @override
  Future<DiscoveryGamesResponse> getGamesByGenre(
    int genreId, {
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _httpClient.get<Map<String, dynamic>>(
      '/games/discovery',
      queryParameters: {
        'type': 'by_genre',
        'genre_id': genreId.toString(),
        'limit': limit.toString(),
        'offset': offset.toString(),
      },
    );

    if (response.isError) {
      throw Exception(
        response.error?.userMessage ?? 'Failed to fetch games for this genre',
      );
    }

    return DiscoveryGamesResponse.fromJson(response.dataOrThrow);
  }

  /// Searches for games matching the query with pagination
  @override
  Future<SearchGamesResponse> searchGames(
    String query, {
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _httpClient.post<Map<String, dynamic>>(
      '/games/search',
      data: {'query': query, 'limit': limit, 'offset': offset},
    );

    if (response.isError) {
      throw Exception(response.error?.userMessage ?? 'Failed to search games');
    }

    return SearchGamesResponse.fromJson(response.dataOrThrow);
  }

  /// Fetches detailed information about a specific game
  @override
  Future<GameDetail> getGameDetails(int id) async {
    final response = await _httpClient.get<Map<String, dynamic>>('/games/$id');

    if (response.isError) {
      throw Exception(
        response.error?.userMessage ?? 'Failed to fetch game details',
      );
    }

    final gameDetailResponse = GameDetailResponse.fromJson(
      response.dataOrThrow,
    );
    return gameDetailResponse.game;
  }
}
