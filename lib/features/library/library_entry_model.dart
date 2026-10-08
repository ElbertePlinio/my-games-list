import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/features/games/game_detail_model.dart';
import 'package:picklog/features/games/release_date.dart';

/// Enum representing the status of a game in the user's library
enum GameStatus {
  planned,
  playing,
  finished,
  dropped,
  onHold;

  /// Creates a GameStatus from a string value
  static GameStatus fromString(String value) {
    switch (value) {
      case 'planned':
        return GameStatus.planned;
      case 'playing':
        return GameStatus.playing;
      case 'finished':
        return GameStatus.finished;
      case 'dropped':
        return GameStatus.dropped;
      case 'on_hold':
        return GameStatus.onHold;
      default:
        return GameStatus.planned;
    }
  }

  /// Converts the GameStatus to a string value for API
  String toApiString() {
    switch (this) {
      case GameStatus.planned:
        return 'planned';
      case GameStatus.playing:
        return 'playing';
      case GameStatus.finished:
        return 'finished';
      case GameStatus.dropped:
        return 'dropped';
      case GameStatus.onHold:
        return 'on_hold';
    }
  }

  /// Returns the localized display name for the current locale.
  String localizedName(BuildContext context) {
    switch (this) {
      case GameStatus.planned:
        return context.l10n.statusPlanned;
      case GameStatus.playing:
        return context.l10n.statusPlaying;
      case GameStatus.finished:
        return context.l10n.statusFinished;
      case GameStatus.dropped:
        return context.l10n.statusDropped;
      case GameStatus.onHold:
        return context.l10n.statusOnHold;
    }
  }
}

/// Represents a cached game from IGDB stored in the backend
class CachedGame extends Equatable {
  const CachedGame({
    required this.id,
    required this.igdbId,
    required this.name,
    this.coverUrl,
    this.firstReleaseDate,
    required this.lastSyncedAt,
    this.totalRating,
    this.slug,
    this.genres = const [],
  });

  factory CachedGame.fromJson(Map<String, dynamic> json) {
    return CachedGame(
      id: json['id'] as String? ?? '',
      igdbId: json['igdb_id'] as int,
      name: json['name'] as String,
      coverUrl: json['cover_url'] as String?,
      firstReleaseDate: parseReleaseDate(json['first_release_date']),
      lastSyncedAt: DateTime.parse(json['last_synced_at'] as String),
      totalRating: (json['total_rating'] as num?)?.toDouble(),
      slug: json['slug'] as String?,
      genres:
          (json['genres'] as List<dynamic>?)
              ?.map((g) => Genre.fromJson(g as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  final String id;
  final int igdbId;
  final String name;
  final String? coverUrl;
  final DateTime? firstReleaseDate;
  final DateTime lastSyncedAt;

  /// IGDB community rating, 0-100.
  final double? totalRating;
  final String? slug;
  final List<Genre> genres;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'igdb_id': igdbId,
      'name': name,
      'cover_url': coverUrl,
      'first_release_date': firstReleaseDate?.toIso8601String(),
      'last_synced_at': lastSyncedAt.toIso8601String(),
      'total_rating': totalRating,
      'slug': slug,
      'genres': [
        for (final g in genres) {'id': g.id, 'name': g.name},
      ],
    };
  }

  @override
  List<Object?> get props => [
    id,
    igdbId,
    name,
    coverUrl,
    firstReleaseDate,
    lastSyncedAt,
    totalRating,
    slug,
    genres,
  ];
}

/// Represents a cached platform from IGDB stored in the backend
class CachedPlatform extends Equatable {
  const CachedPlatform({
    required this.id,
    required this.igdbPlatformId,
    required this.name,
    this.abbreviation,
    this.logoUrl,
  });

  factory CachedPlatform.fromJson(Map<String, dynamic> json) {
    return CachedPlatform(
      id: json['id'] as String? ?? '',
      igdbPlatformId: json['igdb_platform_id'] as int,
      name: json['name'] as String,
      abbreviation: json['abbreviation'] as String?,
      logoUrl: json['logo_url'] as String?,
    );
  }

  final String id;
  final int igdbPlatformId;
  final String name;
  final String? abbreviation;
  final String? logoUrl;

  /// Returns the abbreviation if available, otherwise the full name
  String get displayName => abbreviation ?? name;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'igdb_platform_id': igdbPlatformId,
      'name': name,
      'abbreviation': abbreviation,
      'logo_url': logoUrl,
    };
  }

  @override
  List<Object?> get props => [id, igdbPlatformId, name, abbreviation, logoUrl];
}

