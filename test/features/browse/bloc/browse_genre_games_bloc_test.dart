import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/core/domain/models/app_failure.dart';
import 'package:picklog/features/browse/bloc/browse_genre_games_bloc.dart';
import 'package:picklog/features/browse/bloc/browse_genre_games_event.dart';
import 'package:picklog/features/browse/bloc/browse_genre_games_state.dart';
import 'package:picklog/features/games/discovery_game_model.dart';
import 'package:picklog/features/games/i_games_repository.dart';

class MockGamesRepository extends Mock implements IGamesRepository {}

void main() {
  late MockGamesRepository mockRepository;

  setUp(() {
    mockRepository = MockGamesRepository();
  });

  group('BrowseGenreGamesBloc', () {
    const response = DiscoveryGamesResponse(
      games: [
        DiscoveryGame(id: 1, name: 'Game A'),
        DiscoveryGame(id: 2, name: 'Game B'),
      ],
      type: 'by_genre',
      totalCount: 2,
      hasMore: false,
      offset: 0,
      limit: 40,
    );

    blocTest<BrowseGenreGamesBloc, BrowseGenreGamesState>(
      'emits [loading, success] with games for the genre',
      build: () {
        when(
          () => mockRepository.getGamesByGenre(12, limit: any(named: 'limit')),
        ).thenAnswer((_) async => response);
        return BrowseGenreGamesBloc(gamesRepository: mockRepository);
      },
      act: (bloc) => bloc.add(const BrowseGenreGamesLoadRequested(12)),
      expect: () => [
        const BrowseGenreGamesState(
          status: BrowseGenreGamesStatus.loading,
          genreId: 12,
        ),
        predicate<BrowseGenreGamesState>(
          (state) =>
              state.status == BrowseGenreGamesStatus.success &&
              state.games.length == 2 &&
              state.games.first.name == 'Game A',
        ),
      ],
      verify: (_) {
        verify(
          () => mockRepository.getGamesByGenre(12, limit: any(named: 'limit')),
        ).called(1);
      },
    );

    blocTest<BrowseGenreGamesBloc, BrowseGenreGamesState>(
      'emits [loading, failure] when the load fails',
      build: () {
        when(
          () => mockRepository.getGamesByGenre(12, limit: any(named: 'limit')),
        ).thenThrow(Exception('boom'));
        return BrowseGenreGamesBloc(gamesRepository: mockRepository);
      },
      act: (bloc) => bloc.add(const BrowseGenreGamesLoadRequested(12)),
      expect: () => [
        const BrowseGenreGamesState(
          status: BrowseGenreGamesStatus.loading,
          genreId: 12,
        ),
        predicate<BrowseGenreGamesState>(
          (state) =>
              state.status == BrowseGenreGamesStatus.failure &&
              state.errorKind == AppErrorKind.unknown,
        ),
      ],
    );

    group('pagination', () {
      DiscoveryGamesResponse page(List<int> ids, {required bool hasMore}) =>
          DiscoveryGamesResponse(
            games: [for (final id in ids) DiscoveryGame(id: id, name: 'G$id')],
            type: 'by_genre',
            totalCount: 100,
            hasMore: hasMore,
            offset: 0,
            limit: 40,
          );

      blocTest<BrowseGenreGamesBloc, BrowseGenreGamesState>(
        'LoadMore appends the next page at the next offset',
        build: () {
          when(
            () => mockRepository.getGamesByGenre(
              12,
              limit: any(named: 'limit'),
              offset: 40,
            ),
          ).thenAnswer((_) async => page([3, 4], hasMore: false));
          return BrowseGenreGamesBloc(gamesRepository: mockRepository);
        },
        seed: () => BrowseGenreGamesState(
          status: BrowseGenreGamesStatus.success,
          games: page([1, 2], hasMore: true).games,
          genreId: 12,
          hasMore: true,
          nextOffset: 40,
        ),
        act: (bloc) => bloc.add(const BrowseGenreGamesLoadMore()),
        expect: () => [
          predicate<BrowseGenreGamesState>((s) => s.isLoadingMore),
          predicate<BrowseGenreGamesState>(
            (s) =>
                s.status == BrowseGenreGamesStatus.success &&
                s.games.map((g) => g.id).toList().join(',') == '1,2,3,4' &&
                !s.hasMore &&
                s.nextOffset == 80,
          ),
        ],
      );

      blocTest<BrowseGenreGamesBloc, BrowseGenreGamesState>(
        'LoadMore does nothing when there are no more pages',
        build: () => BrowseGenreGamesBloc(gamesRepository: mockRepository),
        seed: () => const BrowseGenreGamesState(
          status: BrowseGenreGamesStatus.success,
          genreId: 12,
        ),
        act: (bloc) => bloc.add(const BrowseGenreGamesLoadMore()),
        expect: () => <BrowseGenreGamesState>[],
      );

      blocTest<BrowseGenreGamesBloc, BrowseGenreGamesState>(
        'a failed LoadMore keeps the loaded games and records the error',
        build: () {
          when(
            () => mockRepository.getGamesByGenre(
              12,
              limit: any(named: 'limit'),
              offset: 40,
            ),
          ).thenThrow(Exception('boom'));
          return BrowseGenreGamesBloc(gamesRepository: mockRepository);
        },
        seed: () => BrowseGenreGamesState(
          status: BrowseGenreGamesStatus.success,
          games: page([1, 2], hasMore: true).games,
          genreId: 12,
          hasMore: true,
          nextOffset: 40,
        ),
        act: (bloc) => bloc.add(const BrowseGenreGamesLoadMore()),
        skip: 1,
        expect: () => [
          predicate<BrowseGenreGamesState>(
            (s) => s.games.length == 2 && s.loadMoreFailed,
          ),
        ],
      );
    });
  });
}
