import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/core/services/connectivity_cubit.dart';
import 'package:picklog/core/utils/app_router.dart';
import 'package:picklog/core/widgets/visibility_hero.dart';
import 'package:picklog/features/browse/bloc/browse_genre_games_bloc.dart';
import 'package:picklog/features/browse/bloc/browse_genre_games_event.dart';
import 'package:picklog/features/browse/bloc/browse_genre_games_state.dart';
import 'package:picklog/features/browse/bloc/browse_genres_bloc.dart';
import 'package:picklog/features/browse/bloc/browse_genres_event.dart';
import 'package:picklog/features/browse/bloc/browse_genres_state.dart';
import 'package:picklog/features/browse/browse_genre_games_screen.dart';
import 'package:picklog/features/browse/browse_screen.dart';
import 'package:picklog/features/games/bloc/collections_bloc.dart';
import 'package:picklog/features/games/bloc/collections_event.dart';
import 'package:picklog/features/games/bloc/collections_state.dart';
import 'package:picklog/features/games/bloc/discovery_games_bloc.dart';
import 'package:picklog/features/games/bloc/discovery_games_event.dart';
import 'package:picklog/features/games/bloc/discovery_games_state.dart';
import 'package:picklog/features/games/collection_model.dart';
import 'package:picklog/features/games/discovery_game_model.dart';
import 'package:picklog/l10n/app_localizations.dart';
import 'package:visibility_detector/visibility_detector.dart';

class MockBrowseGenresBloc
    extends MockBloc<BrowseGenresEvent, BrowseGenresState>
    implements BrowseGenresBloc {}

class MockDiscoveryGamesBloc
    extends MockBloc<DiscoveryGamesEvent, DiscoveryGamesState>
    implements DiscoveryGamesBloc {}

class MockCollectionsBloc extends MockBloc<CollectionsEvent, CollectionsState>
    implements CollectionsBloc {}

class MockBrowseGenreGamesBloc
    extends MockBloc<BrowseGenreGamesEvent, BrowseGenreGamesState>
    implements BrowseGenreGamesBloc {}

class MockConnectivityCubit extends MockCubit<bool>
    implements ConnectivityCubit {}

/// A discovery state holding [games] under both release rows.
DiscoveryGamesState releasesState(List<DiscoveryGame> games) {
  return DiscoveryGamesState(
    stateByType: {
      DiscoveryType.newReleases: DiscoveryTypeState(
        status: DiscoveryGamesStatus.success,
        games: games,
      ),
      DiscoveryType.comingSoon: DiscoveryTypeState(
        status: DiscoveryGamesStatus.success,
        games: games,
      ),
    },
    activeDiscoveryType: DiscoveryType.newReleases,
  );
}

