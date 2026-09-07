import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/features/games/anticipated_game_model.dart';
import 'package:picklog/features/games/bloc/anticipated_games_bloc.dart';
import 'package:picklog/features/games/bloc/anticipated_games_event.dart';
import 'package:picklog/features/games/bloc/anticipated_games_state.dart';
import 'package:picklog/features/games/i_games_repository.dart';

class MockGamesRepository extends Mock implements IGamesRepository {}

void main() {
  late MockGamesRepository mockRepository;

  setUp(() {
    mockRepository = MockGamesRepository();
  });

  group('AnticipatedGamesBloc', () {
    final mockGames = [
      AnticipatedGame(
        id: 52189,
        name: 'Grand Theft Auto VI',
        coverUrl:
            'https://images.igdb.com/igdb/image/upload/t_cover_big/co9rwo.jpg',
        hypes: 764,
        firstReleaseDate: DateTime.now().add(const Duration(days: 365)),
        platforms: const [
          GamePlatform(id: 169, name: 'Xbox Series X|S'),
          GamePlatform(id: 167, name: 'PlayStation 5'),
        ],
      ),
      AnticipatedGame(
        id: 12345,
        name: 'Another Game',
        coverUrl: '',
        hypes: 500,
        firstReleaseDate: DateTime.now().add(const Duration(days: 180)),
        platforms: const [],
      ),
    ];

    blocTest<AnticipatedGamesBloc, AnticipatedGamesState>(
      'emits [loading, success] when load is requested successfully',
      build: () {
        when(
          () => mockRepository.getAnticipatedGames(),
        ).thenAnswer((_) async => mockGames);
        return AnticipatedGamesBloc(gamesRepository: mockRepository);
      },
      act: (bloc) => bloc.add(const AnticipatedGamesLoadRequested()),
      expect: () => [
        const AnticipatedGamesState(status: AnticipatedGamesStatus.loading),
        predicate<AnticipatedGamesState>(
          (state) =>
              state.status == AnticipatedGamesStatus.success &&
              state.games.length == 2 &&
              state.games[0].name == 'Grand Theft Auto VI',
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.getAnticipatedGames()).called(1);
      },
    );

    blocTest<AnticipatedGamesBloc, AnticipatedGamesState>(
      'emits [loading, failure] when load fails',
      build: () {
        when(
          () => mockRepository.getAnticipatedGames(),
        ).thenThrow(Exception('Network error'));
        return AnticipatedGamesBloc(gamesRepository: mockRepository);
      },
      act: (bloc) => bloc.add(const AnticipatedGamesLoadRequested()),
      expect: () => [
        const AnticipatedGamesState(status: AnticipatedGamesStatus.loading),
        predicate<AnticipatedGamesState>(
          (state) =>
              state.status == AnticipatedGamesStatus.failure &&
              state.errorMessage != null,
        ),
      ],
    );

    blocTest<AnticipatedGamesBloc, AnticipatedGamesState>(
      'does not emit loading when already loading',
      build: () {
        when(() => mockRepository.getAnticipatedGames()).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return mockGames;
        });
        return AnticipatedGamesBloc(gamesRepository: mockRepository);
      },
      seed: () =>
          const AnticipatedGamesState(status: AnticipatedGamesStatus.loading),
      act: (bloc) => bloc.add(const AnticipatedGamesLoadRequested()),
      expect: () => [],
      verify: (_) {
        verifyNever(() => mockRepository.getAnticipatedGames());
      },
    );

    blocTest<AnticipatedGamesBloc, AnticipatedGamesState>(
      'emits success on refresh when already has games',
      build: () {
        when(
          () => mockRepository.getAnticipatedGames(),
        ).thenAnswer((_) async => mockGames);
        return AnticipatedGamesBloc(gamesRepository: mockRepository);
      },
      seed: () => AnticipatedGamesState(
        status: AnticipatedGamesStatus.success,
        games: [mockGames[0]],
      ),
      act: (bloc) => bloc.add(const AnticipatedGamesRefreshRequested()),
      expect: () => [
        predicate<AnticipatedGamesState>(
          (state) =>
              state.status == AnticipatedGamesStatus.success &&
              state.games.length == 2,
        ),
      ],
    );

    blocTest<AnticipatedGamesBloc, AnticipatedGamesState>(
      'keeps games on refresh failure',
      build: () {
        when(
          () => mockRepository.getAnticipatedGames(),
        ).thenThrow(Exception('Network error'));
        return AnticipatedGamesBloc(gamesRepository: mockRepository);
      },
      seed: () => AnticipatedGamesState(
        status: AnticipatedGamesStatus.success,
        games: mockGames,
      ),
      act: (bloc) => bloc.add(const AnticipatedGamesRefreshRequested()),
      expect: () => [
        predicate<AnticipatedGamesState>(
          (state) => state.games.length == 2 && state.errorMessage != null,
        ),
      ],
    );

    blocTest<AnticipatedGamesBloc, AnticipatedGamesState>(
      'emits new state with incremented tick on countdown tick',
      build: () {
        return AnticipatedGamesBloc(gamesRepository: mockRepository);
      },
      seed: () => AnticipatedGamesState(
        status: AnticipatedGamesStatus.success,
        games: mockGames,
        countdownTick: 0,
      ),
      act: (bloc) => bloc.add(const AnticipatedGamesCountdownTick()),
      expect: () => [
        predicate<AnticipatedGamesState>(
          (state) =>
              state.status == AnticipatedGamesStatus.success &&
              state.games.length == 2 &&
              state.countdownTick == 1,
        ),
      ],
    );

    test('starts countdown timer on successful load', () async {
      when(
        () => mockRepository.getAnticipatedGames(),
      ).thenAnswer((_) async => mockGames);

      final bloc = AnticipatedGamesBloc(gamesRepository: mockRepository);
      bloc.add(const AnticipatedGamesLoadRequested());

      await Future.delayed(const Duration(milliseconds: 100));

      // The timer should have been started
      // We can't directly test the timer, but we can verify the bloc is functioning
      expect(bloc.state.status, AnticipatedGamesStatus.success);

      await bloc.close();
    });

    test('stops countdown timer on close', () async {
      when(
        () => mockRepository.getAnticipatedGames(),
      ).thenAnswer((_) async => mockGames);

      final bloc = AnticipatedGamesBloc(gamesRepository: mockRepository);
      bloc.add(const AnticipatedGamesLoadRequested());

      await Future.delayed(const Duration(milliseconds: 100));
      await bloc.close();

      // After close, no more emissions should happen
      expect(bloc.isClosed, true);
    });
  });

  group('AnticipatedGamesState', () {
    test('initial state has correct defaults', () {
      const state = AnticipatedGamesState();

      expect(state.status, AnticipatedGamesStatus.initial);
      expect(state.games, isEmpty);
      expect(state.errorMessage, isNull);
      expect(state.lastUpdated, isNull);
    });

    test('isLoading returns true when status is loading', () {
      const state = AnticipatedGamesState(
        status: AnticipatedGamesStatus.loading,
      );

      expect(state.isLoading, true);
    });

    test('hasGames returns true when games list is not empty', () {
      final state = AnticipatedGamesState(
        games: [
          AnticipatedGame(
            id: 1,
            name: 'Test',
            coverUrl: '',
            hypes: 0,
            firstReleaseDate: DateTime.now(),
            platforms: const [],
          ),
        ],
      );

      expect(state.hasGames, true);
    });

    test('copyWith maintains existing values when not provided', () {
      final originalState = AnticipatedGamesState(
        status: AnticipatedGamesStatus.success,
        games: [
          AnticipatedGame(
            id: 1,
            name: 'Test',
            coverUrl: '',
            hypes: 0,
            firstReleaseDate: DateTime.now(),
            platforms: const [],
          ),
        ],
        lastUpdated: DateTime.now(),
      );

      final newState = originalState.copyWith(
        status: AnticipatedGamesStatus.loading,
      );

      expect(newState.status, AnticipatedGamesStatus.loading);
      expect(newState.games, originalState.games);
      expect(newState.lastUpdated, originalState.lastUpdated);
    });
  });

  group('AnticipatedGamesEvent', () {
    test('AnticipatedGamesLoadRequested has correct props', () {
      const event1 = AnticipatedGamesLoadRequested();
      const event2 = AnticipatedGamesLoadRequested();

      expect(event1, equals(event2));
      expect(event1.props, isEmpty);
    });

    test('AnticipatedGamesRefreshRequested has correct props', () {
      const event1 = AnticipatedGamesRefreshRequested();
      const event2 = AnticipatedGamesRefreshRequested();

      expect(event1, equals(event2));
    });

    test('AnticipatedGamesCountdownTick has correct props', () {
      const event1 = AnticipatedGamesCountdownTick();
      const event2 = AnticipatedGamesCountdownTick();

      expect(event1, equals(event2));
    });
  });
}
