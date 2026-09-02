import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:picklog/core/data/services/http/i_http_client.dart';
import 'package:picklog/core/data/services/storage/token_storage.dart';
import 'package:picklog/core/services/consent/consent_service.dart';
import 'package:picklog/core/services/notification_service.dart';
import 'package:picklog/features/library/bloc/library_bloc.dart';

/// Tears down per-user session state on logout so that a subsequent user in the
/// same running app session (common on web/shared devices) cannot see the
/// previous user's cached in-memory data.
///
/// This is the single seam for logout teardown — both the manual logout and a
/// future auto-logout-on-401 (#21) route through [teardownSession]. New per-user
/// singletons should be reset here, not scattered across feature blocs.
class SessionResetService {
  SessionResetService({
    required TokenStorage tokenStorage,
    required IHttpClient httpClient,
    required NotificationService notificationService,
    required ConsentService consentService,
    GetIt? locator,
  }) : _tokenStorage = tokenStorage,
       _httpClient = httpClient,
       _notificationService = notificationService,
       _consent = consentService,
       _locator = locator ?? GetIt.instance;

  final TokenStorage _tokenStorage;
  final IHttpClient _httpClient;
  final NotificationService _notificationService;
  final ConsentService _consent;
  final GetIt _locator;

  /// Clears the auth token everywhere and recreates per-user singletons so the
  /// next user starts from a clean slate. Safe to call on any logout path.
  Future<void> teardownSession() async {
    // Re-deny every consent category so the next account on this (possibly
    // shared) device starts denied instead of inheriting the previous user's
    // grants. Consent keys are global, so without this user B would silently
    // inherit user A's telemetry/push consent. Runs while still authenticated
    // so the push revoke's backend DELETE can succeed. Also re-evaluates the
    // coordinator + error hooks via the changes stream.
    try {
      await _consent.revokeAll();
    } catch (_) {
      // Best-effort; never block logout on consent teardown.
    }

    // Drop the FCM token before the auth header is cleared so the backend
    // DELETE is still authenticated; without this the previous user keeps
    // receiving pushes on a shared device.
    try {
      await _notificationService.disable();
    } catch (_) {
      // Best-effort; never block logout on FCM teardown.
    }

    try {
      await _tokenStorage.delete();
    } catch (_) {
      // Secure storage can be unavailable (locked keystore, web, tests);
      // continue tearing down the rest of the session regardless.
    }
    _httpClient.clearAuthToken();

    // LibraryBloc is a lazy singleton holding the user's library. Reset the
    // registration so the next access recreates a fresh instance. Close the old
    // one off the logout path (unawaited) so a slow in-flight library request
    // can't delay clearing auth state.
    if (_locator.isRegistered<LibraryBloc>()) {
      final library = _locator<LibraryBloc>();
      _locator.resetLazySingleton<LibraryBloc>();
      unawaited(library.close());
    }
  }
}
