import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/features/games/game_detail_model.dart';
import 'package:picklog/features/games/release_date.dart';

/// Represents the type of discovery query
enum DiscoveryType {
  trending('trending', 'Trending Now'),
  indie('indie', 'Indie Games'),
  upcoming('upcoming', 'Upcoming Games'),
  newReleases('new_releases', 'New Releases'),
  comingSoon('coming_soon', 'Coming Soon');

  const DiscoveryType(this.queryParam, this.displayName);

  /// The query parameter value for the API
  final String queryParam;

  /// The display name shown in the UI (non-localized fallback)
  final String displayName;

  /// Returns the localized display name for this discovery type
  String localizedName(BuildContext context) {
    switch (this) {
      case DiscoveryType.trending:
        return context.l10n.discoveryTrending;
      case DiscoveryType.indie:
        return context.l10n.discoveryIndie;
      case DiscoveryType.upcoming:
        return context.l10n.discoveryUpcoming;
      case DiscoveryType.newReleases:
        return context.l10n.discoveryNewReleases;
      case DiscoveryType.comingSoon:
        return context.l10n.discoveryComingSoon;
    }
  }

  /// Creates a DiscoveryType from a query parameter string
  static DiscoveryType fromQueryParam(String param) {
    return DiscoveryType.values.firstWhere(
      (type) => type.queryParam == param,
      orElse: () => DiscoveryType.trending,
    );
  }
}

/// Why a game was recommended.
enum RecommendationReasonType {
  genre,
  similar,
  popular;

  static RecommendationReasonType? fromApi(String? value) => switch (value) {
    'genre' => genre,
    'similar' => similar,
    'popular' => popular,
    _ => null,
  };
}

/// Reason attached to a `GET /games/recommendations` game.
class RecommendationReason extends Equatable {
  const RecommendationReason({
    required this.type,
    this.sourceGameName,
    this.genreName,
  });

  /// Null when the type is unknown, so the UI shows no reason.
  static RecommendationReason? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final type = RecommendationReasonType.fromApi(json['type'] as String?);
    if (type == null) return null;
    return RecommendationReason(
      type: type,
      sourceGameName: json['source_game_name'] as String?,
      genreName: json['genre_name'] as String?,
    );
  }

  final RecommendationReasonType type;
  final String? sourceGameName;
  final String? genreName;

  /// Localized one-line reason.
  String localizedLabel(BuildContext context) {
    final l10n = context.l10n;
    final source = sourceGameName?.trim() ?? '';
    final genre = genreName?.trim() ?? '';
    return switch (type) {
      RecommendationReasonType.similar =>
        source.isEmpty
            ? l10n.recommendationReasonSimilarGeneric
            : l10n.recommendationReasonSimilar(source),
      RecommendationReasonType.genre =>
        genre.isEmpty
            ? l10n.recommendationReasonGenreGeneric
            : l10n.recommendationReasonGenre(genre),
      RecommendationReasonType.popular => l10n.recommendationReasonPopular,
    };
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'source_game_name': ?sourceGameName,
    'genre_name': ?genreName,
  };

  @override
  List<Object?> get props => [type, sourceGameName, genreName];
}

/// Represents a game from discovery results
class DiscoveryGame extends Equatable {
  const DiscoveryGame({
    required this.id,
    required this.name,
    this.coverUrl,
    this.totalRating,
    this.firstReleaseDate,
    this.genres = const [],
    this.reason,
  });

  factory DiscoveryGame.fromJson(Map<String, dynamic> json) {
    return DiscoveryGame(
      id: json['id'] as int,
      name: json['name'] as String,
      coverUrl: json['cover_url'] as String?,
      totalRating: (json['total_rating'] as num?)?.toDouble(),
      firstReleaseDate: parseReleaseDate(json['first_release_date']),
      genres:
          (json['genres'] as List<dynamic>?)
              ?.map((g) => Genre.fromJson(g as Map<String, dynamic>))
              .toList() ??
          const [],
      reason: RecommendationReason.fromJson(json['reason']),
    );
  }

  final int id;
  final String name;
  final String? coverUrl;
  final double? totalRating;

  /// First release (RFC3339 in the API), when known.
  final DateTime? firstReleaseDate;
  final List<Genre> genres;

  /// Set only on recommendations.
  final RecommendationReason? reason;

  /// Returns the rating as a formatted percentage string (e.g., "85%")
  String get ratingPercentage {
    if (totalRating == null) return '';
    return '${totalRating!.round()}%';
  }

  /// Returns true if the game has a rating
  bool get hasRating => totalRating != null && totalRating! > 0;

  /// Release year in UTC, when known.
  int? get releaseYear => firstReleaseDate?.toUtc().year;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'cover_url': coverUrl,
      'total_rating': totalRating,
      if (firstReleaseDate != null)
        'first_release_date': firstReleaseDate!.toUtc().toIso8601String(),
      if (genres.isNotEmpty)
        'genres': [
          for (final g in genres) {'id': g.id, 'name': g.name},
        ],
      if (reason != null) 'reason': reason!.toJson(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    coverUrl,
    totalRating,
    firstReleaseDate,
    genres,
    reason,
  ];
}

/// Represents the response from the discovery games endpoint
class DiscoveryGamesResponse extends Equatable {
  const DiscoveryGamesResponse({
    required this.games,
    required this.type,
    required this.totalCount,
    required this.hasMore,
    required this.offset,
    required this.limit,
  });

  factory DiscoveryGamesResponse.fromJson(Map<String, dynamic> json) {
    return DiscoveryGamesResponse(
      games: (json['games'] as List<dynamic>)
          .map((g) => DiscoveryGame.fromJson(g as Map<String, dynamic>))
          .toList(),
      type: json['type'] as String,
      totalCount: json['total_count'] as int,
      hasMore: json['has_more'] as bool,
      offset: json['offset'] as int,
      limit: json['limit'] as int,
    );
  }

  final List<DiscoveryGame> games;
  final String type;
  final int totalCount;
  final bool hasMore;
  final int offset;
  final int limit;

  Map<String, dynamic> toJson() {
    return {
      'games': games.map((g) => g.toJson()).toList(),
      'type': type,
      'total_count': totalCount,
      'has_more': hasMore,
      'offset': offset,
      'limit': limit,
    };
  }

  @override
  List<Object?> get props => [games, type, totalCount, hasMore, offset, limit];
}
