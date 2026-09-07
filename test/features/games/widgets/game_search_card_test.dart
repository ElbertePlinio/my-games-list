import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:picklog/features/games/search_game_model.dart';
import 'package:picklog/features/games/widgets/game_search_card.dart';
import 'package:picklog/l10n/app_localizations.dart';

void main() {
  group('GameSearchCard', () {
    final gameWithEverything = SearchGame(
      id: 1942,
      name: 'The Witcher 3: Wild Hunt',
      coverUrl:
          'https://images.igdb.com/igdb/image/upload/t_cover_big/coaarl.jpg',
      firstReleaseDate: DateTime(2015, 5, 19),
      genres: const [
        GameGenre(id: 12, name: 'RPG'),
        GameGenre(id: 31, name: 'Adventure'),
        GameGenre(id: 5, name: 'Shooter'),
      ],
      platforms: const [
        GamePlatform(id: 6, name: 'PC'),
        GamePlatform(id: 167, name: 'PlayStation 5'),
        GamePlatform(id: 169, name: 'Xbox Series X|S'),
      ],
    );

    const gameMinimal = SearchGame(
      id: 7,
      name: 'No Cover Game',
      genres: [],
      platforms: [],
    );

    /// Pumps the card inside a GoRouter exposing a `gameDetails` route, so the
    /// card's `pushNamed('gameDetails')` tap target resolves during tests.
    Future<void> pumpCard(WidgetTester tester, SearchGame game) async {
      var pushedId = '';
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                Scaffold(body: GameSearchCard(game: game)),
          ),
          GoRoute(
            path: '/game/:id',
            name: 'gameDetails',
            builder: (context, state) {
              pushedId = state.pathParameters['id'] ?? '';
              return Scaffold(body: Text('details $pushedId'));
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
          routerConfig: router,
        ),
      );
      await tester.pump();
    }

    testWidgets('renders the game name', (tester) async {
      await pumpCard(tester, gameWithEverything);

      expect(find.text('The Witcher 3: Wild Hunt'), findsOneWidget);
    });

    testWidgets('shows at most the first two genres', (tester) async {
      await pumpCard(tester, gameWithEverything);

      expect(find.text('RPG, Adventure'), findsOneWidget);
      expect(find.textContaining('Shooter'), findsNothing);
    });

    testWidgets('shows at most the first two platforms', (tester) async {
      await pumpCard(tester, gameWithEverything);

      expect(find.text('PC, PlayStation 5'), findsOneWidget);
      expect(find.textContaining('Xbox'), findsNothing);
    });

    testWidgets('renders the cover image when a cover URL is present', (
      tester,
    ) async {
      await pumpCard(tester, gameWithEverything);

      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });

    testWidgets('renders a placeholder icon when there is no cover URL', (
      tester,
    ) async {
      await pumpCard(tester, gameMinimal);

      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(find.byIcon(Icons.videogame_asset), findsOneWidget);
    });

    testWidgets('omits genre and platform rows when both are empty', (
      tester,
    ) async {
      await pumpCard(tester, gameMinimal);

      expect(find.byIcon(Icons.category), findsNothing);
      expect(find.byIcon(Icons.devices), findsNothing);
      expect(find.byIcon(Icons.calendar_today), findsNothing);
    });

    testWidgets('shows the release date row when a date is present', (
      tester,
    ) async {
      await pumpCard(tester, gameWithEverything);

      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('tapping navigates to the game details route', (tester) async {
      await pumpCard(tester, gameWithEverything);

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(find.text('details 1942'), findsOneWidget);
    });

    testWidgets('exposes a rich semantics label folding in content', (
      tester,
    ) async {
      await pumpCard(tester, gameWithEverything);

      expect(
        find.bySemanticsLabel(
          'The Witcher 3: Wild Hunt. RPG, Adventure. PC, PlayStation 5. 2015',
        ),
        findsOneWidget,
      );
    });

    testWidgets('semantics label falls back to the name when sparse', (
      tester,
    ) async {
      await pumpCard(tester, gameMinimal);

      expect(find.bySemanticsLabel('No Cover Game'), findsOneWidget);
    });

    testWidgets('exposes a screen-reader tap action on the labelled node', (
      tester,
    ) async {
      await pumpCard(tester, gameWithEverything);

      final handle = tester.ensureSemantics();

      expect(
        tester.getSemantics(
          find.bySemanticsLabel(
            'The Witcher 3: Wild Hunt. RPG, Adventure. PC, PlayStation 5. 2015',
          ),
        ),
        containsSemantics(isButton: true, hasTapAction: true),
      );

      handle.dispose();
    });
  });
}
