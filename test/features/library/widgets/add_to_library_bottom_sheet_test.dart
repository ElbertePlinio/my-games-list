import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picklog/core/widgets/score_badge.dart';
import 'package:picklog/core/domain/models/app_failure.dart';
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

    Widget buildSubject({
      LibraryEntry? existingEntry,
      GameStatus? initialStatus,
      List<Platform> sheetPlatforms = platforms,
      Future<List<Platform>> Function()? loadPlatforms,
    }) {
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
              platforms: sheetPlatforms,
              existingEntry: existingEntry,
              initialStatus: initialStatus,
              loadPlatforms: loadPlatforms,
            ),
          ),
        ),
      );
    }

    testWidgets('add mode shows the add header and the game name', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('Add to library'), findsOneWidget);
      expect(find.text('Hollow Knight'), findsOneWidget);
      // Add mode does not show the delete affordance.
      expect(find.text('Remove from library'), findsNothing);
    });

    testWidgets('groups essentials first and keeps details collapsed', (
      tester,
    ) async {
      // A tall window so the whole first step fits in the sheet.
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(buildSubject());

      expect(find.text('STATUS'), findsOneWidget);
      expect(find.text('PLATFORM'), findsOneWidget);
      expect(find.text('RATING'), findsOneWidget);
      expect(find.byType(ChoiceChip), findsNWidgets(GameStatus.values.length));
      expect(find.byType(ScoreRing), findsOneWidget);
      // Optional details stay folded away in add mode.
      expect(find.text('More details'), findsOneWidget);
      expect(find.text('PLAYTIME'), findsNothing);

      await tester.tap(find.text('More details'));
      await tester.pumpAndSettle();

      expect(find.text('PLAYTIME'), findsOneWidget);
      expect(find.text('DATES'), findsOneWidget);
      expect(find.text('DIFFICULTY'), findsOneWidget);
      expect(find.text('NOTES'), findsOneWidget);
    });

    testWidgets('the score preview follows the slider in the 0-100 format', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(existingEntry: _buildEntry()));

      final ring = tester.widget<ScoreRing>(find.byType(ScoreRing));
      expect(ring.score, 80);
      expect(find.text('80'), findsWidgets);
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

        expect(find.text('Edit entry'), findsOneWidget);
        expect(find.text('Remove from library'), findsOneWidget);
        // Details that already have values start expanded, and the notes and
        // difficulty controllers are pre-populated.
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
      expect(event.isFavorite, isTrue);
      expect(
        event.details,
        const LibraryEntryDetails(
          score: 80,
          difficulty: 'Hard',
          notes: 'Great game',
        ),
      );
    });

    testWidgets('edit mode can deliberately clear the score and notes', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(existingEntry: _buildEntry()));

      // Moving the score slider to 0 means no score.
      tester.widget<Slider>(find.byType(Slider)).onChanged!(0);
      await tester.pump();
      expect(find.text('Not rated'), findsOneWidget);
      final notes = find.widgetWithText(TextField, 'Great game');
      await tester.ensureVisible(notes);
      await tester.enterText(notes, '');
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pump();

      final event =
          verify(() => libraryBloc.add(captureAny())).captured.single
              as LibraryUpdateEntryRequested;
      // Null details are sent as null, so the API clears them.
      expect(event.details, const LibraryEntryDetails(difficulty: 'Hard'));
    });

    testWidgets('delete confirmation dispatches LibraryDeleteEntryRequested', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(existingEntry: _buildEntry()));

      // The delete button sits at the bottom of the draggable sheet.
      await tester.ensureVisible(find.text('Remove from library'));
      await tester.pump();
      await tester.tap(find.text('Remove from library'));
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

    testWidgets('adding a game shows no toast; the card state shows it', (
      tester,
    ) async {
      whenListen(
        libraryBloc,
        Stream<LibraryState>.fromIterable([
          const LibraryState(gameAddedOrUpdated: true),
        ]),
        initialState: const LibraryState(),
      );

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('shows a localized message when saving fails', (tester) async {
      whenListen(
        libraryBloc,
        Stream<LibraryState>.fromIterable([
          const LibraryState(
            failure: LibraryFailure(LibraryAction.add, AppErrorKind.network),
          ),
        ]),
        initialState: const LibraryState(),
      );

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(
        find.text("Couldn't save your changes. Try again."),
        findsOneWidget,
      );
    });

    testWidgets('a Finished initial status keeps a set end date', (
      tester,
    ) async {
      final entry = _buildEntry().copyWith(endDate: DateTime(2024, 3, 9));
      await tester.pumpWidget(
        buildSubject(existingEntry: entry, initialStatus: GameStatus.finished),
      );

      await tester.tap(find.text('Save'));
      await tester.pump();

      final event =
          verify(() => libraryBloc.add(captureAny())).captured.single
              as LibraryUpdateEntryRequested;
      expect(event.status, GameStatus.finished);
      expect(event.details?.endDate, DateTime(2024, 3, 9));
    });

    testWidgets('loaded platforms replace the single current platform', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(
          existingEntry: _buildEntry(),
          sheetPlatforms: const [Platform(id: 6, name: 'PC')],
          loadPlatforms: () async => platforms,
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byType(DropdownButtonFormField<Platform>),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<Platform>));
      await tester.pumpAndSettle();

      expect(find.text('PlayStation 4'), findsWidgets);
    });
  });
}
