import 'package:get_it/get_it.dart';
import 'package:picklog/core/data/services/http/dio_http_client.dart';
import 'package:picklog/core/data/services/http/i_http_client.dart';
import 'package:picklog/core/data/services/storage/local_storage_service.dart';
import 'package:picklog/core/data/services/storage/secure_token_storage.dart';
import 'package:picklog/core/data/services/storage/shared_preferences_service.dart';
import 'package:picklog/core/data/services/storage/token_storage.dart';
import 'package:picklog/core/services/consent/consent_service.dart';
import 'package:picklog/core/services/consent/firebase_telemetry_gateway.dart';
import 'package:picklog/core/services/consent/push_registration_coordinator.dart';
import 'package:picklog/core/services/consent/telemetry_gateway.dart';
import 'package:picklog/core/services/notification_service.dart';
import 'package:picklog/core/services/session_reset_service.dart';
import 'package:picklog/core/utils/env.dart';
import 'package:picklog/features/auth/bloc/auth_bloc.dart';
import 'package:picklog/features/auth/bloc/auth_event.dart';
import 'package:picklog/features/auth/bloc/auth_state.dart';
import 'package:picklog/features/consent/bloc/consent_cubit.dart';
import 'package:picklog/features/settings/bloc/settings_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global service locator instance
final GetIt sl = GetIt.instance;

/// Sets up global dependencies for the application.
/// This should be called during app initialization.
/// Only registers dependencies that are needed globally throughout the app.
/// Module-specific dependencies should be registered lazily when modules are loaded.
Future<void> setupServiceLocator() async {
  // Register core services first
  await _registerCoreServices();

  // Restore authentication token if it exists
  await _restoreAuthToken();

  // Register global BLoCs (non-auth)
  _registerGlobalBlocs();

  // Load persisted consent and apply each collector's state. Runs after the
  // gateway + services are registered and BEFORE the app starts collecting, so
  // a fresh install (all categories denied) collects nothing.
  await sl<ConsentService>().load();
}

/// Registers core services like storage and HTTP client.
/// These are global dependencies needed throughout the app.
Future<void> _registerCoreServices() async {
  // Register SharedPreferences instance as singleton
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(sharedPreferences);

  // Register storage service implementation
  sl.registerSingleton<LocalStorageService>(
    SharedPreferencesService(sharedPreferences),
  );

  // Register secure storage for the auth token (Keychain/Keystore on mobile)
  sl.registerLazySingleton<TokenStorage>(() => SecureTokenStorage());

  // Register HTTP client as singleton (used globally for all API calls)
  sl.registerLazySingleton<IHttpClient>(() => DioHttpClient());

  // Register NotificationService as lazy singleton
  sl.registerLazySingleton<NotificationService>(
    () => NotificationService(httpClient: sl<IHttpClient>()),
  );

  // Telemetry collectors live behind a gateway so consent logic stays testable
  // and Firebase-free. Only production builds touch the real SDKs; everything
  // else (staging, debug, tests) uses a no-op so nothing collects.
  sl.registerLazySingleton<TelemetryGateway>(
    () => Env.isProduction
        ? FirebaseTelemetryGateway(
            notificationService: sl<NotificationService>(),
          )
        : const NoopTelemetryGateway(),
  );

  // Consent gate (LGPD). Defaults every category to denied until granted.
  sl.registerLazySingleton<ConsentService>(
    () => ConsentService(
      storage: sl<LocalStorageService>(),
      gateway: sl<TelemetryGateway>(),
    ),
  );

  // Session teardown (logout) — clears token, re-denies every consent category
  // so the next account starts denied, and resets per-user singletons.
  sl.registerLazySingleton<SessionResetService>(
    () => SessionResetService(
      tokenStorage: sl<TokenStorage>(),
      httpClient: sl<IHttpClient>(),
      notificationService: sl<NotificationService>(),
      consentService: sl<ConsentService>(),
    ),
  );
}

/// Restores the authentication token from storage to HTTP client if it exists.
/// This ensures that authenticated users stay logged in after app restarts.
Future<void> _restoreAuthToken() async {
  try {
    final token = await sl<TokenStorage>().read();
    if (token != null && token.isNotEmpty) {
      // Set the token in the HTTP client so subsequent requests are authenticated
      sl<IHttpClient>().setAuthToken(token);
    }
  } catch (_) {
    // Secure storage can be unavailable (e.g. tests or a locked keystore);
    // proceed unauthenticated rather than blocking app startup.
  }
}

/// Registers global BLoCs that are needed throughout the app.
/// Auth-specific BLoCs (SignIn/SignUp) are registered modularly in the router.
void _registerGlobalBlocs() {
  // Register AuthBloc as lazy singleton - manages global authentication state
  sl.registerLazySingleton<AuthBloc>(
    () => AuthBloc(sl<LocalStorageService>(), sl<SessionResetService>()),
  );

  // Register SettingsBloc as lazy singleton
  sl.registerLazySingleton<SettingsBloc>(
    () => SettingsBloc(sl<LocalStorageService>()),
  );

  // Consent presentation cubit (lazy singleton): a thin view over ConsentService
  // shared by the first-run banner and the settings toggles so both stay in
  // sync. Built lazily, after ConsentService.load() has run.
  sl.registerLazySingleton<ConsentCubit>(
    () => ConsentCubit(sl<ConsentService>()),
  );

  // Drives FCM registration: only registers the token once push consent is
  // granted AND the user is authenticated, tearing it down otherwise. Fixes
  // the cold-start PATCH /users/me/fcm-token 401.
  sl.registerLazySingleton<PushRegistrationCoordinator>(
    () => PushRegistrationCoordinator(
      consentService: sl<ConsentService>(),
      notificationService: sl<NotificationService>(),
      authBloc: sl<AuthBloc>(),
    ),
  );

  // Auto-logout on 401: an expired/invalid session triggers a single logout
  // through AuthBloc, which runs the full session teardown.
  sl<IHttpClient>().setOnUnauthorized(() {
    final authBloc = sl<AuthBloc>();
    if (authBloc.state is AuthAuthenticated) {
      authBloc.add(const AuthLogoutRequested());
      return true;
    }
    return false;
  });
}

/// Resets all registrations - useful for testing
Future<void> resetServiceLocator() async {
  await sl.reset();
}

/// Helper method to check if all services are ready
Future<void> waitForServicesReady() async {
  await sl.allReady();
}
