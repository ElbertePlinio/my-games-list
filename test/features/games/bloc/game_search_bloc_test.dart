import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/features/games/bloc/game_search_bloc.dart';
import 'package:picklog/features/games/bloc/game_search_event.dart';
import 'package:picklog/features/games/bloc/game_search_filters.dart';
import 'package:picklog/features/games/bloc/game_search_state.dart';
import 'package:picklog/features/games/catalog_filters.dart';
import 'package:picklog/features/games/search_game_model.dart';
import 'package:picklog/features/games/i_games_repository.dart';

class MockGamesRepository extends Mock implements IGamesRepository {}

void main() {
  setUpAll(() => registerFallbackValue(const CatalogFilters()));

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
              filters: any(named: 'filters'),
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
            () => mockRepository.searchGames(
              'Test',
              limit: 20,
              offset: 0,
              filters: const CatalogFilters(),
            ),
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
              filters: any(named: 'filters'),
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
              filters: any(named: 'filters'),
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
                state.errorKind != null,
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
              filters: any(named: 'filters'),
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
            () => mockRepository.searchGames(
              'Test',
              limit: 20,
              offset: 0,
              filters: const CatalogFilters(),
            ),
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
              filters: any(named: 'filters'),
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

      test('isEmptyByFilters needs active catalog filters', () {
        const empty = GameSearchState(status: GameSearchStatus.success);
        expect(empty.isEmptyByFilters, isFalse);
        const filtered = GameSearchState(
          status: GameSearchStatus.success,
          filters: GameSearchFilters(catalog: CatalogFilters(genreIds: {10})),
        );
        expect(filtered.isEmptyByFilters, isTrue);
        expect(filtered.isEmpty, isTrue);
      });

      void stubSearch() =>
          when(
            () => mockRepository.searchGames(
              any(),
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
              filters: any(named: 'filters'),
            ),
          ).thenAnswer(
            (_) async => SearchGamesResponse(
              games: [games[1]],
              totalCount: 1,
              hasMore: false,
              offset: 0,
              limit: 20,
            ),
          );

      blocTest<GameSearchBloc, GameSearchState>(
        'a catalog filter change runs the query again with the filters',
        build: () {
          stubSearch();
          return bloc;
        },
        seed: seeded,
        act: (bloc) => bloc.add(
          const GameSearchFiltersChanged(
            GameSearchFilters(
              catalog: CatalogFilters(genreIds: {20}, minRating: 80),
            ),
          ),
        ),
        expect: () => [
          predicate<GameSearchState>((s) => s.hasActiveFilters),
          predicate<GameSearchState>((s) => s.isLoading && s.games.isEmpty),
          predicate<GameSearchState>(
            (s) =>
                s.status == GameSearchStatus.success && s.games.single.id == 2,
          ),
        ],
        verify: (_) => verify(
          () => mockRepository.searchGames(
            'q',
            limit: 20,
            offset: 0,
            filters: const CatalogFilters(genreIds: {20}, minRating: 80),
          ),
        ).called(1),
      );

      blocTest<GameSearchBloc, GameSearchState>(
        'a sort-only change reorders without a request',
        build: () => bloc,
        seed: seeded,
        act: (bloc) => bloc.add(
          const GameSearchFiltersChanged(
            GameSearchFilters(sort: GameSearchSort.nameAsc),
          ),
        ),
        expect: () => [
          predicate<GameSearchState>(
            (s) => s.visibleGames.map((g) => g.name).first == 'Apex',
          ),
        ],
        verify: (_) => verifyNever(
          () => mockRepository.searchGames(
            any(),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            filters: any(named: 'filters'),
          ),
        ),
      );

      blocTest<GameSearchBloc, GameSearchState>(
        'GameSearchFiltersCleared clears and searches again',
        build: () {
          stubSearch();
          return bloc;
        },
        seed: () => seeded(
          const GameSearchFilters(
            sort: GameSearchSort.nameAsc,
            catalog: CatalogFilters(genreIds: {10}),
          ),
        ),
        act: (bloc) => bloc.add(const GameSearchFiltersCleared()),
        verify: (bloc) {
          expect(bloc.state.filters.isEmpty, isTrue);
          verify(
            () => mockRepository.searchGames(
              'q',
              limit: 20,
              offset: 0,
              filters: const CatalogFilters(),
            ),
          ).called(1);
        },
      );

      blocTest<GameSearchBloc, GameSearchState>(
        'a new query keeps the filters and sends them',
        build: () {
          stubSearch();
          return bloc;
        },
        seed: () => seeded(
          const GameSearchFilters(catalog: CatalogFilters(platformIds: {200})),
        ),
        act: (bloc) => bloc.add(const GameSearchQueryChanged('new query')),
        wait: const Duration(milliseconds: 600),
        verify: (bloc) {
          expect(bloc.state.filters.catalog.platformIds, {200});
          verify(
            () => mockRepository.searchGames(
              'new query',
              limit: 20,
              offset: 0,
              filters: const CatalogFilters(platformIds: {200}),
            ),
          ).called(1);
        },
      );

      blocTest<GameSearchBloc, GameSearchState>(
        'load more sends the same filters',
        build: () {
          stubSearch();
          return bloc;
        },
        seed: () => GameSearchState(
          status: GameSearchStatus.success,
          query: 'q',
          games: games,
          currentOffset: 20,
          filters: const GameSearchFilters(
            catalog: CatalogFilters(yearFrom: 2018),
          ),
        ),
        act: (bloc) => bloc.add(const GameSearchLoadMore()),
        verify: (_) => verify(
          () => mockRepository.searchGames(
            'q',
            limit: 20,
            offset: 20,
            filters: const CatalogFilters(yearFrom: 2018),
          ),
        ).called(1),
      );
    });
  });
}
