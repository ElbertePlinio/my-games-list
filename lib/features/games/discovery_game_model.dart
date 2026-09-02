import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';

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

/// Represents a game from discovery results
class DiscoveryGame extends Equatable {
  const DiscoveryGame({
    required this.id,
    required this.name,
    this.coverUrl,
    this.totalRating,
  });

  factory DiscoveryGame.fromJson(Map<String, dynamic> json) {
    return DiscoveryGame(
      id: json['id'] as int,
      name: json['name'] as String,
      coverUrl: json['cover_url'] as String?,
      totalRating: (json['total_rating'] as num?)?.toDouble(),
    );
  }

  final int id;
  final String name;
  final String? coverUrl;
  final double? totalRating;

  /// Returns the rating as a formatted percentage string (e.g., "85%")
  String get ratingPercentage {
    if (totalRating == null) return '';
    return '${totalRating!.round()}%';
  }

  /// Returns true if the game has a rating
  bool get hasRating => totalRating != null && totalRating! > 0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'cover_url': coverUrl,
      'total_rating': totalRating,
    };
  }

  @override
  List<Object?> get props => [id, name, coverUrl, totalRating];
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
