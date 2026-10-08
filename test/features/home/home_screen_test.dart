import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/core/theme/app_theme.dart';
import 'package:picklog/core/utils/app_router.dart';
import 'package:picklog/core/widgets/brand_mark.dart';
import 'package:picklog/core/widgets/section_header.dart';
import 'package:picklog/features/ai/ai_models.dart';
import 'package:picklog/features/ai/bloc/ai_status_cubit.dart';
import 'package:picklog/features/auth/bloc/auth_state.dart';
import 'package:picklog/features/auth/user_model.dart';
import 'package:picklog/features/games/anticipated_game_model.dart';
import 'package:picklog/features/games/bloc/anticipated_games_bloc.dart';
import 'package:picklog/features/games/bloc/anticipated_games_event.dart';
import 'package:picklog/features/games/bloc/anticipated_games_state.dart';
import 'package:picklog/features/games/bloc/collections_bloc.dart';
import 'package:picklog/features/games/bloc/collections_event.dart';
import 'package:picklog/features/games/bloc/collections_state.dart';
import 'package:picklog/features/games/bloc/discovery_games_bloc.dart';
import 'package:picklog/features/games/bloc/discovery_games_event.dart';
import 'package:picklog/features/games/bloc/discovery_games_state.dart';
import 'package:picklog/features/games/bloc/featured_banners_bloc.dart';
import 'package:picklog/features/games/bloc/featured_banners_event.dart';
import 'package:picklog/features/games/bloc/featured_banners_state.dart';
import 'package:picklog/features/games/bloc/recommendations_bloc.dart';
import 'package:picklog/features/games/bloc/recommendations_event.dart';
import 'package:picklog/features/games/bloc/recommendations_state.dart';
import 'package:picklog/features/games/discovery_game_model.dart';
import 'package:picklog/features/games/widgets/anticipated_games_carousel.dart';
import 'package:picklog/features/games/widgets/discovery_game_tile.dart';
import 'package:picklog/features/home/home_screen.dart';
import 'package:picklog/features/auth/bloc/auth_bloc.dart';
import 'package:picklog/l10n/app_localizations.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../mocks/mock_blocs.dart';
import '../ai/ai_fixtures.dart';

class _MockAnticipated
    extends MockBloc<AnticipatedGamesEvent, AnticipatedGamesState>
    implements AnticipatedGamesBloc {}

class _MockDiscovery extends MockBloc<DiscoveryGamesEvent, DiscoveryGamesState>
    implements DiscoveryGamesBloc {}

class _MockBanners extends MockBloc<FeaturedBannersEvent, FeaturedBannersState>
    implements FeaturedBannersBloc {}

class _MockRecommendations
    extends MockBloc<RecommendationsEvent, RecommendationsState>
    implements RecommendationsBloc {}

class _MockCollections extends MockBloc<CollectionsEvent, CollectionsState>
    implements CollectionsBloc {}

