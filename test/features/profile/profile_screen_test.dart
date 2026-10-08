import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/core/theme/app_theme.dart';
import 'package:picklog/core/utils/app_router.dart';
import 'package:picklog/features/auth/bloc/auth_bloc.dart';
import 'package:picklog/features/auth/bloc/auth_state.dart';
import 'package:picklog/features/auth/user_model.dart';
import 'package:picklog/features/library/bloc/library_bloc.dart';
import 'package:picklog/features/library/bloc/library_state.dart';
import 'package:picklog/features/library/library_entry_model.dart';
import 'package:picklog/features/library/stats/library_stats_model.dart';
import 'package:picklog/features/library/stats/stats_cubit.dart';
import 'package:picklog/features/profile/profile_screen.dart';
import 'package:picklog/l10n/app_localizations.dart';

import '../../mocks/mock_blocs.dart';
import '../library/library_fixtures.dart';

class _MockStats extends MockCubit<StatsState> implements StatsCubit {}

const _user = User(id: '123', email: 'test@example.com', name: 'Test User');

const _stats = UserStats(
  totalGames: 42,
  favorites: 1,
  statusCounts: {
    GameStatus.planned: 10,
    GameStatus.playing: 3,
    GameStatus.finished: 20,
    GameStatus.dropped: 4,
    GameStatus.onHold: 5,
  },
  totalPlaytimeMinutes: 6000,
  averageScore: 78.5,
  backlogCount: 15,
  topGenres: [StatsGenre(id: 12, name: 'RPG', count: 9)],
  topPlatforms: [
    StatsPlatform(
      id: 6,
      name: 'PC (Microsoft Windows)',
      abbreviation: 'PC',
      count: 20,
    ),
  ],
  achievements: AchievementTotals(unlocked: 12, total: 40),
);

