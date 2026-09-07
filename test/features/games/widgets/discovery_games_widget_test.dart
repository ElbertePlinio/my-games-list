import 'package:bloc_test/bloc_test.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/core/widgets/shimmer_loading.dart';
import 'package:picklog/features/games/discovery_game_model.dart';
import 'package:picklog/features/games/bloc/discovery_games_bloc.dart';
import 'package:picklog/features/games/bloc/discovery_games_event.dart';
import 'package:picklog/features/games/bloc/discovery_games_state.dart';
import 'package:picklog/features/games/widgets/discovery_game_tile.dart';
import 'package:picklog/features/games/widgets/discovery_games_widget.dart';
import 'package:picklog/l10n/app_localizations.dart';
import 'package:visibility_detector/visibility_detector.dart';

class MockDiscoveryGamesBloc
    extends MockBloc<DiscoveryGamesEvent, DiscoveryGamesState>
    implements DiscoveryGamesBloc {}

/// Builds a [DiscoveryGamesState] holding state for a single discovery type
/// via the per-type API, matching how the widget reads `getStateForType`.
DiscoveryGamesState stateForType(
  DiscoveryType type, {
  DiscoveryGamesStatus status = DiscoveryGamesStatus.initial,
  List<DiscoveryGame> games = const [],
  String? errorMessage,
}) {
  return DiscoveryGamesState(
    stateByType: {
      type: DiscoveryTypeState(
        status: status,
        games: games,
        errorMessage: errorMessage,
      ),
    },
    activeDiscoveryType: type,
  );
}

