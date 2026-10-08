import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/features/games/bloc/explore_bloc.dart';
import 'package:picklog/features/games/bloc/filter_options_cubit.dart';
import 'package:picklog/features/games/catalog_filters.dart';
import 'package:picklog/features/games/discovery_game_model.dart';
import 'package:picklog/features/games/game_detail_model.dart';
import 'package:picklog/features/games/i_games_repository.dart';

class _MockRepo extends Mock implements IGamesRepository {}

DiscoveryGamesResponse _page(int from, int count, {bool hasMore = true}) =>
    DiscoveryGamesResponse(
      games: [
        for (var i = from; i < from + count; i++)
          DiscoveryGame(id: i, name: 'Game $i'),
      ],
      type: 'explore',
      totalCount: 500,
      hasMore: hasMore,
      offset: from,
      limit: count,
    );

void main() {
  late _MockRepo repo;
  setUpAll(() => registerFallbackValue(const ExploreFilters()));
  setUp(() => repo = _MockRepo());

  group('ExploreBloc', () {
    blocTest<ExploreBloc, ExploreState>(
      'loads the first page',
      setUp: () => when(
        () => repo.exploreGames(any(), limit: any(named: 'limit')),
      ).thenAnswer((_) async => _page(0, 30)),
      build: () => ExploreBloc(gamesRepository: repo),
      act: (b) => b.add(const ExploreLoadRequested()),
      expect: () => [
        isA<ExploreState>().having((s) => s.isLoading, 'loading', true),
        isA<ExploreState>()
            .having((s) => s.games.length, 'games', 30)
            .having((s) => s.hasMore, 'hasMore', true),
      ],
    );

    blocTest<ExploreBloc, ExploreState>(
      'changing filters reloads from the first page with them',
      setUp: () => when(
        () => repo.exploreGames(any(), limit: any(named: 'limit')),
      ).thenAnswer((_) async => _page(0, 5, hasMore: false)),
      build: () => ExploreBloc(gamesRepository: repo),
      seed: () => ExploreState(
        status: ExploreStatus.success,
        games: _page(0, 30).games,
        nextOffset: 30,
        hasMore: true,
      ),
      act: (b) => b.add(
        const ExploreFiltersChanged(
          ExploreFilters(
            catalog: CatalogFilters(genreIds: {12}),
            sort: ExploreSort.rating,
          ),
        ),
      ),
      verify: (b) {
        expect(b.state.games.length, 5);
        expect(b.state.hasMore, isFalse);
        verify(
          () => repo.exploreGames(
            const ExploreFilters(
              catalog: CatalogFilters(genreIds: {12}),
              sort: ExploreSort.rating,
            ),
            limit: ExploreBloc.pageSize,
          ),
        ).called(1);
      },
    );

    blocTest<ExploreBloc, ExploreState>(
      'load more appends and de-duplicates',
      setUp: () => when(
        () => repo.exploreGames(
          any(),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => _page(29, 30)),
      build: () => ExploreBloc(gamesRepository: repo),
      seed: () => ExploreState(
        status: ExploreStatus.success,
        games: _page(0, 30).games,
        nextOffset: 30,
        hasMore: true,
      ),
      act: (b) => b.add(const ExploreLoadMore()),
      skip: 1,
      expect: () => [
        isA<ExploreState>()
            .having((s) => s.games.length, 'games', 59)
            .having((s) => s.nextOffset, 'next', 60),
      ],
    );

    blocTest<ExploreBloc, ExploreState>(
      'a failed page keeps the games',
      setUp: () => when(
        () => repo.exploreGames(
          any(),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenThrow(Exception('x')),
      build: () => ExploreBloc(gamesRepository: repo),
      seed: () => ExploreState(
        status: ExploreStatus.success,
        games: _page(0, 30).games,
        nextOffset: 30,
        hasMore: true,
      ),
      act: (b) => b.add(const ExploreLoadMore()),
      skip: 1,
      expect: () => [
        isA<ExploreState>()
            .having((s) => s.games.length, 'games', 30)
            .having((s) => s.loadMoreFailed, 'failed', true),
      ],
    );
  });

  group('FilterOptionsCubit', () {
    blocTest<FilterOptionsCubit, FilterOptionsState>(
      'loads genres and platforms',
      setUp: () {
        when(
          () => repo.getGenres(),
        ).thenAnswer((_) async => const [Genre(id: 12, name: 'RPG')]);
        when(() => repo.getPlatforms()).thenAnswer(
          (_) async => const [
            PlatformOption(
              id: 6,
              name: 'PC (Microsoft Windows)',
              abbreviation: 'PC',
            ),
          ],
        );
      },
      build: () => FilterOptionsCubit(gamesRepository: repo),
      act: (c) => c.load(),
      verify: (c) {
        expect(c.state.status, FilterOptionsStatus.success);
        expect(c.state.genreName(12), 'RPG');
        expect(c.state.platformLabel(6), 'PC');
      },
    );

    blocTest<FilterOptionsCubit, FilterOptionsState>(
      'one failed list keeps the other',
      setUp: () {
        when(() => repo.getGenres()).thenThrow(Exception('x'));
        when(
          () => repo.getPlatforms(),
        ).thenAnswer((_) async => const [PlatformOption(id: 6, name: 'PC')]);
      },
      build: () => FilterOptionsCubit(gamesRepository: repo),
      act: (c) => c.load(),
      verify: (c) {
        expect(c.state.status, FilterOptionsStatus.success);
        expect(c.state.platforms, hasLength(1));
        expect(c.state.genres, isEmpty);
      },
    );
  });
}
