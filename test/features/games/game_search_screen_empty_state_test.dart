import 'package:bloc_test/bloc_test.dart';
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
import 'package:picklog/l10n/app_localizations.dart';

class _MockGameSearchBloc extends MockBloc<GameSearchEvent, GameSearchState>
    implements GameSearchBloc {}

class _FakeGameSearchEvent extends Fake implements GameSearchEvent {}

void main() {
  setUpAll(() => registerFallbackValue(_FakeGameSearchEvent()));

  group('GameSearchScreen welcoming states', () {
    late _MockGameSearchBloc bloc;

    setUp(() => bloc = _MockGameSearchBloc());

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

    testWidgets('initial state shows a warm title and hint', (tester) async {
      when(() => bloc.state).thenReturn(const GameSearchState());

      await tester.pumpWidget(buildSubject());

      expect(find.text('Find your next favorite'), findsOneWidget);
      expect(
        find.text('Search by title to add games to your library.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.search), findsWidgets);
    });

    testWidgets('no-results state shows a friendly title and the query', (
      tester,
    ) async {
      when(() => bloc.state).thenReturn(
        const GameSearchState(status: GameSearchStatus.success, query: 'zelda'),
      );

      await tester.pumpWidget(buildSubject());

      expect(find.text('No matches yet'), findsOneWidget);
      expect(find.text('No results found for "zelda"'), findsOneWidget);
      expect(find.byIcon(Icons.search_off), findsOneWidget);
    });

    testWidgets(
      'filtered empty state offers an inline clear-filters recovery action',
      (tester) async {
        registerFallbackValue(const GameSearchFiltersCleared());
        when(() => bloc.state).thenReturn(
          const GameSearchState(
            status: GameSearchStatus.success,
            query: 'zelda',
            games: [
              SearchGame(id: 1, name: 'Zelda', genres: [], platforms: []),
            ],
            filters: GameSearchFilters(year: 1999),
          ),
        );

        await tester.pumpWidget(buildSubject());

        expect(find.text('No matches for these filters'), findsOneWidget);

        final clearButton = find.text('Clear filters');
        expect(clearButton, findsOneWidget);

        await tester.tap(clearButton);
        await tester.pump();

        verify(() => bloc.add(const GameSearchFiltersCleared())).called(1);
      },
    );
  });
}
