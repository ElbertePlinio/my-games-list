import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/features/games/bloc/game_search_bloc.dart';
import 'package:picklog/features/games/bloc/game_search_event.dart';
import 'package:picklog/features/games/bloc/game_search_filters.dart';
import 'package:picklog/features/games/bloc/game_search_state.dart';
import 'package:picklog/features/games/search_game_model.dart';
import 'package:picklog/features/games/i_games_repository.dart';

class MockGamesRepository extends Mock implements IGamesRepository {}

void main() {
  group('GameSearchBloc', () {
    late MockGamesRepository mockRepository;
    late GameSearchBloc bloc;

    setUp(() {
      mockRepository = MockGamesRepository();
      bloc = GameSearchBloc(gamesRepository: mockRepository);
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state is correct', () {
      expect(bloc.state, equals(const GameSearchState()));
      expect(bloc.state.status, equals(GameSearchStatus.initial));
      expect(bloc.state.games, isEmpty);
      expect(bloc.state.query, isEmpty);
    });

    group('GameSearchQueryChanged', () {
      const mockGames = [
        SearchGame(id: 1, name: 'Test Game', genres: [], platforms: []),
      ];

      const mockResponse = SearchGamesResponse(
        games: mockGames,
        totalCount: 1,
        hasMore: false,
        offset: 0,
        limit: 20,
      );

      blocTest<GameSearchBloc, GameSearchState>(
        'emits [loading, success] when query changed with results',
        build: () {
          when(
            () => mockRepository.searchGames(
              any(),
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
            ),
          ).thenAnswer((_) async => mockResponse);
          return bloc;
        },
        act: (bloc) => bloc.add(const GameSearchQueryChanged('Test')),
        wait: const Duration(milliseconds: 600), // Wait for debounce
        expect: () => [
          predicate<GameSearchState>(
            (state) =>
                state.status == GameSearchStatus.loading &&
                state.query == 'Test' &&
                state.games.isEmpty,
          ),
          predicate<GameSearchState>(
            (state) =>
                state.status == GameSearchStatus.success &&
                state.games.length == 1 &&
                state.games.first.name == 'Test Game',
          ),
        ],
        verify: (_) {
          verify(
            () => mockRepository.searchGames('Test', limit: 20, offset: 0),
          ).called(1);
        },
      );

      blocTest<GameSearchBloc, GameSearchState>(
        'does not emit when query is empty',
        build: () => bloc,
        act: (bloc) => bloc.add(const GameSearchQueryChanged('')),
        wait: const Duration(milliseconds: 100),
        expect: () => [],
        verify: (_) {
          verifyNever(
            () => mockRepository.searchGames(
              any(),
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
            ),
          );
          // State should remain initial
          expect(bloc.state.status, GameSearchStatus.initial);
        },
      );

      blocTest<GameSearchBloc, GameSearchState>(
        'emits failure when repository throws',
        build: () {
          when(
            () => mockRepository.searchGames(
              any(),
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
            ),
          ).thenThrow(Exception('Search failed'));
          return bloc;
        },
        act: (bloc) => bloc.add(const GameSearchQueryChanged('Error')),
        wait: const Duration(milliseconds: 600),
        expect: () => [
          predicate<GameSearchState>(
            (state) =>
                state.status == GameSearchStatus.loading &&
                state.query == 'Error',
          ),
          predicate<GameSearchState>(
            (state) =>
                state.status == GameSearchStatus.failure &&
                state.errorMessage != null,
          ),
        ],
      );

      blocTest<GameSearchBloc, GameSearchState>(
        'debounces rapid query changes',
        build: () {
          when(
            () => mockRepository.searchGames(
              any(),
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
            ),
          ).thenAnswer((_) async => mockResponse);
          return bloc;
        },
        act: (bloc) async {
          bloc.add(const GameSearchQueryChanged('T'));
          await Future<void>.delayed(const Duration(milliseconds: 100));
          bloc.add(const GameSearchQueryChanged('Te'));
          await Future<void>.delayed(const Duration(milliseconds: 100));
          bloc.add(const GameSearchQueryChanged('Tes'));
          await Future<void>.delayed(const Duration(milliseconds: 100));
          bloc.add(const GameSearchQueryChanged('Test'));
        },
        wait: const Duration(milliseconds: 800),
        verify: (_) {
          // Should only call API once with final query after debounce
          verify(
            () => mockRepository.searchGames('Test', limit: 20, offset: 0),
          ).called(1);
        },
      );
    });

    group('GameSearchLoadMore', () {
      final mockGames = List.generate(
        20,
        (i) => SearchGame(
          id: i,
          name: 'Game $i',
          genres: const [],
          platforms: const [],
        ),
      );

      blocTest<GameSearchBloc, GameSearchState>(
        'loads more results when hasMore is true',
        build: () {
          when(
            () => mockRepository.searchGames(
              any(),
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
            ),
          ).thenAnswer(
            (_) async => SearchGamesResponse(
              games: mockGames,
              totalCount: 20,
              hasMore: true,
              offset: 20,
              limit: 20,
            ),
          );
          return bloc;
        },
        seed: () => GameSearchState(
          status: GameSearchStatus.success,
          query: 'Test',
          games: mockGames.sublist(0, 10),
          currentOffset: 20,
          hasMore: true,
        ),
        act: (bloc) => bloc.add(const GameSearchLoadMore()),
        expect: () => [
          predicate<GameSearchState>(
            (state) => state.status == GameSearchStatus.loadingMore,
          ),
          predicate<GameSearchState>(
            (state) =>
                state.status == GameSearchStatus.success &&
                state.games.length == 30,
          ),
        ],
      );

      blocTest<GameSearchBloc, GameSearchState>(
        'does not load more when already loading',
        build: () => bloc,
        seed: () => const GameSearchState(
          status: GameSearchStatus.loadingMore,
          query: 'Test',
        ),
        act: (bloc) => bloc.add(const GameSearchLoadMore()),
        expect: () => [],
      );

      blocTest<GameSearchBloc, GameSearchState>(
        'sets offsetLimitReached when offset >= 10000',
        build: () => bloc,
        seed: () => const GameSearchState(
          status: GameSearchStatus.success,
          query: 'Test',
          currentOffset: 10000,
          hasMore: true,
        ),
        act: (bloc) => bloc.add(const GameSearchLoadMore()),
        expect: () => [
          predicate<GameSearchState>(
            (state) =>
                state.offsetLimitReached == true && state.hasMore == false,
          ),
        ],
      );
    });

    group('GameSearchClear', () {
      blocTest<GameSearchBloc, GameSearchState>(
        'resets to initial state',
        build: () => bloc,
        seed: () => const GameSearchState(
          status: GameSearchStatus.success,
          query: 'Test',
          games: [SearchGame(id: 1, name: 'Test', genres: [], platforms: [])],
        ),
        act: (bloc) => bloc.add(const GameSearchClear()),
        expect: () => [const GameSearchState()],
      );
    });

    group('state getters', () {
      test('isLoading returns true when status is loading', () {
        const state = GameSearchState(status: GameSearchStatus.loading);
        expect(state.isLoading, isTrue);
      });

      test('isLoadingMore returns true when status is loadingMore', () {
        const state = GameSearchState(status: GameSearchStatus.loadingMore);
        expect(state.isLoadingMore, isTrue);
      });

      test('hasGames returns true when games list is not empty', () {
        const state = GameSearchState(
          games: [SearchGame(id: 1, name: 'Test', genres: [], platforms: [])],
        );
        expect(state.hasGames, isTrue);
      });

      test(
        'isEmpty returns true when games is empty and status is success',
        () {
          const state = GameSearchState(
            status: GameSearchStatus.success,
            games: [],
          );
          expect(state.isEmpty, isTrue);
        },
      );

      test('canLoadMore returns correct value', () {
        const stateCanLoad = GameSearchState(
          hasMore: true,
          offsetLimitReached: false,
          status: GameSearchStatus.success,
        );
        expect(stateCanLoad.canLoadMore, isTrue);

        const stateCannotLoad = GameSearchState(
          hasMore: false,
          offsetLimitReached: false,
          status: GameSearchStatus.success,
        );
        expect(stateCannotLoad.canLoadMore, isFalse);
      });
    });

    group('filters and sort', () {
      // Three games with distinct genres, platforms, years and names so each
      // filter/sort dimension can be exercised in isolation.
      final games = [
        SearchGame(
          id: 1,
          name: 'Zelda',
          firstReleaseDate: DateTime(2017),
          genres: const [GameGenre(id: 10, name: 'Adventure')],
          platforms: const [GamePlatform(id: 100, name: 'Switch')],
        ),
        SearchGame(
          id: 2,
          name: 'Apex',
          firstReleaseDate: DateTime(2019),
          genres: const [GameGenre(id: 20, name: 'Shooter')],
          platforms: const [GamePlatform(id: 200, name: 'PC')],
        ),
        SearchGame(
          id: 3,
          name: 'Mario',
          firstReleaseDate: DateTime(2021),
          genres: const [GameGenre(id: 10, name: 'Adventure')],
          platforms: const [GamePlatform(id: 100, name: 'Switch')],
        ),
      ];

      GameSearchState seeded([GameSearchFilters? filters]) => GameSearchState(
        status: GameSearchStatus.success,
        query: 'q',
        games: games,
        filters: filters ?? const GameSearchFilters(),
      );

      test('relevance keeps the original API order', () {
        final visible = seeded().visibleGames;
        expect(visible.map((g) => g.id), [1, 2, 3]);
      });

      test('name sort reorders results alphabetically', () {
        final visible = seeded(
          const GameSearchFilters(sort: GameSearchSort.nameAsc),
        ).visibleGames;
        expect(visible.map((g) => g.name), ['Apex', 'Mario', 'Zelda']);
      });

      test('year sort orders newest and oldest first', () {
        final newest = seeded(
          const GameSearchFilters(sort: GameSearchSort.yearDesc),
        ).visibleGames;
        expect(newest.map((g) => g.id), [3, 2, 1]);

        final oldest = seeded(
          const GameSearchFilters(sort: GameSearchSort.yearAsc),
        ).visibleGames;
        expect(oldest.map((g) => g.id), [1, 2, 3]);
      });

      test('genre filter narrows results to the selected genre', () {
        final visible = seeded(
          const GameSearchFilters(genreIds: {10}),
        ).visibleGames;
        expect(visible.map((g) => g.id), [1, 3]);
      });

      test('platform filter narrows results to the selected platform', () {
        final visible = seeded(
          const GameSearchFilters(platformIds: {200}),
        ).visibleGames;
        expect(visible.map((g) => g.id), [2]);
      });

      test('year filter narrows results to the selected year', () {
        final visible = seeded(
          const GameSearchFilters(year: 2019),
        ).visibleGames;
        expect(visible.map((g) => g.id), [2]);
      });

      test('combined filters intersect', () {
        final visible = seeded(
          const GameSearchFilters(genreIds: {10}, year: 2021),
        ).visibleGames;
        expect(visible.map((g) => g.id), [3]);
      });

      test('isEmptyByFilters is true when filters hide every result', () {
        final state = seeded(const GameSearchFilters(year: 1990));
        expect(state.visibleGames, isEmpty);
        expect(state.isEmptyByFilters, isTrue);
        expect(state.isEmpty, isTrue);
      });

      test('available facets derive from loaded results', () {
        final state = seeded();
        expect(state.availableGenres.map((g) => g.name), [
          'Adventure',
          'Shooter',
        ]);
        expect(state.availablePlatforms.map((p) => p.name), ['PC', 'Switch']);
        expect(state.availableYears, [2021, 2019, 2017]);
      });

      test('availableYears derives the year in UTC for a midnight-UTC '
          'release', () {
        // 2017-01-01T00:00:00Z resolves to 2016 in local time west of UTC, but
        // the year facet must report the UTC year (2017).
        final state = GameSearchState(
          status: GameSearchStatus.success,
          query: 'q',
          games: [
            SearchGame(
              id: 1,
              name: 'New Year Release',
              firstReleaseDate: DateTime.utc(2017, 1, 1),
              genres: const [],
              platforms: const [],
            ),
          ],
        );
        expect(state.availableYears, [2017]);
      });

      blocTest<GameSearchBloc, GameSearchState>(
        'GameSearchFiltersChanged applies the filters to the state',
        build: () => bloc,
        seed: seeded,
        act: (bloc) => bloc.add(
          const GameSearchFiltersChanged(GameSearchFilters(genreIds: {20})),
        ),
        expect: () => [
          predicate<GameSearchState>(
            (state) =>
                state.filters.genreIds.contains(20) &&
                state.visibleGames.length == 1 &&
                state.visibleGames.first.id == 2 &&
                state.hasActiveFilters,
          ),
        ],
      );

      blocTest<GameSearchBloc, GameSearchState>(
        'GameSearchFiltersCleared restores all results',
        build: () => bloc,
        seed: () => seeded(
          const GameSearchFilters(
            sort: GameSearchSort.nameAsc,
            genreIds: {10},
            year: 2017,
          ),
        ),
        act: (bloc) => bloc.add(const GameSearchFiltersCleared()),
        expect: () => [
          predicate<GameSearchState>(
            (state) =>
                state.filters.isEmpty &&
                !state.hasActiveFilters &&
                state.visibleGames.length == 3,
          ),
        ],
      );

      blocTest<GameSearchBloc, GameSearchState>(
        'a new query resets active filters',
        build: () {
          when(
            () => mockRepository.searchGames(
              any(),
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
            ),
          ).thenAnswer(
            (_) async => const SearchGamesResponse(
              games: [],
              totalCount: 0,
              hasMore: false,
              offset: 0,
              limit: 20,
            ),
          );
          return bloc;
        },
        seed: () => seeded(const GameSearchFilters(genreIds: {10})),
        act: (bloc) => bloc.add(const GameSearchQueryChanged('new query')),
        wait: const Duration(milliseconds: 600),
        expect: () => [
          predicate<GameSearchState>(
            (state) =>
                state.status == GameSearchStatus.loading &&
                state.filters.isEmpty,
          ),
          predicate<GameSearchState>(
            (state) => state.status == GameSearchStatus.success,
          ),
        ],
      );
    });
  });
}
