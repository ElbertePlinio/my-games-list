import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/features/integrations/bloc/achievement_game_cubit.dart';
import 'package:picklog/features/integrations/bloc/achievements_cubit.dart';
import 'package:picklog/features/integrations/integrations_models.dart';
import 'package:picklog/features/integrations/integrations_repository.dart';

import '../integrations_fixtures.dart';

void main() {
  late MockIntegrationsRepository repository;

  setUp(() => repository = MockIntegrationsRepository());

  group('AchievementsCubit', () {
    blocTest<AchievementsCubit, AchievementsState>(
      'load emits the summary',
      build: () {
        when(() => repository.getSummary()).thenAnswer((_) async => kSummary);
        return AchievementsCubit(repository: repository);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const AchievementsState(status: AchievementsStatus.loading),
        AchievementsState(status: AchievementsStatus.ready, summary: kSummary),
      ],
    );

    test('games are sorted by recent activity, undated last', () {
      final state = AchievementsState(
        status: AchievementsStatus.ready,
        summary: kSummary,
      );
      expect(state.games.map((g) => g.name), [
        'Hades',
        'Halo Infinite',
        'Portal',
      ]);
      expect(state.providersWithGames, [GameProvider.steam, GameProvider.xbox]);
    });

    blocTest<AchievementsCubit, AchievementsState>(
      'filterProvider narrows the games list',
      build: () => AchievementsCubit(repository: repository),
      seed: () => AchievementsState(
        status: AchievementsStatus.ready,
        summary: kSummary,
      ),
      act: (cubit) => cubit.filterProvider(GameProvider.xbox),
      verify: (cubit) =>
          expect(cubit.state.games.map((g) => g.name), ['Halo Infinite']),
    );

    blocTest<AchievementsCubit, AchievementsState>(
      'failure stores the error kind',
      build: () {
        when(
          () => repository.getSummary(),
        ).thenThrow(const IntegrationException(IntegrationErrorKind.network));
        return AchievementsCubit(repository: repository);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const AchievementsState(status: AchievementsStatus.loading),
        const AchievementsState(
          status: AchievementsStatus.failure,
          errorKind: IntegrationErrorKind.network,
        ),
      ],
    );
  });

  group('AchievementGameCubit', () {
    blocTest<AchievementGameCubit, AchievementGameState>(
      'load emits the game',
      build: () {
        when(
          () => repository.getGameAchievements(GameProvider.steam, '1145360'),
        ).thenAnswer((_) async => kHadesAchievements);
        return AchievementGameCubit(
          repository: repository,
          provider: GameProvider.steam,
          externalGameId: '1145360',
        );
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const AchievementGameState(status: AchievementGameStatus.loading),
        AchievementGameState(
          status: AchievementGameStatus.ready,
          game: kHadesAchievements,
        ),
      ],
    );

    test('sorted lists unlocked first, newest first, then locked', () {
      expect(kHadesAchievements.sorted.map((a) => a.id), ['a2', 'a3', 'a1']);
    });
  });

  group('GameAchievementsCubit', () {
    blocTest<GameAchievementsCubit, GameAchievementsState>(
      'load emits mapped games',
      build: () {
        when(
          () => repository.getAchievementsForGame(113112),
        ).thenAnswer((_) async => [kHadesAchievements]);
        return GameAchievementsCubit(repository: repository);
      },
      act: (cubit) => cubit.load(113112),
      expect: () => [
        GameAchievementsState(loaded: true, games: [kHadesAchievements]),
      ],
      verify: (cubit) => expect(cubit.state.hasData, isTrue),
    );

    blocTest<GameAchievementsCubit, GameAchievementsState>(
      'errors leave the section empty',
      build: () {
        when(
          () => repository.getAchievementsForGame(1),
        ).thenThrow(const IntegrationException(IntegrationErrorKind.unknown));
        return GameAchievementsCubit(repository: repository);
      },
      act: (cubit) => cubit.load(1),
      expect: () => [const GameAchievementsState(loaded: true)],
    );
  });
}