/// Represents a library entry - a game in the user's library with tracking data
class LibraryEntry extends Equatable {
  const LibraryEntry({
    required this.id,
    required this.userId,
    required this.game,
    this.platform,
    required this.status,
    this.score,
    this.playtimeMinutes,
    this.startDate,
    this.endDate,
    this.difficulty,
    required this.isFavorite,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.collectionIds = const [],
  });

  factory LibraryEntry.fromJson(Map<String, dynamic> json) {
    return LibraryEntry(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      game: CachedGame.fromJson(json['game'] as Map<String, dynamic>),
      platform: json['platform'] != null
          ? CachedPlatform.fromJson(json['platform'] as Map<String, dynamic>)
          : null,
      status: GameStatus.fromString(json['status'] as String),
      score: json['score'] as int?,
      playtimeMinutes: json['playtime_minutes'] as int?,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      difficulty: json['difficulty'] as String?,
      isFavorite: json['is_favorite'] as bool,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      collectionIds:
          (json['collection_ids'] as List<dynamic>?)
              ?.map((id) => id as String)
              .toList() ??
          const [],
    );
  }

  final String id;
  final String userId;
  final CachedGame game;
  final CachedPlatform? platform;
  final GameStatus status;
  final int? score;
  final int? playtimeMinutes;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? difficulty;
  final bool isFavorite;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Ids of the caller's collections that hold this entry.
  final List<String> collectionIds;

  /// Returns a copy of this entry with updated fields
  LibraryEntry copyWith({
    String? id,
    String? userId,
    CachedGame? game,
    CachedPlatform? platform,
    GameStatus? status,
    int? score,
    int? playtimeMinutes,
    DateTime? startDate,
    DateTime? endDate,
    String? difficulty,
    bool? isFavorite,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? collectionIds,
  }) {
    return LibraryEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      game: game ?? this.game,
      platform: platform ?? this.platform,
      status: status ?? this.status,
      score: score ?? this.score,
      playtimeMinutes: playtimeMinutes ?? this.playtimeMinutes,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      difficulty: difficulty ?? this.difficulty,
      isFavorite: isFavorite ?? this.isFavorite,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      collectionIds: collectionIds ?? this.collectionIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'game': game.toJson(),
      'platform': platform?.toJson(),
      'status': status.toApiString(),
      'score': score,
      'playtime_minutes': playtimeMinutes,
      'start_date': startDate?.toIso8601String().split('T').first,
      'end_date': endDate?.toIso8601String().split('T').first,
      'difficulty': difficulty,
      'is_favorite': isFavorite,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'collection_ids': collectionIds,
    };
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    game,
    platform,
    status,
    score,
    playtimeMinutes,
    startDate,
    endDate,
    difficulty,
    isFavorite,
    notes,
    createdAt,
    updatedAt,
    collectionIds,
  ];
}

/// The entry fields that PUT /library/{id} replaces on every call.
///
/// The API sets these columns straight from the request, so an omitted field
/// becomes null. Every update sends all of them: [LibraryEntryDetails.of]
/// keeps the current values, and a null field here clears that value.
class LibraryEntryDetails extends Equatable {
  const LibraryEntryDetails({
    this.score,
    this.startDate,
    this.endDate,
    this.difficulty,
    this.notes,
  });

  /// The current values of [entry], to send back unchanged.
  factory LibraryEntryDetails.of(LibraryEntry entry) => LibraryEntryDetails(
    score: entry.score,
    startDate: entry.startDate,
    endDate: entry.endDate,
    difficulty: entry.difficulty,
    notes: entry.notes,
  );

  final int? score;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? difficulty;
  final String? notes;

  /// Request fields. Null values are kept so the payload is always complete.
  Map<String, dynamic> toJson() => {
    'score': score,
    'start_date': _apiDate(startDate),
    'end_date': _apiDate(endDate),
    'difficulty': difficulty,
    'notes': notes,
  };

  static String? _apiDate(DateTime? date) =>
      date?.toIso8601String().split('T').first;

  @override
  List<Object?> get props => [score, startDate, endDate, difficulty, notes];
}

/// Response model for library entries list
class LibraryEntriesResponse extends Equatable {
  const LibraryEntriesResponse({
    required this.entries,
    required this.totalCount,
  });

  factory LibraryEntriesResponse.fromJson(Map<String, dynamic> json) {
    return LibraryEntriesResponse(
      entries: (json['entries'] as List<dynamic>)
          .map((e) => LibraryEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCount: json['total_count'] as int,
    );
  }

  final List<LibraryEntry> entries;
  final int totalCount;

  @override
  List<Object?> get props => [entries, totalCount];
}
