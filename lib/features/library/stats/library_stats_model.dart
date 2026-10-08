import 'package:equatable/equatable.dart';
import 'package:picklog/features/library/library_entry_model.dart';

/// A genre with the number of library games that have it.
class StatsGenre extends Equatable {
  const StatsGenre({required this.id, required this.name, required this.count});

  factory StatsGenre.fromJson(Map<String, dynamic> json) => StatsGenre(
    id: json['id'] as int,
    name: json['name'] as String,
    count: json['count'] as int? ?? 0,
  );

  final int id;
  final String name;
  final int count;

  @override
  List<Object?> get props => [id, name, count];
}

/// A platform with the number of library entries on it.
class StatsPlatform extends Equatable {
  const StatsPlatform({
    required this.id,
    required this.name,
    required this.count,
    this.abbreviation,
  });

  factory StatsPlatform.fromJson(Map<String, dynamic> json) => StatsPlatform(
    id: json['id'] as int,
    name: json['name'] as String,
    abbreviation: json['abbreviation'] as String?,
    count: json['count'] as int? ?? 0,
  );

  final int id;
  final String name;
  final String? abbreviation;
  final int count;

  /// The abbreviation when present, otherwise the full name.
  String get displayName =>
      (abbreviation?.isNotEmpty ?? false) ? abbreviation! : name;

  @override
  List<Object?> get props => [id, name, abbreviation, count];
}

/// Added and finished counts for one month of a year summary.
class StatsMonth extends Equatable {
  const StatsMonth({
    required this.month,
    required this.added,
    required this.finished,
  });

  factory StatsMonth.fromJson(Map<String, dynamic> json) => StatsMonth(
    month: json['month'] as int,
    added: json['added'] as int? ?? 0,
    finished: json['finished'] as int? ?? 0,
  );

  /// 1 (January) to 12 (December).
  final int month;
  final int added;
  final int finished;

  @override
  List<Object?> get props => [month, added, finished];
}

/// A library entry highlighted in a year summary.
class StatsYearEntry extends Equatable {
  const StatsYearEntry({
    required this.libraryEntryId,
    required this.igdbId,
    required this.name,
    this.coverUrl,
    this.score,
    this.playtimeMinutes,
  });

  factory StatsYearEntry.fromJson(Map<String, dynamic> json) => StatsYearEntry(
    libraryEntryId: json['library_entry_id'] as String? ?? '',
    igdbId: json['igdb_id'] as int,
    name: json['name'] as String,
    coverUrl: json['cover_url'] as String?,
    score: json['score'] as int?,
    playtimeMinutes: json['playtime_minutes'] as int?,
  );

  final String libraryEntryId;
  final int igdbId;
  final String name;
  final String? coverUrl;
  final int? score;
  final int? playtimeMinutes;

  @override
  List<Object?> get props => [
    libraryEntryId,
    igdbId,
    name,
    coverUrl,
    score,
    playtimeMinutes,
  ];
}

/// The year-in-review block of the stats response.
class YearSummary extends Equatable {
  const YearSummary({
    required this.added,
    required this.finished,
    required this.playtimeMinutes,
    required this.byMonth,
    this.topRated = const [],
    this.firstFinished,
    this.longestSessionGame,
  });

