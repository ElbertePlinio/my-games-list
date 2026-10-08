import 'package:equatable/equatable.dart';
import 'package:picklog/features/games/release_date.dart';

/// Represents the cover image for a game.
class GameDetailCover extends Equatable {
  const GameDetailCover({required this.id, required this.url});

  factory GameDetailCover.fromJson(Map<String, dynamic> json) {
    return GameDetailCover(id: json['id'] as int, url: json['url'] as String);
  }

  final int id;
  final String url;

  @override
  List<Object?> get props => [id, url];
}

/// Represents a game genre.
class Genre extends Equatable {
  const Genre({required this.id, required this.name});

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(id: json['id'] as int, name: json['name'] as String);
  }

  final int id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}

/// Represents a gaming platform.
class Platform extends Equatable {
  const Platform({required this.id, required this.name});

  factory Platform.fromJson(Map<String, dynamic> json) {
    return Platform(id: json['id'] as int, name: json['name'] as String);
  }

  final int id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}

/// Represents a company (developer/publisher).
class Company extends Equatable {
  const Company({required this.id, required this.name});

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(id: json['id'] as int, name: json['name'] as String);
  }

  final int id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}

/// Represents a company involved in game development/publishing.
class InvolvedCompany extends Equatable {
  const InvolvedCompany({
    required this.id,
    required this.company,
    required this.developer,
  });

  factory InvolvedCompany.fromJson(Map<String, dynamic> json) {
    return InvolvedCompany(
      id: json['id'] as int,
      company: Company.fromJson(json['company'] as Map<String, dynamic>),
      developer: json['developer'] as bool? ?? false,
    );
  }

  final int id;
  final Company company;
  final bool developer;

  @override
  List<Object?> get props => [id, company, developer];
}

/// Represents a game screenshot.
class Screenshot extends Equatable {
  const Screenshot({required this.id, required this.url});

  factory Screenshot.fromJson(Map<String, dynamic> json) {
    return Screenshot(id: json['id'] as int, url: json['url'] as String);
  }

  final int id;
  final String url;

  @override
  List<Object?> get props => [id, url];
}

/// Represents a game video (YouTube).
class Video extends Equatable {
  const Video({required this.id, required this.videoId});

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(id: json['id'] as int, videoId: json['video_id'] as String);
  }

  final int id;
  final String videoId;

  /// Returns the YouTube thumbnail URL for this video.
  String get thumbnailUrl =>
      'https://img.youtube.com/vi/$videoId/mqdefault.jpg';

  /// Returns the high-quality YouTube thumbnail URL.
  String get highQualityThumbnailUrl =>
      'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';

  @override
  List<Object?> get props => [id, videoId];
}

/// Represents a game-related website.
class Website extends Equatable {
  const Website({required this.id, required this.url, required this.category});

  factory Website.fromJson(Map<String, dynamic> json) {
    return Website(
      id: json['id'] as int,
      url: json['url'] as String,
      category: json['category'] as int,
    );
  }

  final int id;
  final String url;
  final int category;

  @override
  List<Object?> get props => [id, url, category];
}

/// Represents the cover for a similar game.
class SimilarGameCover extends Equatable {
  const SimilarGameCover({required this.id, required this.url});

  factory SimilarGameCover.fromJson(Map<String, dynamic> json) {
    return SimilarGameCover(id: json['id'] as int, url: json['url'] as String);
  }

  final int id;
  final String url;

  @override
  List<Object?> get props => [id, url];
}

/// Represents a similar game.
class SimilarGame extends Equatable {
  const SimilarGame({required this.id, required this.name, this.cover});

  factory SimilarGame.fromJson(Map<String, dynamic> json) {
    return SimilarGame(
      id: json['id'] as int,
      name: json['name'] as String,
      cover: json['cover'] != null
          ? SimilarGameCover.fromJson(json['cover'] as Map<String, dynamic>)
          : null,
    );
  }

  final int id;
  final String name;
  final SimilarGameCover? cover;

