import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/features/games/bloc/featured_banners_bloc.dart';
import 'package:picklog/features/games/bloc/featured_banners_event.dart';
import 'package:picklog/features/games/bloc/featured_banners_state.dart';
import 'package:picklog/features/games/featured_banner_model.dart';
import 'package:picklog/features/games/games_repository.dart';

class MockGamesRepository extends Mock implements GamesRepository {}

void main() {
  late MockGamesRepository mockRepository;

  setUp(() {
    mockRepository = MockGamesRepository();
  });

  group('FeaturedBannersBloc', () {
    const banner1 = FeaturedBanner(
      id: 'b1',
      title: 'Summer Sale',
      imageUrl: 'https://example.com/b1.jpg',
      position: 0,
    );
    const banner2 = FeaturedBanner(
      id: 'b2',
      title: 'New Releases',
      imageUrl: 'https://example.com/b2.jpg',
      position: 1,
    );

    blocTest<FeaturedBannersBloc, FeaturedBannersState>(
      'emits [loading, success] when load succeeds',
      build: () {
        when(
          () => mockRepository.getFeaturedBanners(),
        ).thenAnswer((_) async => const [banner1, banner2]);
        return FeaturedBannersBloc(gamesRepository: mockRepository);
      },
      act: (bloc) => bloc.add(const FeaturedBannersLoadRequested()),
      expect: () => [
        const FeaturedBannersState(status: FeaturedBannersStatus.loading),
        predicate<FeaturedBannersState>(
          (state) =>
              state.status == FeaturedBannersStatus.success &&
              state.banners.length == 2 &&
              state.banners.first.title == 'Summer Sale',
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.getFeaturedBanners()).called(1);
      },
    );

    blocTest<FeaturedBannersBloc, FeaturedBannersState>(
      'emits [loading, failure] when load throws',
      build: () {
        when(
          () => mockRepository.getFeaturedBanners(),
        ).thenThrow(Exception('Network error'));
        return FeaturedBannersBloc(gamesRepository: mockRepository);
      },
      act: (bloc) => bloc.add(const FeaturedBannersLoadRequested()),
      expect: () => [
        const FeaturedBannersState(status: FeaturedBannersStatus.loading),
        predicate<FeaturedBannersState>(
          (state) =>
              state.status == FeaturedBannersStatus.failure &&
              state.errorMessage != null,
        ),
      ],
    );

    blocTest<FeaturedBannersBloc, FeaturedBannersState>(
      'does not reload when already loading',
      build: () => FeaturedBannersBloc(gamesRepository: mockRepository),
      seed: () =>
          const FeaturedBannersState(status: FeaturedBannersStatus.loading),
      act: (bloc) => bloc.add(const FeaturedBannersLoadRequested()),
      expect: () => <FeaturedBannersState>[],
      verify: (_) {
        verifyNever(() => mockRepository.getFeaturedBanners());
      },
    );

    blocTest<FeaturedBannersBloc, FeaturedBannersState>(
      'refresh replaces banners with the latest on success',
      build: () {
        when(
          () => mockRepository.getFeaturedBanners(),
        ).thenAnswer((_) async => const [banner1, banner2]);
        return FeaturedBannersBloc(gamesRepository: mockRepository);
      },
      seed: () => const FeaturedBannersState(
        status: FeaturedBannersStatus.success,
        banners: [banner1],
      ),
      act: (bloc) => bloc.add(const FeaturedBannersRefreshRequested()),
      expect: () => [
        predicate<FeaturedBannersState>(
          (state) =>
              state.status == FeaturedBannersStatus.success &&
              state.banners.length == 2,
        ),
      ],
    );

    blocTest<FeaturedBannersBloc, FeaturedBannersState>(
      'refresh keeps existing banners when it fails',
      build: () {
        when(
          () => mockRepository.getFeaturedBanners(),
        ).thenThrow(Exception('Refresh failed'));
        return FeaturedBannersBloc(gamesRepository: mockRepository);
      },
      seed: () => const FeaturedBannersState(
        status: FeaturedBannersStatus.success,
        banners: [banner1, banner2],
      ),
      act: (bloc) => bloc.add(const FeaturedBannersRefreshRequested()),
      expect: () => [
        predicate<FeaturedBannersState>(
          (state) =>
              state.status == FeaturedBannersStatus.success &&
              state.banners.length == 2 &&
              state.errorMessage != null,
        ),
      ],
    );
  });

  group('FeaturedBannersState', () {
    test('initial state has correct defaults', () {
      const state = FeaturedBannersState();

      expect(state.status, FeaturedBannersStatus.initial);
      expect(state.banners, isEmpty);
      expect(state.errorMessage, isNull);
      expect(state.isLoading, isFalse);
      expect(state.hasBanners, isFalse);
    });

    test('isLoading and hasBanners reflect status and banners', () {
      const loading = FeaturedBannersState(
        status: FeaturedBannersStatus.loading,
      );
      const withData = FeaturedBannersState(
        status: FeaturedBannersStatus.success,
        banners: [
          FeaturedBanner(id: 'b', title: 'T', imageUrl: 'u', position: 0),
        ],
      );

      expect(loading.isLoading, isTrue);
      expect(withData.hasBanners, isTrue);
    });

    test('copyWith keeps unspecified values and clears errorMessage', () {
      const original = FeaturedBannersState(
        status: FeaturedBannersStatus.success,
        banners: [
          FeaturedBanner(id: 'b', title: 'T', imageUrl: 'u', position: 0),
        ],
        errorMessage: 'old',
      );

      final updated = original.copyWith(status: FeaturedBannersStatus.loading);

      expect(updated.status, FeaturedBannersStatus.loading);
      expect(updated.banners, original.banners);
      expect(updated.errorMessage, isNull);
    });
  });

  group('FeaturedBannersEvent', () {
    test('events support value equality', () {
      expect(
        const FeaturedBannersLoadRequested(),
        equals(const FeaturedBannersLoadRequested()),
      );
      expect(
        const FeaturedBannersRefreshRequested(),
        equals(const FeaturedBannersRefreshRequested()),
      );
    });
  });
}
