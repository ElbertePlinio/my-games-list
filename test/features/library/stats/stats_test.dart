import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/core/data/services/http/i_http_client.dart';
import 'package:picklog/core/domain/models/api_response.dart';
import 'package:picklog/core/domain/models/app_failure.dart';
import 'package:picklog/features/library/library_entry_model.dart';
import 'package:picklog/features/library/stats/library_stats_model.dart';
import 'package:picklog/features/library/stats/stats_cubit.dart';
import 'package:picklog/features/library/stats/stats_repository.dart';

class _MockHttp extends Mock implements IHttpClient {}

class _MockStatsRepo extends Mock implements StatsRepository {}

Map<String, dynamic> statsJson({bool withYear = true}) => {
  'total_games': 42,
  'favorites': 5,
  'status_counts': {
    'planned': 10,
    'playing': 3,
    'finished': 20,
    'dropped': 4,
    'on_hold': 5,
  },
  'total_playtime_minutes': 12345,
  'average_score': 78.5,
  'backlog_count': 15,
  'backlog_estimated_minutes': null,
  'top_genres': [
    {'id': 12, 'name': 'RPG', 'count': 9},
  ],
  'top_platforms': [
    {
      'id': 6,
      'name': 'PC (Microsoft Windows)',
      'abbreviation': 'PC',
      'count': 20,
    },
  ],
  'achievements': {'unlocked': 3, 'total': 10},
  if (withYear) 'year': 2026,
  if (withYear)
    'year_summary': {
      'added': 12,
      'finished': 7,
      'playtime_minutes': 3000,
      'by_month': [
        {'month': 1, 'added': 2, 'finished': 1},
        {'month': 3, 'added': 1, 'finished': 0},
      ],
      'top_rated': [
        {
          'library_entry_id': 'e1',
          'igdb_id': 1,
          'name': 'X',
          'cover_url': 'c',
          'score': 95,
        },
      ],
      'first_finished': null,
      'longest_session_game': null,
    },
};

void main() {
  group('UserStats.fromJson', () {
    test('parses counts, top lists and achievements', () {
      final stats = UserStats.fromJson(statsJson(withYear: false));
      expect(stats.totalGames, 42);
      expect(stats.countFor(GameStatus.onHold), 5);
      expect(stats.averageScore, 78.5);
      expect(stats.backlogEstimatedMinutes, isNull);
      expect(stats.topGenres.single.name, 'RPG');
      expect(stats.topPlatforms.single.displayName, 'PC');
      expect(
        stats.achievements,
        const AchievementTotals(unlocked: 3, total: 10),
      );
      expect(stats.yearSummary, isNull);
    });

    test('pads by_month to 12 months and parses the year entries', () {
      final summary = UserStats.fromJson(statsJson()).yearSummary!;
      expect(summary.byMonth, hasLength(12));
      expect(summary.byMonth[0].added, 2);
      expect(
        summary.byMonth[1],
        const StatsMonth(month: 2, added: 0, finished: 0),
      );
      expect(summary.topRated.single.score, 95);
      expect(summary.firstFinished, isNull);
      expect(summary.isEmpty, isFalse);
    });

    test('a null average score stays null', () {
      final json = statsJson(withYear: false)..['average_score'] = null;
      expect(UserStats.fromJson(json).averageScore, isNull);
    });
  });

  test('StatsRepository sends the year parameter', () async {
    final http = _MockHttp();
    when(
      () => http.get<Map<String, dynamic>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer((_) async => ApiResponse.success(statsJson()));
    final stats = await StatsRepository(httpClient: http).getStats(year: 2026);
    expect(stats.year, 2026);
    verify(
      () => http.get<Map<String, dynamic>>(
        '/users/me/stats',
        queryParameters: {'year': '2026'},
      ),
    ).called(1);
  });

  group('StatsCubit', () {
    late _MockStatsRepo repo;
    setUp(() => repo = _MockStatsRepo());

    blocTest<StatsCubit, StatsState>(
      'loads stats for the year',
      setUp: () => when(
        () => repo.getStats(year: any(named: 'year')),
      ).thenAnswer((_) async => UserStats.fromJson(statsJson())),
      build: () => StatsCubit(statsRepository: repo, year: 2026),
      act: (c) => c.load(),
      expect: () => [
        const StatsState(status: StatsStatus.loading, year: 2026),
        isA<StatsState>()
            .having((s) => s.status, 'status', StatsStatus.success)
            .having((s) => s.stats?.yearSummary?.added, 'added', 12),
      ],
    );

    blocTest<StatsCubit, StatsState>(
      'a failed reload keeps the shown stats',
      setUp: () => when(
        () => repo.getStats(year: any(named: 'year')),
      ).thenThrow(Exception('x')),
      build: () => StatsCubit(statsRepository: repo),
      seed: () => StatsState(
        status: StatsStatus.success,
        stats: UserStats.fromJson(statsJson(withYear: false)),
      ),
      act: (c) => c.load(),
      skip: 1,
      expect: () => [
        isA<StatsState>()
            .having((s) => s.status, 'status', StatsStatus.failure)
            .having((s) => s.hasStats, 'hasStats', true)
            .having((s) => s.errorKind, 'kind', AppErrorKind.unknown),
      ],
    );

    blocTest<StatsCubit, StatsState>(
      'a new year clears the previous stats while loading',
      setUp: () => when(
        () => repo.getStats(year: any(named: 'year')),
      ).thenAnswer((_) async => UserStats.fromJson(statsJson())),
      build: () => StatsCubit(statsRepository: repo, year: 2025),
      seed: () => StatsState(
        status: StatsStatus.success,
        year: 2025,
        stats: UserStats.fromJson(statsJson()),
      ),
      act: (c) => c.load(year: 2024),
      expect: () => [
        const StatsState(status: StatsStatus.loading, year: 2024),
        isA<StatsState>().having((s) => s.year, 'year', 2024),
      ],
    );
  });
}
