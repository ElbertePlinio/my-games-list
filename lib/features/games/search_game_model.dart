import 'package:equatable/equatable.dart';
import 'package:picklog/features/games/release_date.dart';

class SearchGame extends Equatable {
  const SearchGame({
    required this.id,
    required this.name,
    this.coverUrl,
    this.firstReleaseDate,
    required this.genres,
    required this.platforms,
  });

  factory SearchGame.fromJson(Map<String, dynamic> json) {
    return SearchGame(
      id: json['id'] as int,
      name: json['name'] as String,
      coverUrl: json['cover_url'] as String?,
      // The API returns release timestamps at midnight UTC. Parsing as UTC
      // keeps the derived year stable across time zones — a 2017-01-01T00:00Z
      // release must land in 2017 even on devices west of UTC.
      firstReleaseDate: parseReleaseDate(
        json['first_release_date'],
        isUtc: true,
      ),
      genres:
          (json['genres'] as List<dynamic>?)
              ?.map((g) => GameGenre.fromJson(g as Map<String, dynamic>))
              .toList() ??
          [],
      platforms:
          (json['platforms'] as List<dynamic>?)
              ?.map((p) => GamePlatform.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  final int id;
  final String name;
  final String? coverUrl;
  final DateTime? firstReleaseDate;
  final List<GameGenre> genres;
  final List<GamePlatform> platforms;

  @override
  List<Object?> get props => [
    id,
    name,
    coverUrl,
    firstReleaseDate,
    genres,
    platforms,
  ];
}

class GameGenre extends Equatable {
  const GameGenre({required this.id, required this.name});

  factory GameGenre.fromJson(Map<String, dynamic> json) {
    return GameGenre(id: json['id'] as int, name: json['name'] as String);
  }

  final int id;
  final String name;

  @override
  List<Object> get props => [id, name];
}

class GamePlatform extends Equatable {
  const GamePlatform({required this.id, required this.name});

  factory GamePlatform.fromJson(Map<String, dynamic> json) {
    return GamePlatform(id: json['id'] as int, name: json['name'] as String);
  }

  final int id;
  final String name;

  @override
  List<Object> get props => [id, name];
}

class SearchGamesResponse extends Equatable {
  const SearchGamesResponse({
    required this.games,
    required this.totalCount,
    required this.hasMore,
    required this.offset,
    required this.limit,
  });

  factory SearchGamesResponse.fromJson(Map<String, dynamic> json) {
    return SearchGamesResponse(
      games: (json['games'] as List<dynamic>)
          .map((g) => SearchGame.fromJson(g as Map<String, dynamic>))
          .toList(),
      totalCount: json['total_count'] as int,
      hasMore: json['has_more'] as bool,
      offset: json['offset'] as int,
      limit: json['limit'] as int,
    );
  }

  final List<SearchGame> games;
  final int totalCount;
  final bool hasMore;
  final int offset;
  final int limit;

  @override
  List<Object> get props => [games, totalCount, hasMore, offset, limit];
}