void main() {
  late MockBrowseGenresBloc genresBloc;
  late MockDiscoveryGamesBloc discoveryBloc;
  late MockCollectionsBloc collectionsBloc;
  late MockBrowseGenreGamesBloc genreGamesBloc;
  late MockConnectivityCubit connectivity;

  setUp(() {
    genresBloc = MockBrowseGenresBloc();
    discoveryBloc = MockDiscoveryGamesBloc();
    collectionsBloc = MockCollectionsBloc();
    genreGamesBloc = MockBrowseGenreGamesBloc();
    connectivity = MockConnectivityCubit();
    when(() => connectivity.state).thenReturn(true);
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  tearDown(() {
    VisibilityDetectorController.instance.updateInterval = const Duration(
      milliseconds: 500,
    );
  });

  /// Captured at the destination: the prefix delivered via GoRouter `extra` and
  /// the Hero tag the destination cover rebuilds from it — exactly mirroring
  /// `GameDetailsScreen`'s `'${heroTagPrefix}game-cover-$gameId'`.
  late String destinationHeroTag;

  /// Builds a router whose `gameDetails` destination reads `state.extra` (the
  /// hero prefix forwarded by the source tile) and renders the production Hero
  /// tag. A prefix mismatch wouldn't throw — it would silently break the shared
  /// element — so the test asserts the destination tag equals the source tag.
  GoRouter routerWithSource(Widget source) {
    destinationHeroTag = '';
    return GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => source),
        GoRoute(
          path: '/games/:id',
          name: AppRouter.gameDetailsName,
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            final prefix = state.extra is String ? state.extra! as String : '';
            destinationHeroTag = '${prefix}game-cover-$id';
            return Scaffold(
              body: Hero(tag: destinationHeroTag, child: const SizedBox()),
            );
          },
        ),
      ],
    );
  }

  Widget pumpRouter(GoRouter router) {
    return MaterialApp.router(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }

  /// Asserts exactly one source cover Hero carries [tag] (so the tap below is
  /// unambiguous) before navigating.
  void expectSingleSourceHero(WidgetTester tester, String tag) {
    final heroes = tester
        .widgetList<VisibilityHero>(find.byType(VisibilityHero))
        .map((h) => h.tag.toString())
        .where((t) => t == tag)
        .toList();
    expect(heroes, hasLength(1), reason: 'expected one source Hero for $tag');
  }

  /// Taps the tile whose source cover Hero carries [tag]. The tile's
  /// whole-surface tap target is the InkWell stacked over that VisibilityHero,
  /// so navigate via the InkWell nearest the matching Hero. Scrolls it into
  /// view first since lower rows (e.g. Coming Soon) start below the fold.
  Future<void> tapTileWithHero(WidgetTester tester, String tag) async {
    final inkWell = find
        .descendant(
          of: find.ancestor(
            of: find.byWidgetPredicate(
              (w) => w is VisibilityHero && w.tag == tag,
            ),
            matching: find.byType(Stack),
          ),
          matching: find.byType(InkWell),
        )
        .first;
    await tester.ensureVisible(inkWell);
    await tester.pumpAndSettle();
    await tester.tap(inkWell);
    await tester.pumpAndSettle();
  }

  Widget browseSource() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<BrowseGenresBloc>.value(value: genresBloc),
        BlocProvider<DiscoveryGamesBloc>.value(value: discoveryBloc),
        BlocProvider<CollectionsBloc>.value(value: collectionsBloc),
        BlocProvider<ConnectivityCubit>.value(value: connectivity),
      ],
      child: const BrowseScreen(),
    );
  }

  testWidgets('release tile destination Hero matches its source prefix', (
    tester,
  ) async {
    const game = DiscoveryGame(
      id: 100,
      name: 'Fresh Drop',
      coverUrl: 'https://example.com/100.jpg',
    );
    when(() => genresBloc.state).thenReturn(
      const BrowseGenresState(status: BrowseGenresStatus.success, genres: []),
    );
    when(() => discoveryBloc.state).thenReturn(releasesState(const [game]));
    when(() => collectionsBloc.state).thenReturn(const CollectionsState());

    await tester.pumpWidget(pumpRouter(routerWithSource(browseSource())));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // The New Releases row carries the browse-new-releases- prefix (the Coming
    // Soon row holds the same game under a distinct prefix — that's the fix).
    const tag = 'browse-new-releases-game-cover-100';
    expectSingleSourceHero(tester, tag);

    await tapTileWithHero(tester, tag);

    expect(destinationHeroTag, tag);
  });

  testWidgets('collection tile destination Hero matches its source prefix', (
    tester,
  ) async {
    const collections = [
      GameCollection(
        id: 'coz',
        slug: 'cozy',
        title: 'Cozy Games',
        games: [
          DiscoveryGame(
            id: 200,
            name: 'Stardew',
            coverUrl: 'https://example.com/200.jpg',
          ),
        ],
      ),
    ];
    when(() => genresBloc.state).thenReturn(
      const BrowseGenresState(status: BrowseGenresStatus.success, genres: []),
    );
    when(() => discoveryBloc.state).thenReturn(releasesState(const []));
    when(() => collectionsBloc.state).thenReturn(
      const CollectionsState(
        status: CollectionsStatus.success,
        collections: collections,
      ),
    );

    await tester.pumpWidget(pumpRouter(routerWithSource(browseSource())));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    const tag = 'browse-col-coz-game-cover-200';
    expectSingleSourceHero(tester, tag);

    await tapTileWithHero(tester, tag);

    expect(destinationHeroTag, tag);
  });

  testWidgets('genre tile destination Hero matches its source prefix', (
    tester,
  ) async {
    const game = DiscoveryGame(
      id: 300,
      name: 'Genre Pick',
      coverUrl: 'https://example.com/300.jpg',
    );
    when(() => genreGamesBloc.state).thenReturn(
      const BrowseGenreGamesState(
        status: BrowseGenreGamesStatus.success,
        games: [game],
      ),
    );

    final source = BlocProvider<BrowseGenreGamesBloc>.value(
      value: genreGamesBloc,
      child: const BrowseGenreGamesScreen(genreId: 7, genreName: 'Action'),
    );

    await tester.pumpWidget(pumpRouter(routerWithSource(source)));
    await tester.pumpAndSettle();

    // The genre games list carries the browse-genre-<id>- prefix.
    const tag = 'browse-genre-7-game-cover-300';
    expectSingleSourceHero(tester, tag);

    await tapTileWithHero(tester, tag);

    expect(destinationHeroTag, tag);
  });

  testWidgets('coming-soon tile uses a distinct prefix from new-releases', (
    tester,
  ) async {
    const game = DiscoveryGame(
      id: 100,
      name: 'Fresh Drop',
      coverUrl: 'https://example.com/100.jpg',
    );
    when(() => genresBloc.state).thenReturn(
      const BrowseGenresState(status: BrowseGenresStatus.success, genres: []),
    );
    when(() => discoveryBloc.state).thenReturn(releasesState(const [game]));
    when(() => collectionsBloc.state).thenReturn(const CollectionsState());

    await tester.pumpWidget(pumpRouter(routerWithSource(browseSource())));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Same game, same id as the new-releases test, but the Coming Soon row's
    // tile carries its own prefix — proving the two rows don't collide and
    // each routes to its own matching destination Hero.
    const tag = 'browse-coming-soon-game-cover-100';
    expectSingleSourceHero(tester, tag);

    await tapTileWithHero(tester, tag);

    expect(destinationHeroTag, tag);
  });
}
