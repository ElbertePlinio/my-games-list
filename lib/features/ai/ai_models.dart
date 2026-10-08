import 'package:equatable/equatable.dart';

/// Moods the play-next endpoint accepts.
enum AiMood {
  chill,
  intense,
  story,
  social,
  quick,
  challenge;

  String get apiValue => name;
}

/// Response of `GET /ai/status`.
class AiStatus extends Equatable {
  const AiStatus({
    required this.enabled,
    required this.consented,
    required this.dailyLimit,
    required this.usedToday,
    this.model,
  });

  factory AiStatus.fromJson(Map<String, dynamic> json) {
    return AiStatus(
      enabled: json['enabled'] as bool? ?? false,
      consented: json['consented'] as bool? ?? false,
      dailyLimit: (json['daily_limit'] as num?)?.toInt() ?? 0,
      usedToday: (json['used_today'] as num?)?.toInt() ?? 0,
      model: json['model'] as String?,
    );
  }

  final bool enabled;
  final bool consented;
  final int dailyLimit;
  final int usedToday;
  final String? model;

  /// Requests left today, never negative.
  int get remainingToday => (dailyLimit - usedToday).clamp(0, dailyLimit);

  AiStatus copyWith({bool? consented, int? usedToday}) {
    return AiStatus(
      enabled: enabled,
      consented: consented ?? this.consented,
      dailyLimit: dailyLimit,
      usedToday: usedToday ?? this.usedToday,
      model: model,
    );
  }

  @override
  List<Object?> get props => [enabled, consented, dailyLimit, usedToday, model];
}

/// Response of `PUT /users/me/ai-consent`.
class AiConsentResult extends Equatable {
  const AiConsentResult({required this.consented, this.consentedAt});

  factory AiConsentResult.fromJson(Map<String, dynamic> json) {
    final at = json['consented_at'] as String?;
    return AiConsentResult(
      consented: json['consented'] as bool? ?? false,
      consentedAt: at == null ? null : DateTime.tryParse(at),
    );
  }

  final bool consented;
  final DateTime? consentedAt;

  @override
  List<Object?> get props => [consented, consentedAt];
}

/// Body of `POST /ai/play-next`. Every field is optional.
class PlayNextRequest extends Equatable {
  const PlayNextRequest({
    this.minutesAvailable,
    this.mood,
    this.platformId,
    this.note,
  });

  final int? minutesAvailable;
  final AiMood? mood;
  final int? platformId;
  final String? note;

  Map<String, dynamic> toJson() {
    final trimmed = note?.trim();
    return {
      if (minutesAvailable != null) 'minutes_available': minutesAvailable,
      if (mood != null) 'mood': mood!.apiValue,
      if (platformId != null) 'platform_id': platformId,
      if (trimmed != null && trimmed.isNotEmpty) 'note': trimmed,
    };
  }

  @override
  List<Object?> get props => [minutesAvailable, mood, platformId, note];
}

/// A game reference inside a play-next pick.
class AiGameRef extends Equatable {
  const AiGameRef({required this.igdbId, required this.name, this.coverUrl});

  factory AiGameRef.fromJson(Map<String, dynamic> json) {
    final cover = json['cover_url'] as String?;
    return AiGameRef(
      igdbId: (json['igdb_id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      coverUrl: cover == null || cover.isEmpty ? null : cover,
    );
  }

  final int igdbId;
  final String name;
  final String? coverUrl;

  @override
  List<Object?> get props => [igdbId, name, coverUrl];
}

/// One play-next suggestion from the user's backlog.
class PlayNextPick extends Equatable {
  const PlayNextPick({
    required this.libraryEntryId,
    required this.game,
    required this.reason,
    required this.estimatedSessionMinutes,
  });

  factory PlayNextPick.fromJson(Map<String, dynamic> json) {
    return PlayNextPick(
      libraryEntryId: json['library_entry_id'] as String,
      game: AiGameRef.fromJson(json['game'] as Map<String, dynamic>),
      reason: json['reason'] as String? ?? '',
      estimatedSessionMinutes:
          (json['estimated_session_minutes'] as num?)?.toInt() ?? 0,
    );
  }

  final String libraryEntryId;
  final AiGameRef game;
  final String reason;
  final int estimatedSessionMinutes;

  @override
  List<Object?> get props => [
    libraryEntryId,
    game,
    reason,
    estimatedSessionMinutes,
  ];
}

/// Response of `POST /ai/play-next`.
class PlayNextResult extends Equatable {
  const PlayNextResult({
    required this.picks,
    required this.remainingToday,
    this.model,
    this.generatedAt,
  });

  factory PlayNextResult.fromJson(Map<String, dynamic> json) {
    final picks = json['picks'] as List<dynamic>? ?? const [];
    return PlayNextResult(
      picks: [
        for (final p in picks) PlayNextPick.fromJson(p as Map<String, dynamic>),
      ],
      remainingToday: (json['remaining_today'] as num?)?.toInt() ?? 0,
      model: json['model'] as String?,
      generatedAt: DateTime.tryParse(json['generated_at'] as String? ?? ''),
    );
  }

  final List<PlayNextPick> picks;
  final int remainingToday;
  final String? model;
  final DateTime? generatedAt;

  @override
  List<Object?> get props => [picks, remainingToday, model, generatedAt];
}

/// A catalogue game inside a discover pick.
class AiDiscoverGame extends Equatable {
  const AiDiscoverGame({
    required this.id,
    required this.name,
    this.coverUrl,
    this.totalRating,
    this.firstReleaseDate,
  });

  factory AiDiscoverGame.fromJson(Map<String, dynamic> json) {
    final cover = json['cover_url'] as String?;
    return AiDiscoverGame(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      coverUrl: cover == null || cover.isEmpty ? null : cover,
      totalRating: (json['total_rating'] as num?)?.toDouble(),
      firstReleaseDate: DateTime.tryParse(
        json['first_release_date'] as String? ?? '',
      ),
    );
  }

  final int id;
  final String name;
  final String? coverUrl;
  final double? totalRating;
  final DateTime? firstReleaseDate;

  @override
  List<Object?> get props => [
    id,
    name,
    coverUrl,
    totalRating,
    firstReleaseDate,
  ];
}

/// One discover suggestion: a game the user does not own yet.
class DiscoverPick extends Equatable {
  const DiscoverPick({required this.game, required this.reason});

  factory DiscoverPick.fromJson(Map<String, dynamic> json) {
    return DiscoverPick(
      game: AiDiscoverGame.fromJson(json['game'] as Map<String, dynamic>),
      reason: json['reason'] as String? ?? '',
    );
  }

  final AiDiscoverGame game;
  final String reason;

  @override
  List<Object?> get props => [game, reason];
}

/// Response of `POST /ai/discover`.
class DiscoverResult extends Equatable {
  const DiscoverResult({
    required this.picks,
    required this.remainingToday,
    this.model,
    this.generatedAt,
  });

  factory DiscoverResult.fromJson(Map<String, dynamic> json) {
    final picks = json['picks'] as List<dynamic>? ?? const [];
    return DiscoverResult(
      picks: [
        for (final p in picks) DiscoverPick.fromJson(p as Map<String, dynamic>),
      ],
      remainingToday: (json['remaining_today'] as num?)?.toInt() ?? 0,
      model: json['model'] as String?,
      generatedAt: DateTime.tryParse(json['generated_at'] as String? ?? ''),
    );
  }

  final List<DiscoverPick> picks;
  final int remainingToday;
  final String? model;
  final DateTime? generatedAt;

  @override
  List<Object?> get props => [picks, remainingToday, model, generatedAt];
}
