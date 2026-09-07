import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/core/services/connectivity_cubit.dart';
import 'package:picklog/core/widgets/skeleton_box.dart';
import 'package:picklog/core/widgets/visibility_hero.dart';
import 'package:picklog/features/browse/bloc/browse_genres_bloc.dart';
import 'package:picklog/features/browse/bloc/browse_genres_event.dart';
import 'package:picklog/features/browse/bloc/browse_genres_state.dart';
import 'package:picklog/features/browse/browse_screen.dart';
import 'package:picklog/features/games/bloc/collections_bloc.dart';
import 'package:picklog/features/games/bloc/collections_event.dart';
import 'package:picklog/features/games/bloc/collections_state.dart';
import 'package:picklog/features/games/bloc/discovery_games_bloc.dart';
import 'package:picklog/features/games/bloc/discovery_games_event.dart';
import 'package:picklog/features/games/bloc/discovery_games_state.dart';
import 'package:picklog/features/games/collection_model.dart';
import 'package:picklog/features/games/discovery_game_model.dart';
import 'package:picklog/features/games/game_detail_model.dart';
import 'package:picklog/features/games/widgets/collections_widget.dart';
import 'package:picklog/features/games/widgets/skeletons/discovery_tile_skeleton.dart';
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

class MockConnectivityCubit extends MockCubit<bool>
    implements ConnectivityCubit {}

