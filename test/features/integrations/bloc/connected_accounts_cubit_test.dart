import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/features/integrations/bloc/connected_accounts_cubit.dart';
import 'package:picklog/features/integrations/integrations_models.dart';
import 'package:picklog/features/integrations/integrations_repository.dart';

import '../integrations_fixtures.dart';

void main() {
  late MockIntegrationsRepository repository;

  setUpAll(() => registerFallbackValue(GameProvider.steam));

  setUp(() => repository = MockIntegrationsRepository());

  ConnectedAccountsCubit build() => ConnectedAccountsCubit(
    repository: repository,
    pollInterval: const Duration(seconds: 3),
  );

  group('ConnectedAccountsCubit', () {
    blocTest<ConnectedAccountsCubit, ConnectedAccountsState>(
      'load emits the providers',
      build: () {
        when(
          () => repository.getLinkedAccounts(),
        ).thenAnswer((_) async => providers(steam: account()));
        return build();
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const ConnectedAccountsState(status: ConnectedAccountsStatus.loading),
        ConnectedAccountsState(
          status: ConnectedAccountsStatus.ready,
          providers: providers(steam: account()),
        ),
      ],
      verify: (cubit) => expect(cubit.isPolling, isFalse),
    );

    blocTest<ConnectedAccountsCubit, ConnectedAccountsState>(
      'link replaces the provider row and reports success',
      build: () {
        when(
          () => repository.link(GameProvider.xbox, 'Hornet'),
        ).thenAnswer((_) async => account(status: SyncStatus.idle));
        return build();
      },
      seed: () => ConnectedAccountsState(
        status: ConnectedAccountsStatus.ready,
        providers: providers(),
      ),
      act: (cubit) => cubit.link(GameProvider.xbox, 'Hornet'),
      verify: (cubit) {
        expect(cubit.state.linkStatus, LinkStatus.success);
        expect(
          cubit.state.providerFor(GameProvider.xbox)!.account!.displayName,
          'Hornet',
        );
        expect(cubit.state.notice!.type, AccountNoticeType.linked);
      },
    );

    for (final kind in [
      IntegrationErrorKind.accountNotFound,
      IntegrationErrorKind.privateProfile,
    ]) {
      blocTest<ConnectedAccountsCubit, ConnectedAccountsState>(
        'link failure stores $kind',
        build: () {
          when(
            () => repository.link(GameProvider.steam, 'nobody'),
          ).thenThrow(IntegrationException(kind));
          return build();
        },
        seed: () => ConnectedAccountsState(
          status: ConnectedAccountsStatus.ready,
          providers: providers(),
        ),
        act: (cubit) => cubit.link(GameProvider.steam, 'nobody'),
        verify: (cubit) {
          expect(cubit.state.linkStatus, LinkStatus.failure);
          expect(cubit.state.linkErrorKind, kind);
        },
      );
    }

    blocTest<ConnectedAccountsCubit, ConnectedAccountsState>(
      'an empty identifier fails without a request',
      build: build,
      act: (cubit) => cubit.link(GameProvider.steam, '   '),
      verify: (cubit) {
        expect(
          cubit.state.linkErrorKind,
          IntegrationErrorKind.invalidIdentifier,
        );
        verifyNever(() => repository.link(any(), any()));
      },
    );

    test(
      'sync starts polling and polling stops when the sync is done',
      () async {
        var calls = 0;
        when(
          () => repository.sync(GameProvider.steam, importLibrary: true),
        ).thenAnswer((_) async {});
        when(() => repository.getLinkedAccounts()).thenAnswer((_) async {
          calls++;
          return calls < 2
              ? providers(steam: account(status: SyncStatus.syncing))
              : providers(steam: account(status: SyncStatus.ok));
        });
        final cubit = ConnectedAccountsCubit(
          repository: repository,
          pollInterval: const Duration(milliseconds: 20),
        );
        addTearDown(cubit.close);
        cubit.emit(
          ConnectedAccountsState(
            status: ConnectedAccountsStatus.ready,
            providers: providers(steam: account()),
          ),
        );

        await cubit.sync(GameProvider.steam, importLibrary: true);
        expect(cubit.isPolling, isTrue);
        expect(cubit.state.providerFor(GameProvider.steam)!.isSyncing, isTrue);
        expect(cubit.state.notice!.type, AccountNoticeType.syncStarted);

        await Future<void>.delayed(const Duration(milliseconds: 120));
        expect(calls, 2);
        expect(cubit.isPolling, isFalse);
        expect(cubit.state.notice!.type, AccountNoticeType.syncFinished);

        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(calls, 2);
      },
    );

    test('closing the cubit stops polling', () async {
      var calls = 0;
      when(() => repository.getLinkedAccounts()).thenAnswer((_) async {
        calls++;
        return providers(steam: account(status: SyncStatus.syncing));
      });
      final cubit = ConnectedAccountsCubit(
        repository: repository,
        pollInterval: const Duration(milliseconds: 20),
      );

      await cubit.load();
      expect(cubit.isPolling, isTrue);

      await cubit.close();
      expect(cubit.isPolling, isFalse);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(calls, 1);
    });

    blocTest<ConnectedAccountsCubit, ConnectedAccountsState>(
      'sync too soon reports a notice and does not poll',
      build: () {
        when(() => repository.sync(GameProvider.steam)).thenThrow(
          const IntegrationException(IntegrationErrorKind.syncTooSoon),
        );
        return build();
      },
      seed: () => ConnectedAccountsState(
        status: ConnectedAccountsStatus.ready,
        providers: providers(steam: account()),
      ),
      act: (cubit) => cubit.sync(GameProvider.steam),
      verify: (cubit) {
        expect(cubit.state.notice!.type, AccountNoticeType.syncFailed);
        expect(cubit.state.notice!.errorKind, IntegrationErrorKind.syncTooSoon);
        expect(cubit.state.busyProviders, isEmpty);
        expect(cubit.isPolling, isFalse);
      },
    );

    blocTest<ConnectedAccountsCubit, ConnectedAccountsState>(
      'unlink clears the account',
      build: () {
        when(
          () => repository.unlink(GameProvider.steam),
        ).thenAnswer((_) async {});
        return build();
      },
      seed: () => ConnectedAccountsState(
        status: ConnectedAccountsStatus.ready,
        providers: providers(steam: account()),
      ),
      act: (cubit) => cubit.unlink(GameProvider.steam),
      verify: (cubit) {
        expect(cubit.state.providerFor(GameProvider.steam)!.isLinked, isFalse);
        expect(cubit.state.notice!.type, AccountNoticeType.unlinked);
        verify(() => repository.unlink(GameProvider.steam)).called(1);
      },
    );

    blocTest<ConnectedAccountsCubit, ConnectedAccountsState>(
      'a failed unlink keeps the account',
      build: () {
        when(
          () => repository.unlink(GameProvider.steam),
        ).thenThrow(const IntegrationException(IntegrationErrorKind.network));
        return build();
      },
      seed: () => ConnectedAccountsState(
        status: ConnectedAccountsStatus.ready,
        providers: providers(steam: account()),
      ),
      act: (cubit) => cubit.unlink(GameProvider.steam),
      verify: (cubit) {
        expect(cubit.state.providerFor(GameProvider.steam)!.isLinked, isTrue);
        expect(cubit.state.notice!.type, AccountNoticeType.unlinkFailed);
      },
    );
    ConnectedAccountsCubit seeded(List<LinkedProvider> list) {
      final cubit = ConnectedAccountsCubit(
        repository: repository,
        pollInterval: const Duration(minutes: 1),
      );
      addTearDown(cubit.close);
      cubit.emit(
        ConnectedAccountsState(
          status: ConnectedAccountsStatus.ready,
          providers: list,
        ),
      );
      return cubit;
    }

    test('an older poll does not undo a sync started after it', () async {
      final pending = Completer<List<LinkedProvider>>();
      when(
        () => repository.getLinkedAccounts(),
      ).thenAnswer((_) => pending.future);
      when(() => repository.sync(GameProvider.xbox)).thenAnswer((_) async {});
      final cubit = seeded(
        providers(
          steam: account(status: SyncStatus.syncing),
          xbox: account(status: SyncStatus.idle),
        ),
      );

      final polling = cubit.poll();
      await cubit.sync(GameProvider.xbox);
      // The server answered before the Xbox sync started.
      pending.complete(
        providers(
          steam: account(status: SyncStatus.syncing),
          xbox: account(status: SyncStatus.idle),
        ),
      );
      await polling;

      expect(cubit.state.providerFor(GameProvider.xbox)!.isSyncing, isTrue);
      expect(cubit.isPolling, isTrue);
    });

    test('an older poll does not restore an unlinked account', () async {
      final pending = Completer<List<LinkedProvider>>();
      when(
        () => repository.getLinkedAccounts(),
      ).thenAnswer((_) => pending.future);
      when(() => repository.unlink(GameProvider.xbox)).thenAnswer((_) async {});
      final cubit = seeded(
        providers(
          steam: account(status: SyncStatus.syncing),
          xbox: account(),
        ),
      );

      final polling = cubit.poll();
      await cubit.unlink(GameProvider.xbox);
      pending.complete(
        providers(
          steam: account(status: SyncStatus.syncing),
          xbox: account(),
        ),
      );
      await polling;

      expect(cubit.state.providerFor(GameProvider.xbox)!.isLinked, isFalse);
    });

    test('a refresh keeps the list on screen while it loads', () async {
      final pending = Completer<List<LinkedProvider>>();
      when(
        () => repository.getLinkedAccounts(),
      ).thenAnswer((_) => pending.future);
      final cubit = seeded(providers(steam: account()));
      final statuses = <ConnectedAccountsStatus>[];
      final sub = cubit.stream.listen((s) => statuses.add(s.status));
      addTearDown(sub.cancel);

      final refreshing = cubit.load();
      pending.complete(providers(steam: account(name: 'Knight')));
      await refreshing;
      await Future<void>.delayed(Duration.zero);

      expect(statuses, isNot(contains(ConnectedAccountsStatus.loading)));
      expect(
        cubit.state.providerFor(GameProvider.steam)!.account!.displayName,
        'Knight',
      );
    });
  });
}
