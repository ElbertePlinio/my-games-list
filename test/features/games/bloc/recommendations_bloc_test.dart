import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/features/games/bloc/recommendations_bloc.dart';
import 'package:picklog/features/games/bloc/recommendations_event.dart';
import 'package:picklog/features/games/bloc/recommendations_state.dart';
import 'package:picklog/features/games/discovery_game_model.dart';
import 'package:picklog/features/games/games_repository.dart';

class MockGamesRepository extends Mock implements GamesRepository {}

void main() {
  late MockGamesRepository mockRepository;

  setUp(() {
    mockRepository = MockGamesRepository();
  });

  group('RecommendationsBloc', () {
    const mockGames = [
      DiscoveryGame(
        id: 1942,
        name: 'The Witcher 3: Wild Hunt',
        coverUrl: 'https://example.com/cover1.jpg',
        totalRating: 92.82,
      ),
      DiscoveryGame(id: 12345, name: 'Another Game'),
    ];

    blocTest<RecommendationsBloc, RecommendationsState>(
      'emits [loading, success] when load succeeds',
      build: () {
        when(
          () => mockRepository.getRecommendations(),
        ).thenAnswer((_) async => mockGames);
        return RecommendationsBloc(gamesRepository: mockRepository);
      },
      act: (bloc) => bloc.add(const RecommendationsLoadRequested()),
      expect: () => [
        const RecommendationsState(status: RecommendationsStatus.loading),
        predicate<RecommendationsState>(
          (state) =>
              state.status == RecommendationsStatus.success &&
              state.games.length == 2 &&
              state.games.first.name == 'The Witcher 3: Wild Hunt',
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.getRecommendations()).called(1);
      },
    );

    blocTest<RecommendationsBloc, RecommendationsState>(
      'emits [loading, failure] when load throws',
      build: () {
        when(
          () => mockRepository.getRecommendations(),
        ).thenThrow(Exception('Network error'));
        return RecommendationsBloc(gamesRepository: mockRepository);
      },
      act: (bloc) => bloc.add(const RecommendationsLoadRequested()),
      expect: () => [
        const RecommendationsState(status: RecommendationsStatus.loading),
        predicate<RecommendationsState>(
          (state) =>
              state.status == RecommendationsStatus.failure &&
              state.errorMessage != null,
        ),
      ],
    );

    blocTest<RecommendationsBloc, RecommendationsState>(
      'does not reload when already loading',
      build: () => RecommendationsBloc(gamesRepository: mockRepository),
      seed: () =>
          const RecommendationsState(status: RecommendationsStatus.loading),
      act: (bloc) => bloc.add(const RecommendationsLoadRequested()),
      expect: () => <RecommendationsState>[],
      verify: (_) {
        verifyNever(() => mockRepository.getRecommendations());
      },
    );
  });

  group('RecommendationsState', () {
    test('initial state has correct defaults', () {
      const state = RecommendationsState();

      expect(state.status, RecommendationsStatus.initial);
      expect(state.games, isEmpty);
      expect(state.errorMessage, isNull);
      expect(state.isLoading, isFalse);
      expect(state.hasGames, isFalse);
    });

    test('isLoading and hasGames reflect status and games', () {
      const loading = RecommendationsState(
        status: RecommendationsStatus.loading,
      );
      const withGames = RecommendationsState(
        status: RecommendationsStatus.success,
        games: [DiscoveryGame(id: 1, name: 'Game')],
      );

      expect(loading.isLoading, isTrue);
      expect(withGames.hasGames, isTrue);
    });

    test('copyWith keeps unspecified values and clears errorMessage', () {
      const original = RecommendationsState(
        status: RecommendationsStatus.success,
        games: [DiscoveryGame(id: 1, name: 'Game')],
        errorMessage: 'old',
      );

      final updated = original.copyWith(status: RecommendationsStatus.loading);

      expect(updated.status, RecommendationsStatus.loading);
      expect(updated.games, original.games);
      // errorMessage is intentionally not preserved by copyWith.
      expect(updated.errorMessage, isNull);
    });
  });

  group('RecommendationsEvent', () {
    test('RecommendationsLoadRequested supports value equality', () {
      const a = RecommendationsLoadRequested();
      const b = RecommendationsLoadRequested();

      expect(a, equals(b));
      expect(a.props, isEmpty);
    });
  });
}