/// A discovery state holding the same games for both release rows so the
/// Browse releases section renders content for newReleases + comingSoon.
DiscoveryGamesState releasesState({
  DiscoveryGamesStatus status = DiscoveryGamesStatus.success,
  List<DiscoveryGame> games = const [],
}) {
  return DiscoveryGamesState(
    stateByType: {
      DiscoveryType.newReleases: DiscoveryTypeState(
        status: status,
        games: games,
      ),
      DiscoveryType.comingSoon: DiscoveryTypeState(
        status: status,
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
  late MockConnectivityCubit connectivity;

  const genres = [Genre(id: 1, name: 'Action'), Genre(id: 2, name: 'RPG')];

  final releaseGames = [
    const DiscoveryGame(
      id: 100,
      name: 'Fresh Drop',
      coverUrl: 'https://example.com/100.jpg',
    ),
    const DiscoveryGame(
      id: 101,
      name: 'Future Hit',
      coverUrl: 'https://example.com/101.jpg',
    ),
  ];

  final collections = [
    const GameCollection(
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

  setUp(() {
    genresBloc = MockBrowseGenresBloc();
    discoveryBloc = MockDiscoveryGamesBloc();
    collectionsBloc = MockCollectionsBloc();
    connectivity = MockConnectivityCubit();
    when(() => connectivity.state).thenReturn(true);
    // Fire visibility callbacks synchronously so the lazy release rows render.
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  tearDown(() {
    VisibilityDetectorController.instance.updateInterval = const Duration(
      milliseconds: 500,
    );
  });

  Widget buildSubject() {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: MultiBlocProvider(
        providers: [
          BlocProvider<BrowseGenresBloc>.value(value: genresBloc),
          BlocProvider<DiscoveryGamesBloc>.value(value: discoveryBloc),
          BlocProvider<CollectionsBloc>.value(value: collectionsBloc),
          BlocProvider<ConnectivityCubit>.value(value: connectivity),
        ],
        child: const BrowseScreen(),
      ),
    );
  }

  testWidgets('renders only the Genres group header; rows self-label', (
    tester,
  ) async {
    when(() => genresBloc.state).thenReturn(
      const BrowseGenresState(
        status: BrowseGenresStatus.success,
        genres: genres,
      ),
    );
    when(() => discoveryBloc.state).thenReturn(releasesState());
    when(() => collectionsBloc.state).thenReturn(const CollectionsState());

    await tester.pumpWidget(buildSubject());
    await tester.pump();

    // The Genres section keeps its group header (its body is a header-less
    // grid). The Releases/Collections group headers are dropped — those rows
    // self-label — so the standalone "Releases"/"Collections" labels are gone.
    expect(find.text('Genres'), findsOneWidget);
    expect(find.text('Releases'), findsNothing);
    expect(find.text('Collections'), findsNothing);
  });

  testWidgets('shows genre cards when genres load', (tester) async {
    when(() => genresBloc.state).thenReturn(
      const BrowseGenresState(
        status: BrowseGenresStatus.success,
        genres: genres,
      ),
    );
    when(() => discoveryBloc.state).thenReturn(releasesState());
    when(() => collectionsBloc.state).thenReturn(const CollectionsState());

    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.text('Action'), findsOneWidget);
    expect(find.text('RPG'), findsOneWidget);
  });

  testWidgets('shows a genres skeleton (not a spinner) while genres load', (
    tester,
  ) async {
    when(
      () => genresBloc.state,
    ).thenReturn(const BrowseGenresState(status: BrowseGenresStatus.loading));
    when(() => discoveryBloc.state).thenReturn(releasesState());
    when(() => collectionsBloc.state).thenReturn(const CollectionsState());

    await tester.pumpWidget(buildSubject());
    await tester.pump();

    // First-load uses shimmer skeleton boxes for the genre grid, matching the
    // rest of the app — never a raw CircularProgressIndicator.
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(SkeletonBox), findsWidgets);
  });

  testWidgets('shows genres error with retry on failure', (tester) async {
    when(
      () => genresBloc.state,
    ).thenReturn(const BrowseGenresState(status: BrowseGenresStatus.failure));
    when(() => discoveryBloc.state).thenReturn(releasesState());
    when(() => collectionsBloc.state).thenReturn(const CollectionsState());

    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(
      find.text("Couldn't load genres. Please try again."),
      findsOneWidget,
    );
  });

  testWidgets('renders release rows with games', (tester) async {
    when(() => genresBloc.state).thenReturn(
      const BrowseGenresState(
        status: BrowseGenresStatus.success,
        genres: genres,
      ),
    );
    when(
      () => discoveryBloc.state,
    ).thenReturn(releasesState(games: releaseGames));
    when(() => collectionsBloc.state).thenReturn(const CollectionsState());

    await tester.pumpWidget(buildSubject());
    // Pump so the lazy rows pick up visibility and render their content.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('New Releases'), findsOneWidget);
    expect(find.text('Coming Soon'), findsOneWidget);
    // The same game appears in both release rows; each row carries a distinct
    // Hero prefix so they don't collide with each other (both stay alive) nor
    // with the Home tab.
    final heroes = tester
        .widgetList<VisibilityHero>(find.byType(VisibilityHero))
        .map((h) => h.tag)
        .toList();
    expect(heroes, contains('browse-new-releases-game-cover-100'));
    expect(heroes, contains('browse-coming-soon-game-cover-100'));
  });

  testWidgets('shows discovery error in the releases section', (tester) async {
    when(() => genresBloc.state).thenReturn(
      const BrowseGenresState(
        status: BrowseGenresStatus.success,
        genres: genres,
      ),
    );
    when(
      () => discoveryBloc.state,
    ).thenReturn(releasesState(status: DiscoveryGamesStatus.failure));
    when(() => collectionsBloc.state).thenReturn(const CollectionsState());

    await tester.pumpWidget(buildSubject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Failed to load games'), findsWidgets);
  });

  testWidgets('renders collection rows with a browse-namespaced Hero', (
    tester,
  ) async {
    when(() => genresBloc.state).thenReturn(
      const BrowseGenresState(
        status: BrowseGenresStatus.success,
        genres: genres,
      ),
    );
    when(() => discoveryBloc.state).thenReturn(releasesState());
    when(() => collectionsBloc.state).thenReturn(
      CollectionsState(
        status: CollectionsStatus.success,
        collections: collections,
      ),
    );

    await tester.pumpWidget(buildSubject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Cozy Games'), findsOneWidget);
    final heroes = tester
        .widgetList<VisibilityHero>(find.byType(VisibilityHero))
        .map((h) => h.tag)
        .toList();
    expect(heroes, contains('browse-col-coz-game-cover-200'));
  });

  testWidgets('shows a skeleton row while the releases load', (tester) async {
    when(() => genresBloc.state).thenReturn(
      const BrowseGenresState(
        status: BrowseGenresStatus.success,
        genres: genres,
      ),
    );
    when(
      () => discoveryBloc.state,
    ).thenReturn(releasesState(status: DiscoveryGamesStatus.loading));
    when(() => collectionsBloc.state).thenReturn(const CollectionsState());

    await tester.pumpWidget(buildSubject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Each loading release row shimmers a skeleton row; the titles still show.
    expect(find.text('New Releases'), findsOneWidget);
    expect(find.text('Coming Soon'), findsOneWidget);
    expect(find.byType(DiscoveryRowSkeleton), findsWidgets);
  });

  testWidgets('shimmers a skeleton row while collections load', (tester) async {
    when(() => genresBloc.state).thenReturn(
      const BrowseGenresState(
        status: BrowseGenresStatus.success,
        genres: genres,
      ),
    );
    when(() => discoveryBloc.state).thenReturn(releasesState());
    when(
      () => collectionsBloc.state,
    ).thenReturn(const CollectionsState(status: CollectionsStatus.loading));

    await tester.pumpWidget(buildSubject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // The collections block shimmers a single row while its first load is in
    // flight (it has no group header to orphan when it later collapses).
    expect(find.byType(DiscoveryRowSkeleton), findsWidgets);
    expect(find.text('Collections'), findsNothing);
  });

  testWidgets('collapses the collections block on failure', (tester) async {
    when(() => genresBloc.state).thenReturn(
      const BrowseGenresState(
        status: BrowseGenresStatus.success,
        genres: genres,
      ),
    );
    when(() => discoveryBloc.state).thenReturn(releasesState());
    when(
      () => collectionsBloc.state,
    ).thenReturn(const CollectionsState(status: CollectionsStatus.failure));

    await tester.pumpWidget(buildSubject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Editorial content hides on error rather than showing an empty placeholder;
    // with the group header dropped there is no dangling label/gap.
    expect(find.byType(CollectionsWidget), findsOneWidget);
    expect(find.text('Collections'), findsNothing);
    expect(find.byType(DiscoveryRowSkeleton), findsNothing);
  });

  testWidgets('collapses the collections block when empty', (tester) async {
    when(() => genresBloc.state).thenReturn(
      const BrowseGenresState(
        status: BrowseGenresStatus.success,
        genres: genres,
      ),
    );
    when(() => discoveryBloc.state).thenReturn(releasesState());
    when(
      () => collectionsBloc.state,
    ).thenReturn(const CollectionsState(status: CollectionsStatus.success));

    await tester.pumpWidget(buildSubject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(CollectionsWidget), findsOneWidget);
    expect(find.text('Collections'), findsNothing);
    expect(find.byType(DiscoveryRowSkeleton), findsNothing);
  });
}
