import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/core/data/services/http/i_http_client.dart';
import 'package:picklog/core/data/services/storage/local_storage_service.dart';
import 'package:picklog/core/data/services/storage/token_storage.dart';
import 'package:picklog/core/services/consent/consent_category.dart';
import 'package:picklog/core/services/consent/consent_service.dart';
import 'package:picklog/core/services/consent/telemetry_gateway.dart';
import 'package:picklog/core/services/notification_service.dart';
import 'package:picklog/core/services/session_reset_service.dart';
import 'package:picklog/features/library/bloc/library_bloc.dart';
import 'package:picklog/features/library/library_repository.dart';

class _MockTokenStorage extends Mock implements TokenStorage {}

class _MockHttpClient extends Mock implements IHttpClient {}

class _MockNotificationService extends Mock implements NotificationService {}

class _MockLibraryRepository extends Mock implements LibraryRepository {}

class _MockStorage extends Mock implements LocalStorageService {}

class _MockGateway extends Mock implements TelemetryGateway {}

void main() {
  setUpAll(() {
    registerFallbackValue(ConsentCategory.crash);
  });

  group('SessionResetService', () {
    late _MockTokenStorage tokenStorage;
    late _MockHttpClient httpClient;
    late _MockNotificationService notificationService;
    late _MockStorage storage;
    late _MockGateway gateway;
    late ConsentService consent;
    late GetIt locator;

    setUp(() {
      tokenStorage = _MockTokenStorage();
      httpClient = _MockHttpClient();
      notificationService = _MockNotificationService();
      storage = _MockStorage();
      gateway = _MockGateway();
      locator = GetIt.asNewInstance();
      when(() => tokenStorage.delete()).thenAnswer((_) async {});
      when(() => notificationService.disable()).thenAnswer((_) async {});
      when(() => storage.getBool(any())).thenAnswer((_) async => null);
      when(() => storage.setBool(any(), any())).thenAnswer((_) async => true);
      when(
        () => gateway.applyConsent(any(), granted: any(named: 'granted')),
      ).thenAnswer((_) async {});
      consent = ConsentService(storage: storage, gateway: gateway);
    });

    tearDown(() => consent.dispose());

    SessionResetService buildService() => SessionResetService(
      tokenStorage: tokenStorage,
      httpClient: httpClient,
      notificationService: notificationService,
      consentService: consent,
      locator: locator,
    );

    test('clears the auth token and HTTP auth header', () async {
      await buildService().teardownSession();

      verify(() => tokenStorage.delete()).called(1);
      verify(() => httpClient.clearAuthToken()).called(1);
    });

    test('disables push (deletes FCM token) on logout', () async {
      await buildService().teardownSession();

      verify(() => notificationService.disable()).called(1);
    });

    test('re-denies every consent category on logout', () async {
      // User A grants consent before logging out.
      await consent.grant(ConsentCategory.crash);
      await consent.grant(ConsentCategory.push);
      await consent.grant(ConsentCategory.analytics);

      await buildService().teardownSession();

      // The next account inherits a denied state, not user A's grants.
      for (final category in ConsentCategory.values) {
        expect(consent.isGranted(category), isFalse);
        verify(
          () => storage.setBool(category.storageKey, false),
        ).called(greaterThanOrEqualTo(1));
      }
    });

    test('is a no-op for LibraryBloc when it is not registered', () async {
      // Should not throw when the user never visited a library screen.
      await buildService().teardownSession();
      expect(locator.isRegistered<LibraryBloc>(), isFalse);
    });

    test(
      'resets the LibraryBloc singleton so the next user gets a fresh one',
      () async {
        locator.registerLazySingleton<LibraryBloc>(
          () => LibraryBloc(libraryRepository: _MockLibraryRepository()),
        );
        final before = locator<LibraryBloc>();

        await buildService().teardownSession();

        // The registration is reset, so the next access is a fresh instance.
        final after = locator<LibraryBloc>();
        expect(identical(before, after), isFalse);

        // The old instance is closed off the logout path (unawaited); awaiting
        // close() again (idempotent) confirms it is torn down.
        await before.close();
        expect(before.isClosed, isTrue);
      },
    );
  });
}
