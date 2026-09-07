import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/core/theme/app_theme.dart';
import 'package:picklog/features/games/bloc/discovery_games_bloc.dart';
import 'package:picklog/features/games/bloc/discovery_games_event.dart';
import 'package:picklog/features/games/bloc/discovery_games_state.dart';
import 'package:picklog/features/games/discovery_game_model.dart';
import 'package:picklog/features/games/search_game_model.dart';
import 'package:picklog/features/games/widgets/discovery_game_tile.dart';
import 'package:picklog/features/games/widgets/discovery_games_widget.dart';
import 'package:picklog/features/games/widgets/game_search_card.dart';
import 'package:picklog/l10n/app_localizations.dart';

class _MockDiscoveryGamesBloc
    extends MockBloc<DiscoveryGamesEvent, DiscoveryGamesState>
    implements DiscoveryGamesBloc {}

/// Uses the real branded [AppTheme] so goldens stay pinned to the app's actual
/// visual output rather than test defaults.
ThemeData _theme(Brightness brightness) =>
    brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light();

/// Wraps [child] in a deterministic shell: fixed size, devicePixelRatio and
/// text scale, localization delegates, and a router so `pushNamed` tap targets
/// resolve. Goldens depend only on the widget, never on the host environment.
Widget _host({
  required Widget child,
  required Size size,
  Brightness brightness = Brightness.light,
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => child),
      GoRoute(
        path: '/games/:id',
        name: 'gameDetails',
        builder: (context, state) => const SizedBox.shrink(),
      ),
    ],
  );

  return MediaQuery(
    data: MediaQueryData(size: size),
    child: MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: _theme(brightness),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      routerConfig: router,
    ),
  );
}

DiscoveryGamesState _loadedState(
  DiscoveryType type,
  List<DiscoveryGame> games,
) {
  return DiscoveryGamesState(
    stateByType: {
      type: DiscoveryTypeState(
        status: DiscoveryGamesStatus.success,
        games: games,
      ),
    },
    activeDiscoveryType: type,
  );
}

void main() {
  // Cover-less fixtures keep goldens deterministic: the tiles render the
  // built-in icon placeholder instead of fetching a network image (which would
  // pull non-deterministic bytes and leave pending timers).
  const witcher = DiscoveryGame(
    id: 1942,
    name: 'The Witcher 3: Wild Hunt',
    totalRating: 92.0,
  );
  const elden = DiscoveryGame(id: 1, name: 'Elden Ring', totalRating: 60.0);
  const indie = DiscoveryGame(id: 2, name: 'Hollow Knight', totalRating: 40.0);
  const noRating = DiscoveryGame(id: 3, name: 'Unrated Game');

  group('DiscoveryGameTile goldens', () {
    testWidgets('compact tile with high rating', (tester) async {
      await tester.pumpWidget(
        _host(
          size: const Size(160, 220),
          child: const Scaffold(
            body: Center(
              child: SizedBox(
                width: 140,
                height: 200,
                child: DiscoveryGameTile(game: witcher, isCompact: true),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await expectLater(
        find.byType(DiscoveryGameTile),
        matchesGoldenFile('goldens/discovery_game_tile_compact.png'),
      );
    });

    testWidgets('tile without a rating badge', (tester) async {
      await tester.pumpWidget(
        _host(
          size: const Size(160, 220),
          child: const Scaffold(
            body: Center(
              child: SizedBox(
                width: 140,
                height: 200,
                child: DiscoveryGameTile(game: noRating, isCompact: true),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await expectLater(
        find.byType(DiscoveryGameTile),
        matchesGoldenFile('goldens/discovery_game_tile_no_rating.png'),
      );
    });

    testWidgets('list tile variant', (tester) async {
      await tester.pumpWidget(
        _host(
          size: const Size(400, 140),
          child: const Scaffold(
            body: Center(child: DiscoveryGameListTile(game: witcher)),
          ),
        ),
      );
      await tester.pump();

      await expectLater(
        find.byType(DiscoveryGameListTile),
        matchesGoldenFile('goldens/discovery_game_list_tile.png'),
      );
    });
  });

  group('DiscoveryGamesWidget golden', () {
    testWidgets('loaded trending carousel', (tester) async {
      final bloc = _MockDiscoveryGamesBloc();
      final state = _loadedState(DiscoveryType.trending, const [
        witcher,
        elden,
        indie,
      ]);
      when(() => bloc.state).thenReturn(state);
      whenListen(
        bloc,
        const Stream<DiscoveryGamesState>.empty(),
        initialState: state,
      );

      await tester.pumpWidget(
        _host(
          size: const Size(400, 320),
          child: Scaffold(
            body: BlocProvider<DiscoveryGamesBloc>.value(
              value: bloc,
              child: const DiscoveryGamesWidget(
                discoveryType: DiscoveryType.trending,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await expectLater(
        find.byType(DiscoveryGamesWidget),
        matchesGoldenFile('goldens/discovery_carousel_trending.png'),
      );
    });
  });

  group('GameSearchCard golden', () {
    testWidgets('search card with metadata', (tester) async {
      final game = SearchGame(
        id: 1942,
        name: 'The Witcher 3: Wild Hunt',
        firstReleaseDate: DateTime(2015, 5, 19),
        genres: const [
          GameGenre(id: 12, name: 'RPG'),
          GameGenre(id: 31, name: 'Adventure'),
        ],
        platforms: const [
          GamePlatform(id: 6, name: 'PC'),
          GamePlatform(id: 167, name: 'PlayStation 5'),
        ],
      );

      await tester.pumpWidget(
        _host(
          size: const Size(400, 180),
          child: Scaffold(body: GameSearchCard(game: game)),
        ),
      );
      await tester.pump();

      await expectLater(
        find.byType(GameSearchCard),
        matchesGoldenFile('goldens/game_search_card.png'),
      );
    });
  });
}
