import 'package:picklog/features/games/anticipated_game_model.dart';
import 'package:picklog/features/games/collection_model.dart';
import 'package:picklog/features/games/discovery_game_model.dart';
import 'package:picklog/features/games/featured_banner_model.dart';
import 'package:picklog/features/games/game_detail_model.dart';
import 'package:picklog/features/games/search_game_model.dart';

/// Interface for fetching game-related data from the API.
/// This abstraction allows for easy swapping of repository implementations
/// (e.g., a remote API or a fake) without affecting the rest of the codebase.
abstract class IGamesRepository {
  /// Fetches the most anticipated upcoming games.
  Future<List<AnticipatedGame>> getAnticipatedGames();

  /// Fetches the editorial featured banners for the home screen.
  Future<List<FeaturedBanner>> getFeaturedBanners();

  /// Fetches personalized recommendations for the authenticated user.
  Future<List<DiscoveryGame>> getRecommendations();

  /// Fetches the curated game collections for the home screen.
  Future<List<GameCollection>> getCollections();

  /// Fetches discovery games based on the discovery [type] with pagination.
  Future<DiscoveryGamesResponse> getDiscoveryGames(
    DiscoveryType type, {
    int limit = 20,
    int offset = 0,
  });

  /// Fetches the list of game genres for the browse hub.
  Future<List<Genre>> getGenres();

  /// Fetches top-rated games for a specific [genreId].
  Future<DiscoveryGamesResponse> getGamesByGenre(
    int genreId, {
    int limit = 20,
    int offset = 0,
  });

  /// Searches for games matching the [query] with pagination.
  Future<SearchGamesResponse> searchGames(
    String query, {
    int limit = 20,
    int offset = 0,
  });

  /// Fetches detailed information about a specific game by [id].
  Future<GameDetail> getGameDetails(int id);
}
