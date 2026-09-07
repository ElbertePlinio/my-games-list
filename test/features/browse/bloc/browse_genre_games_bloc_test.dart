import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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
        const BrowseGenreGamesState(status: BrowseGenreGamesStatus.loading),
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
        const BrowseGenreGamesState(status: BrowseGenreGamesStatus.loading),
        predicate<BrowseGenreGamesState>(
          (state) => state.status == BrowseGenreGamesStatus.failure,
        ),
      ],
    );
  });
}
