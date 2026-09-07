import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/core/data/services/storage/local_storage_service.dart';
import 'package:picklog/core/services/consent/consent_category.dart';
import 'package:picklog/core/services/consent/consent_service.dart';
import 'package:picklog/core/services/consent/telemetry_gateway.dart';

class _MockStorage extends Mock implements LocalStorageService {}

class _MockGateway extends Mock implements TelemetryGateway {}

void main() {
  setUpAll(() {
    registerFallbackValue(ConsentCategory.crash);
    registerFallbackValue(StackTrace.empty);
  });

  group('ConsentService', () {
    late _MockStorage storage;
    late _MockGateway gateway;
    late ConsentService service;

    setUp(() {
      storage = _MockStorage();
      gateway = _MockGateway();
      when(() => storage.getBool(any())).thenAnswer((_) async => null);
      when(() => storage.setBool(any(), any())).thenAnswer((_) async => true);
      when(() => storage.remove(any())).thenAnswer((_) async => true);
      when(
        () => gateway.applyConsent(any(), granted: any(named: 'granted')),
      ).thenAnswer((_) async {});
      when(
        () => gateway.recordError(any(), any(), fatal: any(named: 'fatal')),
      ).thenAnswer((_) async {});
      when(() => gateway.recordFlutterError(any())).thenAnswer((_) async {});
      service = ConsentService(storage: storage, gateway: gateway);
    });

    tearDown(() => service.dispose());

    test('every category defaults to denied', () {
      for (final category in ConsentCategory.values) {
        expect(service.isGranted(category), isFalse);
      }
    });

    test(
      'load applies the persisted (denied) state to every collector',
      () async {
        await service.load();

        for (final category in ConsentCategory.values) {
          verify(
            () => gateway.applyConsent(category, granted: false),
          ).called(1);
          expect(service.isGranted(category), isFalse);
        }
      },
    );

    test(
      'load reads a persisted granted flag and enables the collector',
      () async {
        when(
          () => storage.getBool(ConsentCategory.crash.storageKey),
        ).thenAnswer((_) async => true);

        await service.load();

        expect(service.isGranted(ConsentCategory.crash), isTrue);
        verify(
          () => gateway.applyConsent(ConsentCategory.crash, granted: true),
        ).called(1);
      },
    );

    test('grant persists the flag and enables the collector', () async {
      await service.grant(ConsentCategory.crash);

      expect(service.isGranted(ConsentCategory.crash), isTrue);
      verify(
        () => storage.setBool(ConsentCategory.crash.storageKey, true),
      ).called(1);
      verify(
        () => gateway.applyConsent(ConsentCategory.crash, granted: true),
      ).called(1);
    });

    test('revoke persists the flag and disables the collector', () async {
      await service.grant(ConsentCategory.push);
      clearInteractions(gateway);

      await service.revoke(ConsentCategory.push);

      expect(service.isGranted(ConsentCategory.push), isFalse);
      verify(
        () => storage.setBool(ConsentCategory.push.storageKey, false),
      ).called(1);
      verify(
        () => gateway.applyConsent(ConsentCategory.push, granted: false),
      ).called(1);
    });

    test('revokeAll re-denies and persists every category', () async {
      await service.grant(ConsentCategory.crash);
      await service.grant(ConsentCategory.push);
      await service.grant(ConsentCategory.analytics);
      clearInteractions(gateway);
      clearInteractions(storage);

      await service.revokeAll();

      for (final category in ConsentCategory.values) {
        expect(service.isGranted(category), isFalse);
        verify(() => storage.setBool(category.storageKey, false)).called(1);
        verify(() => gateway.applyConsent(category, granted: false)).called(1);
      }
    });

    group('answered flag', () {
      test('defaults to not answered', () {
        expect(service.hasAnswered, isFalse);
      });

      test('load reflects the persisted answered flag', () async {
        when(
          () => storage.getBool(ConsentService.answeredStorageKey),
        ).thenAnswer((_) async => true);

        await service.load();

        expect(service.hasAnswered, isTrue);
      });

      test('markAnswered persists the flag and is idempotent', () async {
        await service.markAnswered();
        await service.markAnswered();

        expect(service.hasAnswered, isTrue);
        verify(
          () => storage.setBool(ConsentService.answeredStorageKey, true),
        ).called(1);
      });

      test('revokeAll clears the answered flag', () async {
        await service.markAnswered();

        await service.revokeAll();

        expect(service.hasAnswered, isFalse);
        verify(
          () => storage.remove(ConsentService.answeredStorageKey),
        ).called(1);
      });

      test(
        'revokeAll signals the changes stream so the prompt re-shows',
        () async {
          await service.markAnswered();

          // The stream emission is what makes the cubit re-read hasAnswered
          // (false again) on a same-session logout + re-login, otherwise the
          // banner stays hidden for the next account.
          expectLater(service.changes, emits(isA<ConsentCategory>()));
          await service.revokeAll();
        },
      );
    });

    test(
      'setting the same value is a no-op (no storage/gateway calls)',
      () async {
        // Already denied by default.
        await service.revoke(ConsentCategory.analytics);

        verifyNever(() => storage.setBool(any(), any()));
        verifyNever(
          () => gateway.applyConsent(any(), granted: any(named: 'granted')),
        );
      },
    );

    test('emits the changed category on the changes stream', () async {
      expectLater(service.changes, emits(ConsentCategory.crash));
      await service.grant(ConsentCategory.crash);
    });

    group('error reporting gating', () {
      test('drops errors while crash consent is denied', () async {
        await service.reportError(Exception('x'), StackTrace.current);
        await service.reportFlutterError(Object());

        verifyNever(
          () => gateway.recordError(any(), any(), fatal: any(named: 'fatal')),
        );
        verifyNever(() => gateway.recordFlutterError(any()));
      });

      test('forwards errors once crash consent is granted', () async {
        await service.grant(ConsentCategory.crash);
        final error = Exception('boom');
        final stack = StackTrace.current;

        await service.reportError(error, stack, fatal: true);

        verify(() => gateway.recordError(error, stack, fatal: true)).called(1);
      });

      test('stops forwarding errors after crash consent is revoked', () async {
        await service.grant(ConsentCategory.crash);
        await service.revoke(ConsentCategory.crash);
        clearInteractions(gateway);

        await service.reportError(Exception('y'), StackTrace.current);

        verifyNever(
          () => gateway.recordError(any(), any(), fatal: any(named: 'fatal')),
        );
      });
    });
  });
}
