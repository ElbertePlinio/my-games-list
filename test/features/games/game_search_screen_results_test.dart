import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/features/games/bloc/game_search_bloc.dart';
import 'package:picklog/features/games/bloc/game_search_event.dart';
import 'package:picklog/features/games/bloc/game_search_filters.dart';
import 'package:picklog/features/games/bloc/game_search_state.dart';
import 'package:picklog/features/games/game_search_screen.dart';
import 'package:picklog/features/games/search_game_model.dart';
import 'package:picklog/features/games/widgets/game_search_card.dart';
import 'package:picklog/l10n/app_localizations.dart';

import '../../mocks/mock_blocs.dart';

class _FakeGameSearchEvent extends Fake implements GameSearchEvent {}

List<SearchGame> _games(int count) {
  return List.generate(
    count,
    (i) => SearchGame(
      id: i,
      name: 'Game $i',
      genres: const [],
      platforms: const [],
    ),
  );
}

void main() {
  setUpAll(() => registerFallbackValue(_FakeGameSearchEvent()));

  group('GameSearchScreen results and interactions', () {
    late MockGameSearchBloc bloc;

    setUp(() {
      bloc = MockGameSearchBloc();
      when(() => bloc.state).thenReturn(const GameSearchState());
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
        home: BlocProvider<GameSearchBloc>.value(
          value: bloc,
          child: const GameSearchScreen(),
        ),
      );
    }

    testWidgets('renders the title and the search field', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('Search Games'), findsOneWidget);
      expect(find.widgetWithText(AppBar, 'Search Games'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('typing a query dispatches GameSearchQueryChanged', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());

      await tester.enterText(find.byType(TextField), 'zelda');
      await tester.pump();

      final event =
          verify(() => bloc.add(captureAny())).captured.single
              as GameSearchQueryChanged;
      expect(event.query, 'zelda');
    });

    testWidgets('tapping the clear icon dispatches GameSearchClear', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      verify(() => bloc.add(const GameSearchClear())).called(1);
    });

    testWidgets('loading state shows the loading semantics label', (
      tester,
    ) async {
      when(
        () => bloc.state,
      ).thenReturn(const GameSearchState(status: GameSearchStatus.loading));

      await tester.pumpWidget(buildSubject());

      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    });

    testWidgets('failure state shows the error message and icon', (
      tester,
    ) async {
      when(() => bloc.state).thenReturn(
        const GameSearchState(
          status: GameSearchStatus.failure,
          errorMessage: 'Search failed',
        ),
      );

      await tester.pumpWidget(buildSubject());

      expect(find.text('Search failed'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('failure state falls back to the default message', (
      tester,
    ) async {
      when(
        () => bloc.state,
      ).thenReturn(const GameSearchState(status: GameSearchStatus.failure));

      await tester.pumpWidget(buildSubject());

      expect(find.text('An error occurred'), findsOneWidget);
    });

    testWidgets('success with results renders a card per game', (tester) async {
      when(() => bloc.state).thenReturn(
        GameSearchState(
          status: GameSearchStatus.success,
          query: 'game',
          games: _games(3),
          hasMore: false,
        ),
      );

      await tester.pumpWidget(buildSubject());

      expect(find.byType(GameSearchCard), findsNWidgets(3));
    });

    testWidgets('a trailing progress indicator shows when more can be loaded', (
      tester,
    ) async {
      when(() => bloc.state).thenReturn(
        GameSearchState(
          status: GameSearchStatus.success,
          query: 'game',
          games: _games(2),
        ),
      );

      await tester.pumpWidget(buildSubject());

      expect(find.byType(GameSearchCard), findsNWidgets(2));
      // 2 result cards + a trailing load-more indicator.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('a short filtered list that cannot scroll auto-loads more so '
        'filtering does not strand pagination', (tester) async {
      // A tall viewport guarantees a few short cards cannot fill it, so the
      // user can never scroll to the bottom — but hasMore is true. The screen
      // must fetch the next page itself instead of stranding pagination.
      tester.view.physicalSize = const Size(800, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      when(() => bloc.state).thenReturn(
        GameSearchState(
          status: GameSearchStatus.success,
          query: 'game',
          games: _games(3),
        ),
      );

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      verify(() => bloc.add(const GameSearchLoadMore())).called(1);
    });

    testWidgets('filters that hide every loaded result keep paging while '
        'hasMore is true so later matching pages are still fetched', (
      tester,
    ) async {
      // The active filter narrows the only loaded game out (year 1990 vs a
      // game with no release date), so the screen shows the filtered-empty
      // guidance. Because hasMore is true, it must auto-fetch the next page
      // instead of dead-ending pagination.
      when(() => bloc.state).thenReturn(
        GameSearchState(
          status: GameSearchStatus.success,
          query: 'game',
          games: _games(2),
          hasMore: true,
          filters: const GameSearchFilters(year: 1990),
        ),
      );

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      // The recovery guidance is still present...
      expect(find.text('No matches for these filters'), findsOneWidget);
      expect(find.text('Clear filters'), findsOneWidget);
      // ...but paging continues regardless.
      verify(() => bloc.add(const GameSearchLoadMore())).called(1);
    });

    testWidgets('the filtered-empty state does not page when the catalog is '
        'exhausted', (tester) async {
      when(() => bloc.state).thenReturn(
        GameSearchState(
          status: GameSearchStatus.success,
          query: 'game',
          games: _games(2),
          hasMore: false,
          filters: const GameSearchFilters(year: 1990),
        ),
      );

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.text('No matches for these filters'), findsOneWidget);
      verifyNever(() => bloc.add(const GameSearchLoadMore()));
    });

    testWidgets('a caption clarifies that filters apply to loaded results', (
      tester,
    ) async {
      when(() => bloc.state).thenReturn(
        GameSearchState(
          status: GameSearchStatus.success,
          query: 'game',
          games: _games(3),
          filters: const GameSearchFilters(sort: GameSearchSort.nameAsc),
          hasMore: false,
        ),
      );

      await tester.pumpWidget(buildSubject());

      expect(find.text('Filters apply to loaded results'), findsOneWidget);
    });

    testWidgets('the offset-limit message shows at the list tail when the '
        'paging limit is reached', (tester) async {
      // Production-realistic state: the bloc emits offsetLimitReached with
      // hasMore false and the status back at success (no load-more in flight),
      // which makes canLoadMore false. The tail must still render the limit
      // message in that state.
      when(() => bloc.state).thenReturn(
        GameSearchState(
          status: GameSearchStatus.success,
          query: 'game',
          games: _games(1),
          hasMore: false,
          offsetLimitReached: true,
        ),
      );

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(
        find.text('Maximum search results reached. Please refine your search.'),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
