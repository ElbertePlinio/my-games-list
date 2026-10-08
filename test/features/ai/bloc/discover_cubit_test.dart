import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/features/ai/ai_models.dart';
import 'package:picklog/features/ai/ai_repository.dart';
import 'package:picklog/features/ai/bloc/discover_cubit.dart';

import '../ai_fixtures.dart';

void main() {
  late MockAiRepository ai;

  setUp(() => ai = MockAiRepository());

  group('DiscoverCubit', () {
    blocTest<DiscoverCubit, DiscoverState>(
      'discover emits loading then picks',
      build: () {
        when(() => ai.discover(prompt: 'cozy')).thenAnswer(
          (_) async =>
              DiscoverResult(picks: [kDiscoverPick], remainingToday: 9),
        );
        return DiscoverCubit(repository: ai);
      },
      act: (cubit) => cubit.discover('  cozy '),
      expect: () => [
        const DiscoverState(status: DiscoverStatus.loading, prompt: 'cozy'),
        DiscoverState(
          status: DiscoverStatus.success,
          prompt: 'cozy',
          picks: [kDiscoverPick],
          remainingToday: 9,
        ),
      ],
    );

    blocTest<DiscoverCubit, DiscoverState>(
      'a quota failure is stored and retry runs the same prompt',
      build: () {
        when(
          () => ai.discover(prompt: 'cozy'),
        ).thenThrow(const AiException(AiErrorKind.quotaExceeded));
        return DiscoverCubit(repository: ai);
      },
      act: (cubit) async {
        await cubit.discover('cozy');
        await cubit.retry();
      },
      expect: () => [
        const DiscoverState(status: DiscoverStatus.loading, prompt: 'cozy'),
        const DiscoverState(
          status: DiscoverStatus.failure,
          prompt: 'cozy',
          errorKind: AiErrorKind.quotaExceeded,
        ),
        const DiscoverState(status: DiscoverStatus.loading, prompt: 'cozy'),
        const DiscoverState(
          status: DiscoverStatus.failure,
          prompt: 'cozy',
          errorKind: AiErrorKind.quotaExceeded,
        ),
      ],
      verify: (_) => verify(() => ai.discover(prompt: 'cozy')).called(2),
    );

    blocTest<DiscoverCubit, DiscoverState>(
      'long prompts are capped at 300 characters',
      build: () {
        when(() => ai.discover(prompt: any(named: 'prompt'))).thenAnswer(
          (_) async => const DiscoverResult(picks: [], remainingToday: 1),
        );
        return DiscoverCubit(repository: ai);
      },
      act: (cubit) => cubit.discover('y' * 400),
      verify: (cubit) => expect(cubit.state.prompt.length, kDiscoverPromptMax),
    );
  });
}
