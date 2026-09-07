import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/features/games/games_screen.dart';
import 'package:picklog/features/games/widgets/skeletons/library_entry_skeleton.dart';
import 'package:picklog/features/library/bloc/library_bloc.dart';
import 'package:picklog/features/library/bloc/library_event.dart';
import 'package:picklog/features/library/bloc/library_state.dart';
import 'package:picklog/features/library/library_entry_model.dart';
import 'package:picklog/l10n/app_localizations.dart';

import '../../mocks/mock_blocs.dart';

class _FakeLibraryEvent extends Fake implements LibraryEvent {}

LibraryEntry _entry({
  String id = 'entry-1',
  String name = 'Hollow Knight',
  int igdbId = 42,
  GameStatus status = GameStatus.playing,
  bool isFavorite = false,
}) {
  final now = DateTime(2024, 1, 1);
  return LibraryEntry(
    id: id,
    userId: 'user-1',
    game: CachedGame(
      id: 'g-$id',
      igdbId: igdbId,
      name: name,
      lastSyncedAt: now,
    ),
    status: status,
    isFavorite: isFavorite,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  setUpAll(() => registerFallbackValue(_FakeLibraryEvent()));

  group('GamesScreen', () {
    late MockLibraryBloc bloc;

    setUp(() {
      bloc = MockLibraryBloc();
      when(() => bloc.state).thenReturn(const LibraryState());
    });

    tearDown(() => bloc.close());

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
        home: BlocProvider<LibraryBloc>.value(
          value: bloc,
          child: const GamesScreen(),
        ),
      );
    }

    testWidgets('shows the library title', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.widgetWithText(AppBar, 'My Library'), findsOneWidget);
    });

    testWidgets('loading with no entries renders the list skeleton', (
      tester,
    ) async {
      when(
        () => bloc.state,
      ).thenReturn(const LibraryState(status: LibraryStatus.loading));

      await tester.pumpWidget(buildSubject());

      expect(find.byType(LibraryListSkeleton), findsOneWidget);
    });

    testWidgets('failure with no entries renders the error view and retry '
        'dispatches LibraryLoadRequested', (tester) async {
      when(() => bloc.state).thenReturn(
        const LibraryState(status: LibraryStatus.failure, userId: 'user-1'),
      );

      await tester.pumpWidget(buildSubject());

      expect(find.text('Failed to load library'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pump();

      final event =
          verify(() => bloc.add(captureAny())).captured.single
              as LibraryLoadRequested;
      expect(event.userId, 'user-1');
    });

    testWidgets('an empty default library shows the welcome empty view', (
      tester,
    ) async {
      when(
        () => bloc.state,
      ).thenReturn(const LibraryState(status: LibraryStatus.success));

      await tester.pumpWidget(buildSubject());

      expect(find.text('Your library is empty'), findsOneWidget);
      expect(find.text('Add Your First Game'), findsOneWidget);
    });

    testWidgets('a populated library renders a card per entry', (tester) async {
      when(() => bloc.state).thenReturn(
        LibraryState(
          status: LibraryStatus.success,
          entries: [
            _entry(id: 'a', name: 'Game A', igdbId: 1),
            _entry(id: 'b', name: 'Game B', igdbId: 2),
          ],
        ),
      );

      await tester.pumpWidget(buildSubject());

      expect(find.text('Game A'), findsOneWidget);
      expect(find.text('Game B'), findsOneWidget);
      expect(find.byType(Card), findsNWidgets(2));
    });

    testWidgets(
      'tapping the favorites filter dispatches LibraryFilterToggled',
      (tester) async {
        when(() => bloc.state).thenReturn(
          LibraryState(status: LibraryStatus.success, entries: [_entry()]),
        );

        await tester.pumpWidget(buildSubject());

        await tester.tap(find.byType(FilterChip).first);
        await tester.pump();

        final event =
            verify(() => bloc.add(captureAny())).captured.single
                as LibraryFilterToggled;
        expect(event.showFavoritesOnly, isTrue);
      },
    );

    testWidgets('tapping a card favorite icon dispatches '
        'LibraryToggleFavoriteRequested', (tester) async {
      when(() => bloc.state).thenReturn(
        LibraryState(
          status: LibraryStatus.success,
          entries: [_entry(id: 'fav-target')],
        ),
      );

      await tester.pumpWidget(buildSubject());

      // The card's favorite control is an IconButton; the favorites filter
      // chip also renders a favorite_border icon, so scope to the IconButton.
      await tester.tap(
        find.descendant(
          of: find.byType(IconButton),
          matching: find.byIcon(Icons.favorite_border),
        ),
      );
      await tester.pump();

      final event =
          verify(() => bloc.add(captureAny())).captured.single
              as LibraryToggleFavoriteRequested;
      expect(event.entryId, 'fav-target');
    });
  });
}