void main() {
  group('DiscoveryGameTile', () {
    const mockGame = DiscoveryGame(
      id: 1942,
      name: 'The Witcher 3: Wild Hunt',
      coverUrl:
          'https://images.igdb.com/igdb/image/upload/t_cover_big/coaarl.jpg',
      totalRating: 92.82,
    );

    const mockGameNoRating = DiscoveryGame(
      id: 1,
      name: 'Test Game',
      coverUrl: 'https://example.com/cover.jpg',
    );

    const mockGameNoCover = DiscoveryGame(
      id: 2,
      name: 'No Cover Game',
      totalRating: 80.0,
    );

    Widget createTile({required DiscoveryGame game}) {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 140,
            height: 200,
            child: DiscoveryGameTile(game: game),
          ),
        ),
      );
    }

    testWidgets('should display game name', (tester) async {
      await tester.pumpWidget(createTile(game: mockGame));
      await tester.pump();

      expect(find.text('The Witcher 3: Wild Hunt'), findsOneWidget);
    });

    testWidgets('should display rating badge when rating exists', (
      tester,
    ) async {
      await tester.pumpWidget(createTile(game: mockGame));
      await tester.pump();

      expect(find.text('93%'), findsOneWidget);
    });

    testWidgets('should not display rating badge when rating is null', (
      tester,
    ) async {
      await tester.pumpWidget(createTile(game: mockGameNoRating));
      await tester.pump();

      // No rating badge should be shown at all
      expect(find.textContaining('%'), findsNothing);
    });

    testWidgets('should display cover image when cover URL exists', (
      tester,
    ) async {
      await tester.pumpWidget(createTile(game: mockGame));
      await tester.pump();

      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });

    testWidgets('should display placeholder when no cover URL', (tester) async {
      await tester.pumpWidget(createTile(game: mockGameNoCover));
      await tester.pump();

      // Should show the game-art placeholder glyph
      expect(find.byIcon(Icons.videogame_asset), findsOneWidget);
    });

    testWidgets('should be tappable with a hover/focus affordance', (
      tester,
    ) async {
      await tester.pumpWidget(createTile(game: mockGame));
      await tester.pump();

      // The tap target is an InkWell so web users get hover + focus highlights.
      final inkWell = tester.widget<InkWell>(find.byType(InkWell));
      expect(inkWell.onTap, isNotNull);
      expect(inkWell.mouseCursor, SystemMouseCursors.click);
    });
  });

  group('DiscoveryGameListTile', () {
    const mockGame = DiscoveryGame(
      id: 1942,
      name: 'The Witcher 3: Wild Hunt',
      coverUrl:
          'https://images.igdb.com/igdb/image/upload/t_cover_big/coaarl.jpg',
      totalRating: 92.82,
    );

    Widget createListTile({required DiscoveryGame game}) {
      return MaterialApp(
        home: Scaffold(body: DiscoveryGameListTile(game: game)),
      );
    }

    testWidgets('should display game name', (tester) async {
      await tester.pumpWidget(createListTile(game: mockGame));
      await tester.pump();

      expect(find.text('The Witcher 3: Wild Hunt'), findsOneWidget);
    });

    testWidgets('should display rating badge', (tester) async {
      await tester.pumpWidget(createListTile(game: mockGame));
      await tester.pump();

      expect(find.text('93%'), findsOneWidget);
    });

    testWidgets('should display cover image', (tester) async {
      await tester.pumpWidget(createListTile(game: mockGame));
      await tester.pump();

      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });
  });

  group('DiscoveryGamesWidget', () {
    late MockDiscoveryGamesBloc mockBloc;

    final mockGames = [
      const DiscoveryGame(
        id: 1942,
        name: 'The Witcher 3',
        coverUrl: 'https://example.com/cover1.jpg',
        totalRating: 92.82,
      ),
      const DiscoveryGame(
        id: 12345,
        name: 'Another Game',
        coverUrl: 'https://example.com/cover2.jpg',
        totalRating: 85.0,
      ),
    ];

    setUp(() {
      mockBloc = MockDiscoveryGamesBloc();
    });

    Widget createWidget({
      required DiscoveryGamesState state,
      DiscoveryType discoveryType = DiscoveryType.trending,
    }) {
      when(() => mockBloc.state).thenReturn(state);

      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<DiscoveryGamesBloc>.value(
            value: mockBloc,
            child: DiscoveryGamesWidget(discoveryType: discoveryType),
          ),
        ),
      );
    }

    testWidgets('should display title based on discovery type', (tester) async {
      when(() => mockBloc.stream).thenAnswer(
        (_) => Stream.value(
          stateForType(
            DiscoveryType.trending,
            status: DiscoveryGamesStatus.success,
            games: mockGames,
          ),
        ),
      );

      await tester.pumpWidget(
        createWidget(
          state: stateForType(
            DiscoveryType.trending,
            status: DiscoveryGamesStatus.success,
            games: mockGames,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Trending Now'), findsOneWidget);
    });

    testWidgets('should display loading indicator when loading', (
      tester,
    ) async {
      when(() => mockBloc.stream).thenAnswer(
        (_) => Stream.value(
          stateForType(
            DiscoveryType.trending,
            status: DiscoveryGamesStatus.loading,
          ),
        ),
      );

      await tester.pumpWidget(
        createWidget(
          state: stateForType(
            DiscoveryType.trending,
            status: DiscoveryGamesStatus.loading,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ShimmerLoading), findsWidgets);
    });

    testWidgets('should display error message on failure', (tester) async {
      const errorMessage = 'Failed to load games';
      when(() => mockBloc.stream).thenAnswer(
        (_) => Stream.value(
          stateForType(
            DiscoveryType.trending,
            status: DiscoveryGamesStatus.failure,
            errorMessage: errorMessage,
          ),
        ),
      );

      await tester.pumpWidget(
        createWidget(
          state: stateForType(
            DiscoveryType.trending,
            status: DiscoveryGamesStatus.failure,
            errorMessage: errorMessage,
          ),
        ),
      );
      await tester.pump();

      expect(find.text(errorMessage), findsOneWidget);
    });

    testWidgets('should display games when loaded', (tester) async {
      when(() => mockBloc.stream).thenAnswer(
        (_) => Stream.value(
          stateForType(
            DiscoveryType.trending,
            status: DiscoveryGamesStatus.success,
            games: mockGames,
          ),
        ),
      );

      await tester.pumpWidget(
        createWidget(
          state: stateForType(
            DiscoveryType.trending,
            status: DiscoveryGamesStatus.success,
            games: mockGames,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('The Witcher 3'), findsOneWidget);
      expect(find.text('Another Game'), findsOneWidget);
    });

    testWidgets('should display See All button', (tester) async {
      when(() => mockBloc.stream).thenAnswer(
        (_) => Stream.value(
          stateForType(
            DiscoveryType.trending,
            status: DiscoveryGamesStatus.success,
            games: mockGames,
          ),
        ),
      );

      await tester.pumpWidget(
        createWidget(
          state: stateForType(
            DiscoveryType.trending,
            status: DiscoveryGamesStatus.success,
            games: mockGames,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('See All'), findsOneWidget);
    });

    testWidgets('should display localized title for indie type', (
      tester,
    ) async {
      when(() => mockBloc.stream).thenAnswer(
        (_) => Stream.value(
          stateForType(
            DiscoveryType.indie,
            status: DiscoveryGamesStatus.success,
            games: mockGames,
          ),
        ),
      );

      await tester.pumpWidget(
        createWidget(
          state: stateForType(
            DiscoveryType.indie,
            status: DiscoveryGamesStatus.success,
            games: mockGames,
          ),
          discoveryType: DiscoveryType.indie,
        ),
      );
      await tester.pump();

      // Should display "Indie Gems" (localized title)
      expect(find.text('Indie Gems'), findsOneWidget);
    });
  });

  group('LazyDiscoveryGamesWidget', () {
    late MockDiscoveryGamesBloc mockBloc;

    final mockGames = [
      const DiscoveryGame(
        id: 1942,
        name: 'Indie Game 1',
        coverUrl: 'https://example.com/cover1.jpg',
        totalRating: 92.82,
      ),
      const DiscoveryGame(
        id: 12345,
        name: 'Indie Game 2',
        coverUrl: 'https://example.com/cover2.jpg',
        totalRating: 85.0,
      ),
    ];

    setUp(() {
      mockBloc = MockDiscoveryGamesBloc();
      // Set update interval to zero for immediate updates in tests
      VisibilityDetectorController.instance.updateInterval = Duration.zero;
    });

    tearDown(() {
      // Reset to default after tests
      VisibilityDetectorController.instance.updateInterval = const Duration(
        milliseconds: 500,
      );
    });

    Widget createLazyWidget({
      required DiscoveryGamesState state,
      DiscoveryType discoveryType = DiscoveryType.indie,
      String heroTagPrefix = '',
    }) {
      when(() => mockBloc.state).thenReturn(state);

      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<DiscoveryGamesBloc>.value(
            value: mockBloc,
            child: LazyDiscoveryGamesWidget(
              discoveryType: discoveryType,
              heroTagPrefix: heroTagPrefix,
            ),
          ),
        ),
      );
    }

    testWidgets('should display loading state initially', (tester) async {
      when(() => mockBloc.stream).thenAnswer(
        (_) => Stream.value(
          stateForType(
            DiscoveryType.indie,
            status: DiscoveryGamesStatus.loading,
          ),
        ),
      );

      await tester.pumpWidget(
        createLazyWidget(
          state: stateForType(
            DiscoveryType.indie,
            status: DiscoveryGamesStatus.loading,
          ),
          discoveryType: DiscoveryType.indie,
        ),
      );
      // Allow the widget to build
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Loading state shows the title with loading placeholder
      expect(find.text('Indie Gems'), findsOneWidget);
      expect(find.byType(ShimmerLoading), findsWidgets);
    });

    testWidgets('should display Indie Gems title for indie type', (
      tester,
    ) async {
      when(() => mockBloc.stream).thenAnswer(
        (_) => Stream.value(
          stateForType(
            DiscoveryType.indie,
            status: DiscoveryGamesStatus.success,
            games: mockGames,
          ),
        ),
      );

      await tester.pumpWidget(
        createLazyWidget(
          state: stateForType(
            DiscoveryType.indie,
            status: DiscoveryGamesStatus.success,
            games: mockGames,
          ),
          discoveryType: DiscoveryType.indie,
        ),
      );
      await tester.pump();

      expect(find.text('Indie Gems'), findsOneWidget);
    });

    testWidgets('should trigger load when widget becomes visible', (
      tester,
    ) async {
      when(() => mockBloc.stream).thenAnswer(
        (_) => Stream.value(
          stateForType(
            DiscoveryType.indie,
            status: DiscoveryGamesStatus.initial,
          ),
        ),
      );

      await tester.pumpWidget(
        createLazyWidget(
          state: stateForType(
            DiscoveryType.indie,
            status: DiscoveryGamesStatus.initial,
          ),
          discoveryType: DiscoveryType.indie,
        ),
      );

      // Pump to trigger visibility callback
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify that the load event was triggered
      verify(
        () => mockBloc.add(
          const DiscoveryGamesLoadRequested(DiscoveryType.indie),
        ),
      ).called(1);
    });

    testWidgets('should display games when loaded', (tester) async {
      final stateWithGames = stateForType(
        DiscoveryType.indie,
        status: DiscoveryGamesStatus.success,
        games: mockGames,
      );

      when(
        () => mockBloc.stream,
      ).thenAnswer((_) => Stream.value(stateWithGames));

      await tester.pumpWidget(
        createLazyWidget(
          state: stateWithGames,
          discoveryType: DiscoveryType.indie,
        ),
      );

      // Pump to trigger visibility callback (same as trigger load test)
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Indie Gems'), findsOneWidget);
      expect(find.text('Indie Game 1'), findsOneWidget);
      expect(find.text('Indie Game 2'), findsOneWidget);
    });

    testWidgets('uses an unchanged detector key for the Home surface', (
      tester,
    ) async {
      when(() => mockBloc.stream).thenAnswer(
        (_) => Stream.value(
          stateForType(
            DiscoveryType.newReleases,
            status: DiscoveryGamesStatus.initial,
          ),
        ),
      );

      await tester.pumpWidget(
        createLazyWidget(
          state: stateForType(
            DiscoveryType.newReleases,
            status: DiscoveryGamesStatus.initial,
          ),
          discoveryType: DiscoveryType.newReleases,
        ),
      );
      await tester.pump();

      final detector = tester.widget<VisibilityDetector>(
        find.byType(VisibilityDetector),
      );
      expect(detector.key, const Key('lazy_discovery_new_releases'));
    });

    testWidgets(
      'derives distinct detector keys per surface so callbacks are not '
      'coalesced',
      (tester) async {
        when(() => mockBloc.stream).thenAnswer(
          (_) => Stream.value(
            stateForType(
              DiscoveryType.newReleases,
              status: DiscoveryGamesStatus.initial,
            ),
          ),
        );

        await tester.pumpWidget(
          createLazyWidget(
            state: stateForType(
              DiscoveryType.newReleases,
              status: DiscoveryGamesStatus.initial,
            ),
            discoveryType: DiscoveryType.newReleases,
            heroTagPrefix: 'browse-new-releases-',
          ),
        );
        await tester.pump();

        final detector = tester.widget<VisibilityDetector>(
          find.byType(VisibilityDetector),
        );
        expect(
          detector.key,
          const Key('lazy_discovery_browse-new-releases-new_releases'),
        );
        expect(detector.key, isNot(const Key('lazy_discovery_new_releases')));
      },
    );
  });
}
