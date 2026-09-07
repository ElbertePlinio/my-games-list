import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:picklog/core/utils/app_router.dart';
import 'package:picklog/features/games/bloc/discovery_games_bloc.dart';
import 'package:picklog/features/games/bloc/discovery_games_event.dart';
import 'package:picklog/features/games/bloc/discovery_games_state.dart';
import 'package:picklog/features/games/discovery_game_model.dart';
import 'package:picklog/features/games/widgets/discovery_game_tile.dart';
import 'package:picklog/features/games/widgets/discovery_games_widget.dart';
import 'package:picklog/l10n/app_localizations.dart';

class _MockDiscoveryGamesBloc
    extends MockBloc<DiscoveryGamesEvent, DiscoveryGamesState>
    implements DiscoveryGamesBloc {}

void main() {
  // Cover-less fixtures avoid network image fetches, keeping the flow free of
  // pending timers and non-deterministic image decoding.
  const games = [
    DiscoveryGame(id: 1942, name: 'The Witcher 3', totalRating: 92.0),
    DiscoveryGame(id: 7, name: 'Stardew Valley', totalRating: 88.0),
  ];

  DiscoveryGamesState loaded() => const DiscoveryGamesState(
    stateByType: {
      DiscoveryType.trending: DiscoveryTypeState(
        status: DiscoveryGamesStatus.success,
        games: games,
      ),
    },
    activeDiscoveryType: DiscoveryType.trending,
  );

  testWidgets(
    'discovery carousel loads, tapping a tile routes to game details',
    (tester) async {
      final bloc = _MockDiscoveryGamesBloc();
      whenListen(
        bloc,
        const Stream<DiscoveryGamesState>.empty(),
        initialState: loaded(),
      );

      var detailsId = '';
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: BlocProvider<DiscoveryGamesBloc>.value(
                value: bloc,
                child: const DiscoveryGamesWidget(
                  discoveryType: DiscoveryType.trending,
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/games/:id',
            name: AppRouter.gameDetailsName,
            builder: (context, state) {
              detailsId = state.pathParameters['id'] ?? '';
              return Scaffold(body: Text('details $detailsId'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
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
      await tester.pump();

      // Carousel rendered both games.
      expect(find.text('The Witcher 3'), findsOneWidget);
      expect(find.text('Stardew Valley'), findsOneWidget);

      // Tap the first tile's own InkWell (the carousel header has a separate
      // "See All" InkWell, so we scope the finder to the tile and target its
      // transparent overlay InkWell rather than the text behind it).
      final firstTile = find.byType(DiscoveryGameTile).first;
      await tester.tap(
        find.descendant(of: firstTile, matching: find.byType(InkWell)),
      );
      await tester.pumpAndSettle();

      expect(find.text('details 1942'), findsOneWidget);
    },
  );
}