  factory YearSummary.fromJson(Map<String, dynamic> json) {
    final months =
        (json['by_month'] as List<dynamic>?)
            ?.map((m) => StatsMonth.fromJson(m as Map<String, dynamic>))
            .toList() ??
        const <StatsMonth>[];
    return YearSummary(
      added: json['added'] as int? ?? 0,
      finished: json['finished'] as int? ?? 0,
      playtimeMinutes: (json['playtime_minutes'] as num?)?.toInt() ?? 0,
      byMonth: _fillMonths(months),
      topRated:
          (json['top_rated'] as List<dynamic>?)
              ?.map((e) => StatsYearEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      firstFinished: _entry(json['first_finished']),
      longestSessionGame: _entry(json['longest_session_game']),
    );
  }

  final int added;
  final int finished;
  final int playtimeMinutes;

  /// Always 12 items, January first.
  final List<StatsMonth> byMonth;
  final List<StatsYearEntry> topRated;
  final StatsYearEntry? firstFinished;
  final StatsYearEntry? longestSessionGame;

  /// True when nothing was added or finished in the year.
  bool get isEmpty => added == 0 && finished == 0 && playtimeMinutes == 0;

  static StatsYearEntry? _entry(Object? json) =>
      json is Map<String, dynamic> ? StatsYearEntry.fromJson(json) : null;

  /// Pads missing months with zeros so charts always draw 12 bars.
  static List<StatsMonth> _fillMonths(List<StatsMonth> months) {
    final byNumber = {for (final m in months) m.month: m};
    return [
      for (var month = 1; month <= 12; month++)
        byNumber[month] ?? StatsMonth(month: month, added: 0, finished: 0),
    ];
  }

  @override
  List<Object?> get props => [
    added,
    finished,
    playtimeMinutes,
    byMonth,
    topRated,
    firstFinished,
    longestSessionGame,
  ];
}

/// Achievement totals across linked accounts.
class AchievementTotals extends Equatable {
  const AchievementTotals({this.unlocked = 0, this.total = 0});

  factory AchievementTotals.fromJson(Map<String, dynamic>? json) =>
      AchievementTotals(
        unlocked: json?['unlocked'] as int? ?? 0,
        total: json?['total'] as int? ?? 0,
      );

  final int unlocked;
  final int total;

  @override
  List<Object?> get props => [unlocked, total];
}

/// Response of `GET /users/me/stats`.
class UserStats extends Equatable {
  const UserStats({
    this.totalGames = 0,
    this.favorites = 0,
    this.statusCounts = const {},
    this.totalPlaytimeMinutes = 0,
    this.averageScore,
    this.backlogCount = 0,
    this.backlogEstimatedMinutes,
    this.topGenres = const [],
    this.topPlatforms = const [],
    this.year,
    this.yearSummary,
    this.achievements = const AchievementTotals(),
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    final rawCounts =
        (json['status_counts'] as Map<String, dynamic>?) ?? const {};
    return UserStats(
      totalGames: json['total_games'] as int? ?? 0,
      favorites: json['favorites'] as int? ?? 0,
      statusCounts: {
        for (final status in GameStatus.values)
          status: (rawCounts[status.toApiString()] as num?)?.toInt() ?? 0,
      },
      totalPlaytimeMinutes:
          (json['total_playtime_minutes'] as num?)?.toInt() ?? 0,
      averageScore: (json['average_score'] as num?)?.toDouble(),
      backlogCount: json['backlog_count'] as int? ?? 0,
      backlogEstimatedMinutes: (json['backlog_estimated_minutes'] as num?)
          ?.toInt(),
      topGenres:
          (json['top_genres'] as List<dynamic>?)
              ?.map((g) => StatsGenre.fromJson(g as Map<String, dynamic>))
              .toList() ??
          const [],
      topPlatforms:
          (json['top_platforms'] as List<dynamic>?)
              ?.map((p) => StatsPlatform.fromJson(p as Map<String, dynamic>))
              .toList() ??
          const [],
      year: json['year'] as int?,
      yearSummary: json['year_summary'] is Map<String, dynamic>
          ? YearSummary.fromJson(json['year_summary'] as Map<String, dynamic>)
          : null,
      achievements: AchievementTotals.fromJson(
        json['achievements'] as Map<String, dynamic>?,
      ),
    );
  }

  final int totalGames;
  final int favorites;
  final Map<GameStatus, int> statusCounts;
  final int totalPlaytimeMinutes;

  /// Null when no entry has a score.
  final double? averageScore;
  final int backlogCount;
  final int? backlogEstimatedMinutes;
  final List<StatsGenre> topGenres;
  final List<StatsPlatform> topPlatforms;
  final int? year;
  final YearSummary? yearSummary;
  final AchievementTotals achievements;

  int countFor(GameStatus status) => statusCounts[status] ?? 0;

  @override
  List<Object?> get props => [
    totalGames,
    favorites,
    statusCounts,
    totalPlaytimeMinutes,
    averageScore,
    backlogCount,
    backlogEstimatedMinutes,
    topGenres,
    topPlatforms,
    year,
    yearSummary,
    achievements,
  ];
}
