import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/features/ai/ai_models.dart';
import 'package:picklog/features/ai/ai_repository.dart';
import 'package:picklog/features/ai/bloc/ai_status_cubit.dart';

import '../ai_fixtures.dart';

void main() {
  late MockAiRepository repository;

  setUp(() => repository = MockAiRepository());

  group('AiStatusCubit', () {
    blocTest<AiStatusCubit, AiStatusState>(
      'load emits loading then ready with the status',
      build: () {
        when(
          () => repository.getStatus(),
        ).thenAnswer((_) async => kStatusConsented);
        return AiStatusCubit(repository: repository);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const AiStatusState(load: AiStatusLoad.loading),
        const AiStatusState(load: AiStatusLoad.ready, status: kStatusConsented),
      ],
    );

    blocTest<AiStatusCubit, AiStatusState>(
      'load failure emits failure',
      build: () {
        when(
          () => repository.getStatus(),
        ).thenThrow(const AiException(AiErrorKind.network));
        return AiStatusCubit(repository: repository);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const AiStatusState(load: AiStatusLoad.loading),
        const AiStatusState(load: AiStatusLoad.failure),
      ],
    );

    blocTest<AiStatusCubit, AiStatusState>(
      'granting consent stores it through the API',
      build: () {
        when(
          () => repository.setConsent(granted: true),
        ).thenAnswer((_) async => const AiConsentResult(consented: true));
        return AiStatusCubit(repository: repository);
      },
      seed: () => const AiStatusState(
        load: AiStatusLoad.ready,
        status: kStatusNoConsent,
      ),
      act: (cubit) async {
        final saved = await cubit.setConsent(true);
        expect(saved, isTrue);
      },
      expect: () => [
        const AiStatusState(
          load: AiStatusLoad.ready,
          status: kStatusNoConsent,
          isSavingConsent: true,
        ),
        AiStatusState(
          load: AiStatusLoad.ready,
          status: kStatusNoConsent.copyWith(consented: true),
        ),
      ],
      verify: (_) =>
          verify(() => repository.setConsent(granted: true)).called(1),
    );

    blocTest<AiStatusCubit, AiStatusState>(
      'revoking consent clears it',
      build: () {
        when(
          () => repository.setConsent(granted: false),
        ).thenAnswer((_) async => const AiConsentResult(consented: false));
        return AiStatusCubit(repository: repository);
      },
      seed: () => const AiStatusState(
        load: AiStatusLoad.ready,
        status: kStatusConsented,
      ),
      act: (cubit) => cubit.setConsent(false),
      skip: 1,
      expect: () => [
        AiStatusState(
          load: AiStatusLoad.ready,
          status: kStatusConsented.copyWith(consented: false),
        ),
      ],
    );

    blocTest<AiStatusCubit, AiStatusState>(
      'a failed consent change keeps the old value and reports the error',
      build: () {
        when(
          () => repository.setConsent(granted: true),
        ).thenThrow(const AiException(AiErrorKind.network));
        return AiStatusCubit(repository: repository);
      },
      seed: () => const AiStatusState(
        load: AiStatusLoad.ready,
        status: kStatusNoConsent,
      ),
      act: (cubit) async => expect(await cubit.setConsent(true), isFalse),
      skip: 1,
      expect: () => [
        const AiStatusState(
          load: AiStatusLoad.ready,
          status: kStatusNoConsent,
          consentErrorKind: AiErrorKind.network,
        ),
      ],
    );

    blocTest<AiStatusCubit, AiStatusState>(
      'updateRemaining recomputes used today; markConsentMissing clears consent',
      build: () => AiStatusCubit(repository: repository),
      seed: () => const AiStatusState(
        load: AiStatusLoad.ready,
        status: kStatusConsented,
      ),
      act: (cubit) => cubit
        ..updateRemaining(15)
        ..markConsentMissing(),
      expect: () => [
        AiStatusState(
          load: AiStatusLoad.ready,
          status: kStatusConsented.copyWith(usedToday: 5),
        ),
        AiStatusState(
          load: AiStatusLoad.ready,
          status: kStatusConsented.copyWith(usedToday: 5, consented: false),
        ),
      ],
    );
    for (final fails in [false, true]) {
      test(
        'closing before load finishes does not throw (fails: $fails)',
        () async {
          final pending = Completer<AiStatus>();
          when(() => repository.getStatus()).thenAnswer((_) => pending.future);
          final cubit = AiStatusCubit(repository: repository);
          final loading = cubit.load();
          await cubit.close();
          fails
              ? pending.completeError(const AiException(AiErrorKind.network))
              : pending.complete(kStatusConsented);
          await expectLater(loading, completes);
        },
      );

      test(
        'closing before setConsent finishes does not throw (fails: $fails)',
        () async {
          final pending = Completer<AiConsentResult>();
          when(
            () => repository.setConsent(granted: true),
          ).thenAnswer((_) => pending.future);
          final cubit = AiStatusCubit(repository: repository);
          final saving = cubit.setConsent(true);
          await cubit.close();
          fails
              ? pending.completeError(const AiException(AiErrorKind.network))
              : pending.complete(const AiConsentResult(consented: true));
          await expectLater(saving, completion(!fails));
        },
      );
    }
  });
}
