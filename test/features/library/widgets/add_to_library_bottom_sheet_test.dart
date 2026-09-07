import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/features/games/game_detail_model.dart';
import 'package:picklog/features/library/bloc/library_bloc.dart';
import 'package:picklog/features/library/bloc/library_event.dart';
import 'package:picklog/features/library/bloc/library_state.dart';
import 'package:picklog/features/library/library_entry_model.dart';
import 'package:picklog/features/library/widgets/add_to_library_bottom_sheet.dart';
import 'package:picklog/l10n/app_localizations.dart';

import '../../../mocks/mock_blocs.dart';

class _FakeLibraryEvent extends Fake implements LibraryEvent {}

LibraryEntry _buildEntry({
  GameStatus status = GameStatus.playing,
  int? score = 80,
  bool isFavorite = true,
  int? playtimeMinutes = 150,
  String? difficulty = 'Hard',
  String? notes = 'Great game',
}) {
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
    score: score,
    playtimeMinutes: playtimeMinutes,
    difficulty: difficulty,
    isFavorite: isFavorite,
    notes: notes,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  setUpAll(() => registerFallbackValue(_FakeLibraryEvent()));

  group('AddToLibraryBottomSheet', () {
    late MockLibraryBloc libraryBloc;

    const platforms = [
      Platform(id: 6, name: 'PC'),
      Platform(id: 48, name: 'PlayStation 4'),
    ];

    setUp(() {
      libraryBloc = MockLibraryBloc();
      when(() => libraryBloc.state).thenReturn(const LibraryState());
    });

    tearDown(() => libraryBloc.close());

    Widget buildSubject({LibraryEntry? existingEntry}) {
      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: BlocProvider<LibraryBloc>.value(
            value: libraryBloc,
            child: AddToLibraryBottomSheet(
              gameId: 42,
              gameName: 'Hollow Knight',
              platforms: platforms,
              existingEntry: existingEntry,
            ),
          ),
        ),
      );
    }

    testWidgets('add mode shows the add header and the game name', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('Add to Library'), findsOneWidget);
      expect(find.text('Hollow Knight'), findsOneWidget);
      // Add mode does not show the delete affordance.
      expect(find.text('Remove from Library'), findsNothing);
    });

    testWidgets('renders all section titles and a status chip per status', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Platform'), findsOneWidget);
      expect(find.text('Rating'), findsOneWidget);
      expect(find.text('Playtime'), findsOneWidget);
      expect(find.text('Dates'), findsOneWidget);
      expect(find.text('Difficulty'), findsOneWidget);
      expect(find.text('Notes'), findsOneWidget);
      expect(find.byType(ChoiceChip), findsNWidgets(GameStatus.values.length));
    });

    testWidgets('Save in add mode dispatches LibraryAddGameRequested with the '
        'default planned status', (tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.tap(find.text('Save'));
      await tester.pump();

      final captured = verify(
        () => libraryBloc.add(captureAny()),
      ).captured.single;
      expect(captured, isA<LibraryAddGameRequested>());
      final event = captured as LibraryAddGameRequested;
      expect(event.igdbId, 42);
      expect(event.status, GameStatus.planned);
      expect(event.isFavorite, isFalse);
    });

    testWidgets('selecting a status chip updates the dispatched event', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());

      await tester.tap(find.text('Finished'));
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pump();

      final event =
          verify(() => libraryBloc.add(captureAny())).captured.single
              as LibraryAddGameRequested;
      expect(event.status, GameStatus.finished);
    });

    testWidgets('toggling favorite is reflected in the dispatched event', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());

      // The favorite toggle lives further down the draggable sheet; bring it
      // into view before tapping.
      await tester.ensureVisible(find.byIcon(Icons.favorite_border));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pump();

      final event =
          verify(() => libraryBloc.add(captureAny())).captured.single
              as LibraryAddGameRequested;
      expect(event.isFavorite, isTrue);
    });

    testWidgets(
      'edit mode shows the edit header and pre-fills from the entry',
      (tester) async {
        await tester.pumpWidget(buildSubject(existingEntry: _buildEntry()));

        expect(find.text('Edit Entry'), findsOneWidget);
        expect(find.text('Remove from Library'), findsOneWidget);
        // Notes and difficulty controllers are pre-populated.
        expect(find.text('Great game'), findsOneWidget);
        expect(find.text('Hard'), findsOneWidget);
      },
    );

    testWidgets('Save in edit mode dispatches LibraryUpdateEntryRequested with '
        'the entry id and existing values', (tester) async {
      await tester.pumpWidget(buildSubject(existingEntry: _buildEntry()));

      await tester.tap(find.text('Save'));
      await tester.pump();

      final captured = verify(
        () => libraryBloc.add(captureAny()),
      ).captured.single;
      expect(captured, isA<LibraryUpdateEntryRequested>());
      final event = captured as LibraryUpdateEntryRequested;
      expect(event.entryId, 'entry-1');
      expect(event.status, GameStatus.playing);
      expect(event.score, 80);
      expect(event.isFavorite, isTrue);
      expect(event.notes, 'Great game');
    });

    testWidgets('delete confirmation dispatches LibraryDeleteEntryRequested', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(existingEntry: _buildEntry()));

      // The delete button sits at the bottom of the draggable sheet.
      await tester.ensureVisible(find.text('Remove from Library'));
      await tester.pump();
      await tester.tap(find.text('Remove from Library'));
      await tester.pumpAndSettle();

      // The confirmation dialog is shown.
      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Remove'));
      await tester.pumpAndSettle();

      final captured = verify(
        () => libraryBloc.add(captureAny()),
      ).captured.single;
      expect(captured, isA<LibraryDeleteEntryRequested>());
      expect((captured as LibraryDeleteEntryRequested).entryId, 'entry-1');
    });

    testWidgets('shows a success message when the bloc reports the game was '
        'added', (tester) async {
      whenListen(
        libraryBloc,
        Stream<LibraryState>.fromIterable([
          const LibraryState(gameAddedOrUpdated: true),
        ]),
        initialState: const LibraryState(),
      );

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.text('Game added to library successfully.'), findsOneWidget);
    });

    testWidgets('shows an error message when the bloc reports an error', (
      tester,
    ) async {
      whenListen(
        libraryBloc,
        Stream<LibraryState>.fromIterable([
          const LibraryState(errorMessage: 'Network down'),
        ]),
        initialState: const LibraryState(),
      );

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.text('Network down'), findsOneWidget);
    });
  });
}