  @override
  List<Object?> get props => [id, name, cover];
}

/// Represents detailed game information.
class GameDetail extends Equatable {
  const GameDetail({
    required this.id,
    required this.name,
    this.summary,
    this.storyline,
    this.cover,
    required this.screenshots,
    required this.videos,
    required this.genres,
    required this.platforms,
    this.firstReleaseDate,
    this.totalRating,
    required this.involvedCompanies,
    required this.websites,
    required this.similarGames,
  });

  factory GameDetail.fromJson(Map<String, dynamic> json) {
    return GameDetail(
      id: json['id'] as int,
      name: json['name'] as String,
      summary: json['summary'] as String?,
      storyline: json['storyline'] as String?,
      cover: json['cover'] != null
          ? GameDetailCover.fromJson(json['cover'] as Map<String, dynamic>)
          : null,
      screenshots:
          (json['screenshots'] as List<dynamic>?)
              ?.map((s) => Screenshot.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      videos:
          (json['videos'] as List<dynamic>?)
              ?.map((v) => Video.fromJson(v as Map<String, dynamic>))
              .toList() ??
          [],
      genres:
          (json['genres'] as List<dynamic>?)
              ?.map((g) => Genre.fromJson(g as Map<String, dynamic>))
              .toList() ??
          [],
      platforms:
          (json['platforms'] as List<dynamic>?)
              ?.map((p) => Platform.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      firstReleaseDate: parseReleaseDate(json['first_release_date']),
      totalRating: (json['total_rating'] as num?)?.toDouble(),
      involvedCompanies:
          (json['involved_companies'] as List<dynamic>?)
              ?.map(
                (ic) => InvolvedCompany.fromJson(ic as Map<String, dynamic>),
              )
              .toList() ??
          [],
      websites:
          (json['websites'] as List<dynamic>?)
              ?.map((w) => Website.fromJson(w as Map<String, dynamic>))
              .toList() ??
          [],
      similarGames:
          (json['similar_games'] as List<dynamic>?)
              ?.map((sg) => SimilarGame.fromJson(sg as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  final int id;
  final String name;
  final String? summary;
  final String? storyline;
  final GameDetailCover? cover;
  final List<Screenshot> screenshots;
  final List<Video> videos;
  final List<Genre> genres;
  final List<Platform> platforms;
  final DateTime? firstReleaseDate;
  final double? totalRating;
  final List<InvolvedCompany> involvedCompanies;
  final List<Website> websites;
  final List<SimilarGame> similarGames;

  /// Converts the total rating (0-100) to a 5-star rating.
  double get fiveStarRating => (totalRating ?? 0) / 20;

  /// Returns the developer company, if available.
  Company? get developer {
    final developerCompany = involvedCompanies.where((ic) => ic.developer);
    return developerCompany.isNotEmpty ? developerCompany.first.company : null;
  }

  /// Returns all publishers (non-developer companies).
  List<Company> get publishers {
    return involvedCompanies
        .where((ic) => !ic.developer)
        .map((ic) => ic.company)
        .toList();
  }

  /// Returns true if the game has a cover image.
  bool get hasCover => cover != null && cover!.url.isNotEmpty;

  /// Returns true if the game has been released.
  bool get isReleased {
    if (firstReleaseDate == null) return false;
    return firstReleaseDate!.isBefore(DateTime.now());
  }

  @override
  List<Object?> get props => [
    id,
    name,
    summary,
    storyline,
    cover,
    screenshots,
    videos,
    genres,
    platforms,
    firstReleaseDate,
    totalRating,
    involvedCompanies,
    websites,
    similarGames,
  ];
}

/// Response wrapper for game detail endpoint.
class GameDetailResponse extends Equatable {
  const GameDetailResponse({required this.game});

  factory GameDetailResponse.fromJson(Map<String, dynamic> json) {
    return GameDetailResponse(
      game: GameDetail.fromJson(json['game'] as Map<String, dynamic>),
    );
  }

  final GameDetail game;

  @override
  List<Object?> get props => [game];
}
