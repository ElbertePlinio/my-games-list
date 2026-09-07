import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/core/data/services/storage/local_storage_service.dart';
import 'package:picklog/core/services/consent/consent_category.dart';
import 'package:picklog/core/services/consent/consent_service.dart';
import 'package:picklog/core/services/consent/telemetry_gateway.dart';
import 'package:picklog/features/consent/bloc/consent_cubit.dart';

class _MockStorage extends Mock implements LocalStorageService {}

class _MockGateway extends Mock implements TelemetryGateway {}

void main() {
  setUpAll(() {
    registerFallbackValue(ConsentCategory.crash);
  });

  late _MockStorage storage;
  late _MockGateway gateway;
  late ConsentService service;
  late ConsentCubit cubit;

  setUp(() {
    storage = _MockStorage();
    gateway = _MockGateway();
    when(() => storage.getBool(any())).thenAnswer((_) async => null);
    when(() => storage.setBool(any(), any())).thenAnswer((_) async => true);
    when(() => storage.remove(any())).thenAnswer((_) async => true);
    when(
      () => gateway.applyConsent(any(), granted: any(named: 'granted')),
    ).thenAnswer((_) async {});
    service = ConsentService(storage: storage, gateway: gateway);
    cubit = ConsentCubit(service);
  });

  tearDown(() async {
    await cubit.close();
    await service.dispose();
  });

  test('initial state mirrors the service (not answered, all denied)', () {
    expect(cubit.state.hasAnswered, isFalse);
    for (final category in ConsentCategory.values) {
      expect(cubit.state.isGranted(category), isFalse);
    }
  });

  test('acceptAll grants every category and marks answered', () async {
    await cubit.acceptAll();

    for (final category in ConsentCategory.values) {
      expect(service.isGranted(category), isTrue);
      expect(cubit.state.isGranted(category), isTrue);
    }
    expect(service.hasAnswered, isTrue);
    expect(cubit.state.hasAnswered, isTrue);
  });

  test('rejectAll denies every category and marks answered', () async {
    await cubit.rejectAll();

    for (final category in ConsentCategory.values) {
      expect(service.isGranted(category), isFalse);
    }
    expect(service.hasAnswered, isTrue);
    expect(cubit.state.hasAnswered, isTrue);
  });

  test('setCategory(granted: true) grants only that category', () async {
    await cubit.setCategory(ConsentCategory.crash, granted: true);

    expect(service.isGranted(ConsentCategory.crash), isTrue);
    expect(service.isGranted(ConsentCategory.analytics), isFalse);
    verify(
      () => gateway.applyConsent(ConsentCategory.crash, granted: true),
    ).called(1);
    expect(service.hasAnswered, isTrue);
  });

  test('setCategory(granted: false) revokes that category', () async {
    await cubit.setCategory(ConsentCategory.push, granted: true);
    clearInteractions(gateway);

    await cubit.setCategory(ConsentCategory.push, granted: false);

    expect(service.isGranted(ConsentCategory.push), isFalse);
    verify(
      () => gateway.applyConsent(ConsentCategory.push, granted: false),
    ).called(1);
  });

  test('applyChoices applies a mixed map and marks answered', () async {
    await cubit.applyChoices({
      ConsentCategory.analytics: true,
      ConsentCategory.crash: false,
      ConsentCategory.push: true,
    });

    expect(service.isGranted(ConsentCategory.analytics), isTrue);
    expect(service.isGranted(ConsentCategory.crash), isFalse);
    expect(service.isGranted(ConsentCategory.push), isTrue);
    expect(service.hasAnswered, isTrue);
  });

  test('exposes isSaving for the duration of a choice', () async {
    final gate = Completer<void>();
    when(
      () => gateway.applyConsent(any(), granted: any(named: 'granted')),
    ).thenAnswer((_) => gate.future);

    expect(cubit.state.isSaving, isFalse);

    final pending = cubit.acceptAll();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.isSaving, isTrue);

    gate.complete();
    await pending;
    expect(cubit.state.isSaving, isFalse);
  });

  test('ignores a re-entrant choice while one is still saving', () async {
    final gate = Completer<void>();
    when(
      () => gateway.applyConsent(any(), granted: any(named: 'granted')),
    ).thenAnswer((_) => gate.future);

    // Accept stalls on the gated write; a Reject fired during the save is a
    // no-op, so the sequential category writes can't interleave.
    final pending = cubit.acceptAll();
    await Future<void>.delayed(Duration.zero);
    await cubit.rejectAll();

    gate.complete();
    await pending;

    for (final category in ConsentCategory.values) {
      expect(service.isGranted(category), isTrue);
    }
    expect(cubit.state.isSaving, isFalse);
  });

  test('reflects a revoke triggered on the service (e.g. logout)', () async {
    await cubit.setCategory(ConsentCategory.crash, granted: true);
    expect(cubit.state.isGranted(ConsentCategory.crash), isTrue);

    await service.revoke(ConsentCategory.crash);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.isGranted(ConsentCategory.crash), isFalse);
  });

  test(
    're-shows the prompt after revokeAll (cross-session re-prompt)',
    () async {
      // First account answers, so the banner is hidden.
      await cubit.acceptAll();
      expect(cubit.state.hasAnswered, isTrue);

      // Same-session logout teardown revokes everything and clears the
      // answered flag. The cubit must re-read hasAnswered via the changes
      // stream so the next account on this device sees the prompt again.
      await service.revokeAll();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.hasAnswered, isFalse);
      for (final category in ConsentCategory.values) {
        expect(cubit.state.isGranted(category), isFalse);
      }
    },
  );
}
