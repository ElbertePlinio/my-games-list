import 'package:equatable/equatable.dart';
import 'package:picklog/features/games/discovery_game_model.dart';

/// A curated collection of games (e.g. "Cozy Games"), with its game cards.
class GameCollection extends Equatable {
  const GameCollection({
    required this.id,
    required this.slug,
    required this.title,
    this.description,
    this.coverImageUrl,
    this.games = const [],
  });

  factory GameCollection.fromJson(Map<String, dynamic> json) {
    final games = (json['games'] as List<dynamic>? ?? []).map((g) {
      final m = g as Map<String, dynamic>;
      // Collection games use `igdb_id`; map to the shared DiscoveryGame card.
      return DiscoveryGame(
        id: m['igdb_id'] as int,
        name: m['name'] as String,
        coverUrl: m['cover_url'] as String?,
      );
    }).toList();

    return GameCollection(
      id: json['id'] as String,
      slug: json['slug'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      games: games,
    );
  }

  final String id;
  final String slug;
  final String title;
  final String? description;
  final String? coverImageUrl;
  final List<DiscoveryGame> games;

  @override
  List<Object?> get props => [
    id,
    slug,
    title,
    description,
    coverImageUrl,
    games,
  ];
}

/// Response for GET /home/collections.
class CollectionsResponse extends Equatable {
  const CollectionsResponse({required this.collections});

  factory CollectionsResponse.fromJson(Map<String, dynamic> json) {
    final collections = (json['collections'] as List<dynamic>? ?? [])
        .map((c) => GameCollection.fromJson(c as Map<String, dynamic>))
        .toList();
    return CollectionsResponse(collections: collections);
  }

  final List<GameCollection> collections;

  @override
  List<Object?> get props => [collections];
}
