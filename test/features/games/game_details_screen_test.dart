import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/features/games/bloc/game_details_bloc.dart';
import 'package:picklog/features/games/bloc/game_details_state.dart';
import 'package:picklog/features/games/game_detail_model.dart';
import 'package:picklog/features/games/game_details_screen.dart';
import 'package:picklog/features/games/widgets/skeletons/game_details_skeleton.dart';
import 'package:picklog/features/library/bloc/library_bloc.dart';
import 'package:picklog/features/library/bloc/library_state.dart';
import 'package:picklog/features/library/library_entry_model.dart';
import 'package:picklog/l10n/app_localizations.dart';

import '../../mocks/mock_blocs.dart';

const _game = GameDetail(
  id: 42,
  name: 'Hollow Knight',
  summary: 'A challenging Metroidvania.',
  screenshots: [],
  videos: [],
  genres: [Genre(id: 1, name: 'Metroidvania')],
  platforms: [Platform(id: 6, name: 'PC')],
  involvedCompanies: [],
  websites: [],
  similarGames: [],
);

LibraryEntry _entry({GameStatus status = GameStatus.playing}) {
  final now = DateTime(2024, 1, 1);
  return LibraryEntry(
    id: 'entry-1',
    userId: 'user-1',
    game: CachedGame(
      id: 'game-1',
      igdbId: 42,
      name: 'Hollow Knight',
      lastSyncedAt: now,
    ),
    status: status,
    isFavorite: false,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('GameDetailsScreen', () {
    late MockGameDetailsBloc detailsBloc;
    late MockLibraryBloc libraryBloc;

    setUp(() {
      detailsBloc = MockGameDetailsBloc();
      libraryBloc = MockLibraryBloc();
      when(() => libraryBloc.state).thenReturn(const LibraryState());
    });

    tearDown(() {
      detailsBloc.close();
      libraryBloc.close();
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
        locale: const Locale('en'),
        home: MultiBlocProvider(
          providers: [
            BlocProvider<GameDetailsBloc>.value(value: detailsBloc),
            BlocProvider<LibraryBloc>.value(value: libraryBloc),
          ],
          child: const GameDetailsScreen(gameId: 42),
        ),
      );
    }

    testWidgets('loading state renders the details skeleton', (tester) async {
      when(
        () => detailsBloc.state,
      ).thenReturn(const GameDetailsState(status: GameDetailsStatus.loading));

      await tester.pumpWidget(buildSubject());

      expect(find.byType(GameDetailsSkeleton), findsOneWidget);
    });

    testWidgets('failure state renders the error message and icon', (
      tester,
    ) async {
      when(() => detailsBloc.state).thenReturn(
        const GameDetailsState(
          status: GameDetailsStatus.failure,
          errorMessage: 'Boom',
        ),
      );

      await tester.pumpWidget(buildSubject());

      expect(find.text('Error loading data'), findsOneWidget);
      expect(find.text('Boom'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('success state renders the game name, genres and platforms', (
      tester,
    ) async {
      when(() => detailsBloc.state).thenReturn(
        const GameDetailsState(status: GameDetailsStatus.success, game: _game),
      );

      await tester.pumpWidget(buildSubject());

      expect(find.text('Hollow Knight'), findsOneWidget);
      expect(find.text('Metroidvania'), findsOneWidget);
      expect(find.text('PC'), findsOneWidget);
    });

    testWidgets('FAB shows the add label when the game is not in the library', (
      tester,
    ) async {
      when(() => detailsBloc.state).thenReturn(
        const GameDetailsState(status: GameDetailsStatus.success, game: _game),
      );
      when(() => libraryBloc.state).thenReturn(const LibraryState());

      await tester.pumpWidget(buildSubject());

      expect(find.widgetWithText(FloatingActionButton, 'Add'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('FAB shows the status label and edit icon when the game is in '
        'the library', (tester) async {
      when(() => detailsBloc.state).thenReturn(
        const GameDetailsState(status: GameDetailsStatus.success, game: _game),
      );
      when(() => libraryBloc.state).thenReturn(
        LibraryState(
          status: LibraryStatus.success,
          entries: [_entry(status: GameStatus.playing)],
        ),
      );

      await tester.pumpWidget(buildSubject());

      expect(
        find.widgetWithText(FloatingActionButton, 'Playing'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.edit), findsOneWidget);
      // The favorite action appears only for library entries.
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });

    testWidgets('tapping the FAB opens the add-to-library bottom sheet', (
      tester,
    ) async {
      when(() => detailsBloc.state).thenReturn(
        const GameDetailsState(status: GameDetailsStatus.success, game: _game),
      );

      await tester.pumpWidget(buildSubject());

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // The sheet header confirms it opened.
      expect(find.text('Add to Library'), findsOneWidget);
    });
  });
}