void main() {
  late _MockAnticipated anticipated;
  late _MockDiscovery discovery;
  late _MockBanners banners;
  late _MockRecommendations recommendations;
  late _MockCollections collections;
  late MockAuthBloc auth;

  setUpAll(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  setUp(() {
    anticipated = _MockAnticipated();
    discovery = _MockDiscovery();
    banners = _MockBanners();
    recommendations = _MockRecommendations();
    collections = _MockCollections();
    auth = MockAuthBloc();

    when(() => auth.state).thenReturn(
      const AuthAuthenticated(
        User(id: '1', email: 'e@x.com', name: 'Elberte Plinio'),
      ),
    );
    when(() => anticipated.state).thenReturn(
      AnticipatedGamesState(
        status: AnticipatedGamesStatus.success,
        games: [
          AnticipatedGame(
            id: 7,
            name: 'Future Game',
            coverUrl: '',
            hypes: 120,
            firstReleaseDate: DateTime.now().add(const Duration(days: 3)),
            platforms: const [],
          ),
        ],
      ),
    );
    when(() => discovery.state).thenReturn(
      const DiscoveryGamesState(
        stateByType: {
          DiscoveryType.trending: DiscoveryTypeState(
            status: DiscoveryGamesStatus.success,
            games: [DiscoveryGame(id: 1, name: 'Trend One', totalRating: 81)],
          ),
        },
      ),
    );
    when(() => banners.state).thenReturn(
      const FeaturedBannersState(status: FeaturedBannersStatus.failure),
    );
    when(() => recommendations.state).thenReturn(
      const RecommendationsState(
        status: RecommendationsStatus.success,
        games: [DiscoveryGame(id: 1, name: 'Rec One')],
      ),
    );
    when(() => collections.state).thenReturn(const CollectionsState());
  });

  Widget buildSubject({AiStatusCubit? aiStatus}) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: auth),
              BlocProvider<AnticipatedGamesBloc>.value(value: anticipated),
              BlocProvider<DiscoveryGamesBloc>.value(value: discovery),
              BlocProvider<FeaturedBannersBloc>.value(value: banners),
              BlocProvider<RecommendationsBloc>.value(value: recommendations),
              BlocProvider<CollectionsBloc>.value(value: collections),
              if (aiStatus != null)
                BlocProvider<AiStatusCubit>.value(value: aiStatus),
            ],
            child: const HomeScreen(),
          ),
        ),
        GoRoute(
          path: '/discovery/:type',
          name: AppRouter.discoveryName,
          builder: (_, state) =>
              Text('discovery ${state.pathParameters['type']}'),
        ),
        GoRoute(
          path: '/search',
          name: AppRouter.searchName,
          builder: (_, _) => const Text('search'),
        ),
      ],
    );
    return MaterialApp.router(
      theme: AppTheme.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      routerConfig: router,
    );
  }

  testWidgets('greets the user by first name with the wordmark', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(Wordmark), findsOneWidget);
    expect(find.text('PICKLOG · HOME'), findsOneWidget);
    expect(find.textContaining('Elberte'), findsOneWidget);
    expect(find.textContaining('Plinio'), findsNothing);
  });

  testWidgets('every row uses the shared section header', (tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(buildSubject());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.widgetWithText(SectionHeader, 'Most anticipated'), findsOne);
    expect(
      find.widgetWithText(SectionHeader, 'Recommended for you'),
      findsOneWidget,
    );
    expect(find.widgetWithText(SectionHeader, 'Trending now'), findsOneWidget);
    expect(find.text('3d 0h 0m'), findsNothing); // localized, not raw
    expect(find.text('120 hypes'), findsOneWidget);
  });

  testWidgets('a failed featured row shows an inline retry', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text("Couldn't load featured picks."), findsOneWidget);
    await tester.tap(find.text('Try again').first);
    verify(() => banners.add(const FeaturedBannersLoadRequested())).called(1);
  });

  testWidgets('hero tags are unique per section', (tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(buildSubject());
    await tester.pump(const Duration(milliseconds: 500));

    // Game 1 appears in Trending and Recommended under different tags.
    expect(find.byType(DiscoveryGameTile), findsNWidgets(2));
    final tags = tester
        .widgetList<DiscoveryGameTile>(find.byType(DiscoveryGameTile))
        .map((t) => gameCoverHeroTag(t.heroTagPrefix, t.game.id))
        .toList();
    expect(tags.toSet().length, tags.length);
  });

  testWidgets('"see all" on anticipated opens the upcoming list', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(
      find.descendant(
        of: find.widgetWithText(SectionHeader, 'Most anticipated'),
        matching: find.text('See all'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('discovery upcoming'), findsOneWidget);
  });

  testWidgets('countdown labels are localized in Portuguese', (tester) async {
    late String label;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt'),
        home: Builder(
          builder: (context) {
            label = anticipatedCountdownLabel(
              context,
              AnticipatedGame(
                id: 1,
                name: 'x',
                coverUrl: '',
                hypes: 0,
                firstReleaseDate: DateTime.now().subtract(
                  const Duration(days: 1),
                ),
                platforms: const [],
              ),
            );
            return const SizedBox();
          },
        ),
      ),
    );
    expect(label, 'Já disponível');
  });

  group('AI entry', () {
    Future<AiStatusCubit> aiCubit(AiStatus status) async {
      final repository = MockAiRepository();
      when(() => repository.getStatus()).thenAnswer((_) async => status);
      final cubit = AiStatusCubit(repository: repository);
      await cubit.load();
      return cubit;
    }

    testWidgets('shows the play next card near the top when enabled', (
      tester,
    ) async {
      final cubit = await aiCubit(kStatusConsented);
      addTearDown(cubit.close);
      await tester.pumpWidget(buildSubject(aiStatus: cubit));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('What should I play tonight?'), findsOneWidget);
      expect(find.text('Discover with AI'), findsOneWidget);
    });

    testWidgets('hides the AI card when AI is disabled', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final cubit = await aiCubit(kStatusDisabled);
      addTearDown(cubit.close);
      await tester.pumpWidget(buildSubject(aiStatus: cubit));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('What should I play tonight?'), findsNothing);
      expect(find.text('Discover with AI'), findsNothing);
      expect(find.widgetWithText(SectionHeader, 'Most anticipated'), findsOne);
    });
  });
}
