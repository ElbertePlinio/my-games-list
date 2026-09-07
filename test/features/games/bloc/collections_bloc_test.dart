import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/features/games/bloc/collections_bloc.dart';
import 'package:picklog/features/games/bloc/collections_event.dart';
import 'package:picklog/features/games/bloc/collections_state.dart';
import 'package:picklog/features/games/collection_model.dart';
import 'package:picklog/features/games/discovery_game_model.dart';
import 'package:picklog/features/games/games_repository.dart';

class MockGamesRepository extends Mock implements GamesRepository {}

void main() {
  late MockGamesRepository mockRepository;

  setUp(() {
    mockRepository = MockGamesRepository();
  });

  group('CollectionsBloc', () {
    const mockCollections = [
      GameCollection(
        id: 'c1',
        slug: 'cozy-games',
        title: 'Cozy Games',
        games: [DiscoveryGame(id: 1, name: 'Stardew Valley')],
      ),
      GameCollection(id: 'c2', slug: 'roguelikes', title: 'Roguelikes'),
    ];

    blocTest<CollectionsBloc, CollectionsState>(
      'emits [loading, success] when load succeeds',
      build: () {
        when(
          () => mockRepository.getCollections(),
        ).thenAnswer((_) async => mockCollections);
        return CollectionsBloc(gamesRepository: mockRepository);
      },
      act: (bloc) => bloc.add(const CollectionsLoadRequested()),
      expect: () => [
        const CollectionsState(status: CollectionsStatus.loading),
        predicate<CollectionsState>(
          (state) =>
              state.status == CollectionsStatus.success &&
              state.collections.length == 2 &&
              state.collections.first.title == 'Cozy Games',
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.getCollections()).called(1);
      },
    );

    blocTest<CollectionsBloc, CollectionsState>(
      'emits [loading, failure] when load throws',
      build: () {
        when(
          () => mockRepository.getCollections(),
        ).thenThrow(Exception('Network error'));
        return CollectionsBloc(gamesRepository: mockRepository);
      },
      act: (bloc) => bloc.add(const CollectionsLoadRequested()),
      expect: () => [
        const CollectionsState(status: CollectionsStatus.loading),
        predicate<CollectionsState>(
          (state) =>
              state.status == CollectionsStatus.failure &&
              state.errorMessage != null,
        ),
      ],
    );

    blocTest<CollectionsBloc, CollectionsState>(
      'does not reload when already loading',
      build: () => CollectionsBloc(gamesRepository: mockRepository),
      seed: () => const CollectionsState(status: CollectionsStatus.loading),
      act: (bloc) => bloc.add(const CollectionsLoadRequested()),
      expect: () => <CollectionsState>[],
      verify: (_) {
        verifyNever(() => mockRepository.getCollections());
      },
    );
  });

  group('CollectionsState', () {
    test('initial state has correct defaults', () {
      const state = CollectionsState();

      expect(state.status, CollectionsStatus.initial);
      expect(state.collections, isEmpty);
      expect(state.errorMessage, isNull);
      expect(state.isLoading, isFalse);
      expect(state.hasCollections, isFalse);
    });

    test('isLoading and hasCollections reflect status and collections', () {
      const loading = CollectionsState(status: CollectionsStatus.loading);
      const withData = CollectionsState(
        status: CollectionsStatus.success,
        collections: [GameCollection(id: 'c1', slug: 's', title: 'T')],
      );

      expect(loading.isLoading, isTrue);
      expect(withData.hasCollections, isTrue);
    });

    test('copyWith keeps unspecified values and clears errorMessage', () {
      const original = CollectionsState(
        status: CollectionsStatus.success,
        collections: [GameCollection(id: 'c1', slug: 's', title: 'T')],
        errorMessage: 'old',
      );

      final updated = original.copyWith(status: CollectionsStatus.loading);

      expect(updated.status, CollectionsStatus.loading);
      expect(updated.collections, original.collections);
      expect(updated.errorMessage, isNull);
    });
  });

  group('CollectionsEvent', () {
    test('CollectionsLoadRequested supports value equality', () {
      const a = CollectionsLoadRequested();
      const b = CollectionsLoadRequested();

      expect(a, equals(b));
      expect(a.props, isEmpty);
    });
  });
}
