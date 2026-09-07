import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/core/data/services/storage/local_storage_service.dart';
import 'package:picklog/core/services/consent/consent_category.dart';
import 'package:picklog/core/services/consent/consent_service.dart';
import 'package:picklog/core/services/consent/push_registration_coordinator.dart';
import 'package:picklog/core/services/consent/telemetry_gateway.dart';
import 'package:picklog/core/services/notification_service.dart';
import 'package:picklog/features/auth/bloc/auth_bloc.dart';
import 'package:picklog/features/auth/bloc/auth_state.dart';
import 'package:picklog/features/auth/user_model.dart';

class _MockStorage extends Mock implements LocalStorageService {}

class _MockGateway extends Mock implements TelemetryGateway {}

class _MockNotificationService extends Mock implements NotificationService {}

class _MockAuthBloc extends Mock implements AuthBloc {}

User _user() => const User(id: '1', email: 'e@e.com', name: 'u');

void main() {
  setUpAll(() {
    registerFallbackValue(ConsentCategory.push);
  });

  group('PushRegistrationCoordinator', () {
    late _MockStorage storage;
    late _MockGateway gateway;
    late ConsentService consent;
    late _MockNotificationService notifications;
    late _MockAuthBloc auth;
    late StreamController<AuthState> authStates;
    late PushRegistrationCoordinator coordinator;

    setUp(() {
      storage = _MockStorage();
      gateway = _MockGateway();
      notifications = _MockNotificationService();
      auth = _MockAuthBloc();
      authStates = StreamController<AuthState>.broadcast();

      when(() => storage.getBool(any())).thenAnswer((_) async => null);
      when(() => storage.setBool(any(), any())).thenAnswer((_) async => true);
      when(
        () => gateway.applyConsent(any(), granted: any(named: 'granted')),
      ).thenAnswer((_) async {});
      when(() => notifications.initialize()).thenAnswer((_) async {});
      when(() => notifications.disable()).thenAnswer((_) async {});
      when(() => auth.stream).thenAnswer((_) => authStates.stream);
      when(() => auth.state).thenReturn(const AuthUnauthenticated());

      consent = ConsentService(storage: storage, gateway: gateway);
      coordinator = PushRegistrationCoordinator(
        consentService: consent,
        notificationService: notifications,
        authBloc: auth,
      );
    });

    tearDown(() async {
      await coordinator.dispose();
      await authStates.close();
      await consent.dispose();
    });

    test(
      'does not register on start when consent and auth are both off',
      () async {
        coordinator.start();
        await Future<void>.delayed(Duration.zero);

        verifyNever(() => notifications.initialize());
      },
    );

    test('does not register on consent grant while unauthenticated', () async {
      coordinator.start();
      await consent.grant(ConsentCategory.push);
      await Future<void>.delayed(Duration.zero);

      verifyNever(() => notifications.initialize());
    });

    test('registers only once both consent and auth hold', () async {
      coordinator.start();
      await consent.grant(ConsentCategory.push);

      when(() => auth.state).thenReturn(AuthAuthenticated(_user()));
      authStates.add(AuthAuthenticated(_user()));
      await Future<void>.delayed(Duration.zero);

      verify(() => notifications.initialize()).called(1);
    });

    test('disables push when consent is revoked while authenticated', () async {
      when(() => auth.state).thenReturn(AuthAuthenticated(_user()));
      coordinator.start();
      await consent.grant(ConsentCategory.push);
      await Future<void>.delayed(Duration.zero);
      verify(() => notifications.initialize()).called(1);

      await consent.revoke(ConsentCategory.push);
      await Future<void>.delayed(Duration.zero);

      verify(() => notifications.disable()).called(1);
    });

    test(
      'retries registration after initialize() fails (does not skip forever)',
      () async {
        when(() => auth.state).thenReturn(AuthAuthenticated(_user()));
        // First attempt throws; the flag must reset so a later reconcile retries.
        when(
          () => notifications.initialize(),
        ).thenThrow(Exception('firebase down'));

        coordinator.start();
        await consent.grant(ConsentCategory.push);
        await Future<void>.delayed(Duration.zero);
        verify(() => notifications.initialize()).called(1);

        // Next attempt succeeds: a new reconcile (e.g. an auth state event)
        // must retry instead of treating the failed attempt as registered.
        when(() => notifications.initialize()).thenAnswer((_) async {});
        authStates.add(AuthAuthenticated(_user()));
        await Future<void>.delayed(Duration.zero);

        verify(() => notifications.initialize()).called(1);
      },
    );

    test(
      'revoke mid-registration tears down (disable fires before registered)',
      () async {
        when(() => auth.state).thenReturn(AuthAuthenticated(_user()));
        // initialize() never completes during this window, so _registered stays
        // false while the attempt is in flight.
        final pending = Completer<void>();
        when(
          () => notifications.initialize(),
        ).thenAnswer((_) => pending.future);

        coordinator.start();
        await consent.grant(ConsentCategory.push);
        await Future<void>.delayed(Duration.zero);
        verify(() => notifications.initialize()).called(1);

        // Revoke while the in-flight initialize() has not resolved.
        await consent.revoke(ConsentCategory.push);
        await Future<void>.delayed(Duration.zero);

        verify(() => notifications.disable()).called(1);
        pending.complete();
      },
    );

    test('disables push on logout', () async {
      when(() => auth.state).thenReturn(AuthAuthenticated(_user()));
      coordinator.start();
      await consent.grant(ConsentCategory.push);
      await Future<void>.delayed(Duration.zero);

      when(() => auth.state).thenReturn(const AuthUnauthenticated());
      authStates.add(const AuthUnauthenticated());
      await Future<void>.delayed(Duration.zero);

      verify(() => notifications.disable()).called(1);
    });
  });
}
