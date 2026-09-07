import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/features/browse/bloc/browse_genres_bloc.dart';
import 'package:picklog/features/browse/bloc/browse_genres_event.dart';
import 'package:picklog/features/browse/bloc/browse_genres_state.dart';
import 'package:picklog/features/games/game_detail_model.dart';
import 'package:picklog/features/games/i_games_repository.dart';

class MockGamesRepository extends Mock implements IGamesRepository {}

void main() {
  late MockGamesRepository mockRepository;

  setUp(() {
    mockRepository = MockGamesRepository();
  });

  group('BrowseGenresBloc', () {
    const mockGenres = [
      Genre(id: 12, name: 'Role-playing (RPG)'),
      Genre(id: 31, name: 'Adventure'),
    ];

    blocTest<BrowseGenresBloc, BrowseGenresState>(
      'emits [loading, success] with genres on a successful load',
      build: () {
        when(
          () => mockRepository.getGenres(),
        ).thenAnswer((_) async => mockGenres);
        return BrowseGenresBloc(gamesRepository: mockRepository);
      },
      act: (bloc) => bloc.add(const BrowseGenresLoadRequested()),
      expect: () => [
        const BrowseGenresState(status: BrowseGenresStatus.loading),
        predicate<BrowseGenresState>(
          (state) =>
              state.status == BrowseGenresStatus.success &&
              state.genres.length == 2 &&
              state.genres.first.name == 'Role-playing (RPG)',
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.getGenres()).called(1);
      },
    );

    blocTest<BrowseGenresBloc, BrowseGenresState>(
      'emits [loading, failure] when the load fails',
      build: () {
        when(
          () => mockRepository.getGenres(),
        ).thenThrow(Exception('network error'));
        return BrowseGenresBloc(gamesRepository: mockRepository);
      },
      act: (bloc) => bloc.add(const BrowseGenresLoadRequested()),
      expect: () => [
        const BrowseGenresState(status: BrowseGenresStatus.loading),
        predicate<BrowseGenresState>(
          (state) => state.status == BrowseGenresStatus.failure,
        ),
      ],
    );
  });
}
