import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/core/widgets/score_badge.dart';
import 'package:picklog/features/ai/ai_models.dart';
import 'package:picklog/features/ai/ai_repository.dart';
import 'package:picklog/features/ai/bloc/ai_status_cubit.dart';
import 'package:picklog/features/ai/bloc/discover_cubit.dart';
import 'package:picklog/features/ai/discover_screen.dart';
import 'package:picklog/features/library/bloc/library_bloc.dart';
import 'package:picklog/features/library/bloc/library_state.dart';
import 'package:picklog/features/library/widgets/add_to_library_bottom_sheet.dart';

import '../../helpers/stub_router_app.dart';
import '../../mocks/mock_blocs.dart';
import 'ai_fixtures.dart';

void main() {
  late MockAiRepository ai;
  late MockLibraryBloc libraryBloc;

  setUp(() {
    ai = MockAiRepository();
    libraryBloc = MockLibraryBloc();
    when(() => ai.getStatus()).thenAnswer((_) async => kStatusConsented);
    whenListen(
      libraryBloc,
      const Stream<LibraryState>.empty(),
      initialState: const LibraryState(),
    );
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final status = AiStatusCubit(repository: ai)..load();
    final discover = DiscoverCubit(repository: ai);
    addTearDown(status.close);
    addTearDown(discover.close);
    await tester.pumpWidget(
      stubRouterApp(
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: status),
            BlocProvider.value(value: discover),
            BlocProvider<LibraryBloc>.value(value: libraryBloc),
          ],
          child: const DiscoverScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a suggestion chip runs discover with its prompt', (
    tester,
  ) async {
    when(() => ai.discover(prompt: 'Like Hades but slower')).thenAnswer(
      (_) async => DiscoverResult(picks: [kDiscoverPick], remainingToday: 12),
    );
    await pump(tester);

    expect(find.text('Cozy games for the weekend'), findsOneWidget);
    expect(find.text('Short story games under 10 hours'), findsOneWidget);
    await tester.tap(find.text('Like Hades but slower'));
    await tester.pumpAndSettle();

    verify(() => ai.discover(prompt: 'Like Hades but slower')).called(1);
    expect(find.text('Stardew Valley'), findsOneWidget);
    expect(find.text(kDiscoverPick.reason), findsOneWidget);
    expect(find.text('2016'), findsOneWidget);
    expect(find.byType(ScoreBadge), findsOneWidget);
    expect(find.text('88'), findsOneWidget);
    expect(find.text('12 of 20 left today'), findsOneWidget);
  });

  testWidgets('typing a prompt and submitting runs discover', (tester) async {
    when(() => ai.discover(prompt: 'farming')).thenAnswer(
      (_) async => const DiscoverResult(picks: [], remainingToday: 10),
    );
    await pump(tester);

    await tester.enterText(find.byType(TextField), 'farming');
    await tester.tap(find.text('Find games'));
    await tester.pumpAndSettle();

    expect(find.text('No new games found'), findsOneWidget);
  });

  testWidgets('add to library opens the existing sheet', (tester) async {
    when(() => ai.discover(prompt: any(named: 'prompt'))).thenAnswer(
      (_) async => DiscoverResult(picks: [kDiscoverPick], remainingToday: 12),
    );
    await pump(tester);
    await tester.tap(find.text('Cozy games for the weekend'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add to library').first);
    await tester.pumpAndSettle();
    expect(find.byType(AddToLibraryBottomSheet), findsOneWidget);
  });

  testWidgets('open goes to the game details', (tester) async {
    when(() => ai.discover(prompt: any(named: 'prompt'))).thenAnswer(
      (_) async => DiscoverResult(picks: [kDiscoverPick], remainingToday: 12),
    );
    await pump(tester);
    await tester.tap(find.text('Cozy games for the weekend'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('route:gameDetails 10'), findsOneWidget);
  });

  testWidgets('an unavailable error shows the off state', (tester) async {
    when(
      () => ai.discover(prompt: any(named: 'prompt')),
    ).thenThrow(const AiException(AiErrorKind.unavailable));
    await pump(tester);
    await tester.tap(find.text('Find games'));
    await tester.pumpAndSettle();
    expect(find.text('AI suggestions are off'), findsOneWidget);
  });
}
