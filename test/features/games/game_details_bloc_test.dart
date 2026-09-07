import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/features/games/bloc/game_details_bloc.dart';
import 'package:picklog/features/games/bloc/game_details_event.dart';
import 'package:picklog/features/games/bloc/game_details_state.dart';
import 'package:picklog/features/games/game_detail_model.dart';
import 'package:picklog/features/games/i_games_repository.dart';

class MockGamesRepository extends Mock implements IGamesRepository {}

void main() {
  late GameDetailsBloc bloc;
  late MockGamesRepository mockRepository;

  setUp(() {
    mockRepository = MockGamesRepository();
    bloc = GameDetailsBloc(gamesRepository: mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  final mockGame = GameDetail.fromJson(const {
    'id': 1942,
    'name': 'The Witcher 3: Wild Hunt',
    'summary': 'An open-world action RPG',
    'total_rating': 92.82744671539679,
    'genres': [
      {'id': 12, 'name': 'Role-playing (RPG)'},
    ],
    'platforms': [
      {'id': 48, 'name': 'PlayStation 4'},
    ],
  });

  group('GameDetailsBloc', () {
    test('initial state is correct', () {
      expect(bloc.state.status, equals(GameDetailsStatus.initial));
      expect(bloc.state.game, isNull);
      expect(bloc.state.errorMessage, isNull);
    });

    blocTest<GameDetailsBloc, GameDetailsState>(
      'emits [loading, success] when GameDetailsLoadRequested succeeds',
      build: () {
        when(
          () => mockRepository.getGameDetails(1942),
        ).thenAnswer((_) async => mockGame);
        return GameDetailsBloc(gamesRepository: mockRepository);
      },
      act: (bloc) => bloc.add(const GameDetailsLoadRequested(1942)),
      expect: () => [
        const GameDetailsState(status: GameDetailsStatus.loading),
        predicate<GameDetailsState>(
          (state) =>
              state.status == GameDetailsStatus.success &&
              state.game?.id == 1942 &&
              state.game?.name == 'The Witcher 3: Wild Hunt',
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.getGameDetails(1942)).called(1);
      },
    );

    blocTest<GameDetailsBloc, GameDetailsState>(
      'emits [loading, failure] when GameDetailsLoadRequested fails',
      build: () {
        when(
          () => mockRepository.getGameDetails(99999),
        ).thenThrow(Exception('Game not found'));
        return GameDetailsBloc(gamesRepository: mockRepository);
      },
      act: (bloc) => bloc.add(const GameDetailsLoadRequested(99999)),
      expect: () => [
        const GameDetailsState(status: GameDetailsStatus.loading),
        predicate<GameDetailsState>(
          (state) =>
              state.status == GameDetailsStatus.failure &&
              state.errorMessage != null &&
              state.errorMessage!.contains('Game not found'),
        ),
      ],
    );

    blocTest<GameDetailsBloc, GameDetailsState>(
      'can load different game after initial load',
      build: () {
        when(
          () => mockRepository.getGameDetails(any()),
        ).thenAnswer((_) async => mockGame);
        return GameDetailsBloc(gamesRepository: mockRepository);
      },
      act: (bloc) async {
        bloc.add(const GameDetailsLoadRequested(1942));
        await Future<void>.delayed(const Duration(milliseconds: 100));
        bloc.add(const GameDetailsLoadRequested(472));
      },
      verify: (_) {
        verify(() => mockRepository.getGameDetails(1942)).called(1);
        verify(() => mockRepository.getGameDetails(472)).called(1);
      },
    );
  });

  group('GameDetailsEvent', () {
    test('GameDetailsLoadRequested props are correct', () {
      const event1 = GameDetailsLoadRequested(1942);
      const event2 = GameDetailsLoadRequested(1942);
      const event3 = GameDetailsLoadRequested(472);

      expect(event1, equals(event2));
      expect(event1, isNot(equals(event3)));
      expect(event1.props, equals([1942]));
    });
  });

  group('GameDetailsState', () {
    test('copyWith creates correct copy', () {
      const initialState = GameDetailsState();
      final updatedState = initialState.copyWith(
        status: GameDetailsStatus.success,
        game: mockGame,
      );

      expect(updatedState.status, equals(GameDetailsStatus.success));
      expect(updatedState.game, equals(mockGame));
      expect(updatedState.errorMessage, isNull);
    });

    test('copyWith preserves existing values when not specified', () {
      final stateWithGame = GameDetailsState(
        status: GameDetailsStatus.success,
        game: mockGame,
      );
      final copiedState = stateWithGame.copyWith(errorMessage: 'Some error');

      expect(copiedState.status, equals(GameDetailsStatus.success));
      expect(copiedState.game, equals(mockGame));
      expect(copiedState.errorMessage, equals('Some error'));
    });

    test('props equality works correctly', () {
      final state1 = GameDetailsState(
        status: GameDetailsStatus.success,
        game: mockGame,
      );
      final state2 = GameDetailsState(
        status: GameDetailsStatus.success,
        game: mockGame,
      );

      expect(state1, equals(state2));
    });
  });
}
