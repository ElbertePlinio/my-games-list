import 'package:equatable/equatable.dart';

/// Represents a gaming platform (e.g., PlayStation 5, Xbox Series X|S)
class GamePlatform extends Equatable {
  const GamePlatform({required this.id, required this.name});

  factory GamePlatform.fromJson(Map<String, dynamic> json) {
    return GamePlatform(id: json['id'] as int, name: json['name'] as String);
  }

  final int id;
  final String name;

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }

  @override
  List<Object?> get props => [id, name];
}

/// Represents an anticipated game from IGDB
class AnticipatedGame extends Equatable {
  const AnticipatedGame({
    required this.id,
    required this.name,
    required this.coverUrl,
    required this.hypes,
    required this.firstReleaseDate,
    required this.platforms,
  });

  factory AnticipatedGame.fromJson(Map<String, dynamic> json) {
    return AnticipatedGame(
      id: json['id'] as int,
      name: json['name'] as String,
      coverUrl: json['cover_url'] as String? ?? '',
      hypes: json['hypes'] as int? ?? 0,
      firstReleaseDate: DateTime.fromMillisecondsSinceEpoch(
        (json['first_release_date'] as int) * 1000,
      ),
      platforms:
          (json['platforms'] as List<dynamic>?)
              ?.map((p) => GamePlatform.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  final int id;
  final String name;
  final String coverUrl;
  final int hypes;
  final DateTime firstReleaseDate;
  final List<GamePlatform> platforms;

  /// Returns the time remaining until release
  Duration get timeUntilRelease {
    final now = DateTime.now();
    return firstReleaseDate.difference(now);
  }

  /// Returns true if the game has been released
  bool get isReleased => timeUntilRelease.isNegative;

  /// Returns the platform names as a comma-separated string
  String get platformNames {
    return platforms.map((p) => p.name).join(', ');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'cover_url': coverUrl,
      'hypes': hypes,
      'first_release_date': firstReleaseDate.millisecondsSinceEpoch ~/ 1000,
      'platforms': platforms.map((p) => p.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    coverUrl,
    hypes,
    firstReleaseDate,
    platforms,
  ];
}

/// Response wrapper for the anticipated games API
class AnticipatedGamesResponse extends Equatable {
  const AnticipatedGamesResponse({required this.games});

  factory AnticipatedGamesResponse.fromJson(Map<String, dynamic> json) {
    return AnticipatedGamesResponse(
      games: (json['games'] as List<dynamic>)
          .map((g) => AnticipatedGame.fromJson(g as Map<String, dynamic>))
          .toList(),
    );
  }

  final List<AnticipatedGame> games;

  @override
  List<Object?> get props => [games];
}