void main() {
  late MockAuthBloc auth;
  late _MockStats stats;
  late MockLibraryBloc library;
  final pushed = <String>[];

  setUp(() {
    pushed.clear();
    auth = MockAuthBloc();
    stats = _MockStats();
    library = MockLibraryBloc();
    whenListen(
      auth,
      const Stream<AuthState>.empty(),
      initialState: const AuthAuthenticated(_user),
    );
    when(
      () => stats.state,
    ).thenReturn(const StatsState(status: StatsStatus.success, stats: _stats));
    when(() => stats.load(year: any(named: 'year'))).thenAnswer((_) async {});
    when(() => library.state).thenReturn(
      LibraryState(
        status: LibraryStatus.success,
        entries: [
          entry(id: 'f', name: 'Favorite Game', favorite: true),
          entry(id: 'n', name: 'Other Game'),
        ],
      ),
    );
  });

  Widget subject({Size size = const Size(390, 1400)}) {
    GoRoute stub(String path, String name) => GoRoute(
      path: path,
      name: name,
      builder: (context, state) {
        pushed.add(state.uri.toString());
        return Scaffold(body: Text('route $path'));
      },
    );
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              ProfileScreen(now: DateTime(2026, 10, 8)),
        ),
        stub(AppRouter.settingsPath, AppRouter.settingsName),
        stub('/year/:year', AppRouter.yearInReviewName),
        stub(AppRouter.achievementsPath, AppRouter.achievementsName),
        stub('/games/:id', AppRouter.gameDetailsName),
      ],
    );
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: auth),
        BlocProvider<StatsCubit>.value(value: stats),
        BlocProvider<LibraryBloc>.value(value: library),
      ],
      child: MediaQuery(
        data: MediaQueryData(size: size),
        child: MaterialApp.router(
          theme: AppTheme.dark(),
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
        ),
      ),
    );
  }

  Future<void> pump(WidgetTester t, {Size size = const Size(390, 1600)}) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(subject(size: size));
    await t.pump(const Duration(seconds: 1));
  }

  group('ProfileScreen dashboard', () {
    testWidgets('shows initials, name, email and the member line', (t) async {
      await pump(t);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('TU'), findsOneWidget);
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('Picklog member · 42 games logged'), findsOneWidget);
    });

    testWidgets('shows the stats cards and the status distribution', (t) async {
      await pump(t);
      expect(find.bySemanticsLabel('Games: 42'), findsOneWidget);
      expect(find.bySemanticsLabel('Hours: 100'), findsOneWidget);
      expect(find.bySemanticsLabel('Avg score: 79'), findsOneWidget);
      expect(find.bySemanticsLabel('Backlog: 15'), findsOneWidget);
      expect(find.text('BY STATUS'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Planned 10, Playing 3, Finished 20, Dropped 4, On hold 5',
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows top genres, platforms and the favorites shelf', (
      t,
    ) async {
      await pump(t);
      expect(find.text('RPG'), findsOneWidget);
      expect(find.text('PC'), findsOneWidget);
      expect(
        find.textContaining('Favorite Game', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Other Game', findRichText: true),
        findsNothing,
      );
    });

    testWidgets('the achievements tile opens the achievements route', (
      t,
    ) async {
      await pump(t);
      expect(find.text('12 of 40 unlocked'), findsOneWidget);
      await t.tap(find.byKey(const Key('profile_achievements_tile')));
      await t.pumpAndSettle();
      expect(pushed, [AppRouter.achievementsPath]);
    });

    testWidgets('the year card opens this year in review', (t) async {
      await pump(t);
      expect(find.text('2026'), findsOneWidget);
      await t.tap(find.byKey(const Key('profile_year_in_review')));
      await t.pumpAndSettle();
      expect(pushed, ['/year/2026']);
    });

    testWidgets('the roulette tile opens the backlog sheet', (t) async {
      await pump(t);
      expect(find.text('15 games in backlog'), findsOneWidget);
      await t.tap(find.byKey(const Key('profile_roulette_tile')));
      await t.pumpAndSettle();
      expect(find.text('BACKLOG ROULETTE'), findsOneWidget);
    });

    testWidgets('the settings link and the gear open settings', (t) async {
      await pump(t);
      final gear = t.widget<IconButton>(
        find.byKey(const Key('profile_settings_button')),
      );
      expect(gear.tooltip, 'Settings');
      await t.tap(find.byKey(const Key('profile_settings_link')));
      await t.pumpAndSettle();
      expect(pushed, [AppRouter.settingsPath]);
    });

    testWidgets('a stats failure offers a retry', (t) async {
      when(
        () => stats.state,
      ).thenReturn(const StatsState(status: StatsStatus.failure));
      await pump(t);
      expect(find.text('Could not load your stats.'), findsOneWidget);
      await t.tap(find.text('Try again'));
      verify(() => stats.load()).called(1);
    });

    testWidgets('the wide layout uses two columns without overflow', (t) async {
      await pump(t, size: const Size(1280, 1000));
      final year = t.getTopLeft(
        find.byKey(const Key('profile_year_in_review')),
      );
      final games = t.getTopLeft(find.bySemanticsLabel('Games: 42'));
      expect(year.dx, greaterThan(games.dx + 400));
      expect(t.takeException(), isNull);
    });

    testWidgets('updates when the auth state changes', (t) async {
      whenListen(
        auth,
        Stream<AuthState>.fromIterable(const [
          AuthAuthenticated(
            User(id: '1', email: 'updated@example.com', name: 'Updated User'),
          ),
        ]),
        initialState: const AuthAuthenticated(_user),
      );
      await pump(t);
      expect(find.text('Updated User'), findsOneWidget);
      expect(find.text('UU'), findsOneWidget);
    });

    testWidgets('shows a fallback when not authenticated', (t) async {
      whenListen(
        auth,
        const Stream<AuthState>.empty(),
        initialState: const AuthUnauthenticated(),
      );
      await pump(t);
      expect(find.text('No user information available'), findsOneWidget);
    });
  });

  test('profileInitials uses up to two words', () {
    expect(profileInitials('Elberte Plinio'), 'EP');
    expect(profileInitials('solo'), 'S');
    expect(profileInitials('   '), '?');
    expect(profileInitials('ana_maria.souza'), 'AM');
  });
}
