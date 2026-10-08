import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/features/ai/ai_models.dart';
import 'package:picklog/features/ai/ai_repository.dart';
import 'package:picklog/features/ai/bloc/ai_status_cubit.dart';
import 'package:picklog/features/ai/bloc/play_next_cubit.dart';
import 'package:picklog/features/ai/play_next_screen.dart';
import 'package:picklog/features/ai/widgets/ai_loading_view.dart';
import 'package:picklog/features/library/library_entry_model.dart';

import '../../helpers/stub_router_app.dart';
import 'ai_fixtures.dart';

LibraryEntry _entry(String id, GameStatus status) => LibraryEntry(
  id: id,
  userId: 'u1',
  game: CachedGame(
    id: 'g$id',
    igdbId: 1,
    name: 'Game $id',
    lastSyncedAt: DateTime.utc(2026),
  ),
  platform: const CachedPlatform(
    id: 'p',
    igdbPlatformId: 6,
    name: 'PC (Microsoft Windows)',
    abbreviation: 'PC',
  ),
  status: status,
  isFavorite: false,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

void main() {
  late MockAiRepository ai;
  late MockLibraryRepository library;

  setUpAll(() => registerFallbackValue(const PlayNextRequest()));

  setUp(() {
    ai = MockAiRepository();
    library = MockLibraryRepository();
    when(() => ai.getStatus()).thenAnswer((_) async => kStatusConsented);
    when(
      () => library.getLibrary('u1'),
    ).thenAnswer((_) async => [_entry('1', GameStatus.planned)]);
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final status = AiStatusCubit(repository: ai)..load();
    final playNext = PlayNextCubit(
      aiRepository: ai,
      libraryRepository: library,
      userId: 'u1',
    )..loadLibrary();
    addTearDown(status.close);
    addTearDown(playNext.close);
    await tester.pumpWidget(
      stubRouterApp(
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: status),
            BlocProvider.value(value: playNext),
          ],
          child: const PlayNextScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the form with moods, time, platforms and counter', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('What should I play tonight?'), findsOneWidget);
    for (final mood in ['Chill', 'Intense', 'Story', 'Social', 'Quick']) {
      expect(find.widgetWithText(ChoiceChip, mood), findsOneWidget);
    }
    expect(find.widgetWithText(ChoiceChip, 'Challenge'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
    expect(find.text('1 h'), findsWidgets);
    expect(find.widgetWithText(ChoiceChip, 'Any platform'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'PC'), findsOneWidget);
    expect(find.text('17 of 20 left today'), findsOneWidget);
  });

  testWidgets('generate shows a loading view, then rich pick cards', (
    tester,
  ) async {
    final completer = Completer<PlayNextResult>();
    when(() => ai.playNext(any())).thenAnswer((_) => completer.future);
    await pump(tester);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Chill'));
    await tester.pump();
    await tester.tap(find.text('Suggest games'));
    await tester.pump();

    expect(find.byType(AiLoadingView), findsOneWidget);
    expect(find.text('Reading your backlog'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Weighing your mood and time'), findsOneWidget);

    completer.complete(kPlayNextResult);
    await tester.pumpAndSettle();

    expect(find.byType(AiLoadingView), findsNothing);
    expect(find.text('Hades'), findsOneWidget);
    expect(find.text(kPickHades.reason), findsOneWidget);
    expect(find.text('About 45 min per session'), findsOneWidget);
    expect(find.text('About 1 h 30 min per session'), findsOneWidget);
    expect(find.text('TOP PICK'), findsOneWidget);
    expect(find.text('16 of 20 left today'), findsOneWidget);
    expect(find.text('Regenerate'), findsWidgets);
    final request =
        verify(() => ai.playNext(captureAny())).captured.single
            as PlayNextRequest;
    expect(request.mood, AiMood.chill);
    expect(request.minutesAvailable, 60);
  });

  testWidgets('start playing updates the library entry', (tester) async {
    when(() => ai.playNext(any())).thenAnswer((_) async => kPlayNextResult);
    final current = _entry('entry-1', GameStatus.planned);
    when(
      () => library.getLibraryEntry('entry-1'),
    ).thenAnswer((_) async => current);
    when(
      () => library.updateLibraryEntry(current, status: GameStatus.playing),
    ).thenAnswer((_) async => _entry('entry-1', GameStatus.playing));
    await pump(tester);

    await tester.tap(find.text('Suggest games'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start playing').first);
    await tester.pumpAndSettle();

    verify(
      () => library.updateLibraryEntry(current, status: GameStatus.playing),
    ).called(1);
    expect(find.text('Now playing'), findsOneWidget);
  });

  testWidgets('open goes to the game details', (tester) async {
    when(() => ai.playNext(any())).thenAnswer((_) async => kPlayNextResult);
    await pump(tester);
    await tester.tap(find.text('Suggest games'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open').first);
    await tester.pumpAndSettle();
    expect(find.text('route:gameDetails 1'), findsOneWidget);
  });

  testWidgets('an empty backlog sends the user to Explore or Search', (
    tester,
  ) async {
    when(
      () => library.getLibrary('u1'),
    ).thenAnswer((_) async => [_entry('1', GameStatus.finished)]);
    await pump(tester);

    expect(find.text('Your backlog is empty'), findsOneWidget);
    await tester.tap(find.text('Explore games'));
    await tester.pumpAndSettle();
    expect(find.textContaining('route:explore'), findsOneWidget);
  });

  testWidgets('an empty answer from the API shows the empty backlog', (
    tester,
  ) async {
    when(() => ai.playNext(any())).thenAnswer(
      (_) async => const PlayNextResult(picks: [], remainingToday: 17),
    );
    await pump(tester);
    await tester.tap(find.text('Suggest games'));
    await tester.pumpAndSettle();

    expect(find.text('Your backlog is empty'), findsOneWidget);
    await tester.tap(find.text('Search games'));
    await tester.pumpAndSettle();
    expect(find.textContaining('route:search'), findsOneWidget);
  });

  testWidgets('quota and upstream errors show localized messages', (
    tester,
  ) async {
    when(
      () => ai.playNext(any()),
    ).thenThrow(const AiException(AiErrorKind.quotaExceeded));
    await pump(tester);
    await tester.tap(find.text('Suggest games'));
    await tester.pumpAndSettle();
    expect(find.text('Daily limit reached'), findsOneWidget);
    expect(find.text('0 of 20 left today'), findsOneWidget);

    when(
      () => ai.playNext(any()),
    ).thenThrow(const AiException(AiErrorKind.upstream));
    await tester.tap(find.text('Suggest games'));
    await tester.pumpAndSettle();
    expect(
      find.text('The AI service did not answer. Try again in a moment.'),
      findsOneWidget,
    );
  });

  testWidgets('consent_required from the API asks for consent again', (
    tester,
  ) async {
    when(
      () => ai.playNext(any()),
    ).thenThrow(const AiException(AiErrorKind.consentRequired));
    await pump(tester);
    await tester.tap(find.text('Suggest games'));
    await tester.pumpAndSettle();
    expect(find.text('AI suggestions need your OK'), findsOneWidget);
  });
}
