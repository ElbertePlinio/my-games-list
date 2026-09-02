import 'dart:async';

import 'package:picklog/core/services/consent/consent_category.dart';
import 'package:picklog/core/services/consent/consent_service.dart';
import 'package:picklog/core/services/notification_service.dart';
import 'package:picklog/features/auth/bloc/auth_bloc.dart';
import 'package:picklog/features/auth/bloc/auth_state.dart';

/// Registers FCM only when push consent is granted **and** the user is
/// authenticated, and tears it down when either condition stops holding.
///
/// This is the seam that fixes the cold-start `PATCH /users/me/fcm-token` 401:
/// the token is never sent on launch. It is sent the moment both gates are
/// satisfied (consent flip while signed in, or sign-in while consent is on).
class PushRegistrationCoordinator {
  PushRegistrationCoordinator({
    required ConsentService consentService,
    required NotificationService notificationService,
    required AuthBloc authBloc,
  }) : _consent = consentService,
       _notifications = notificationService,
       _auth = authBloc;

  final ConsentService _consent;
  final NotificationService _notifications;
  final AuthBloc _auth;

  StreamSubscription<ConsentCategory>? _consentSub;
  StreamSubscription<AuthState>? _authSub;
  bool _registered = false;
  bool _registering = false;

  /// Starts watching consent + auth and reconciles the current state once.
  void start() {
    _consentSub = _consent.changes.listen((category) {
      if (category == ConsentCategory.push) _reconcile();
    });
    _authSub = _auth.stream.listen((_) => _reconcile());
    _reconcile();
  }

  void _reconcile() {
    final shouldRegister =
        _consent.isGranted(ConsentCategory.push) &&
        _auth.state is AuthAuthenticated;

    if (shouldRegister && !_registered) {
      // Mark registered only after setup actually succeeds; if initialize()
      // throws, reset the flag so a later reconcile retries instead of skipping
      // registration forever. Guard against a concurrent in-flight attempt.
      if (_registering) return;
      _registering = true;
      // Future.sync so a synchronous throw from initialize() is captured as a
      // rejected future instead of escaping and leaving _registering stuck.
      Future.sync(_notifications.initialize)
          .then((_) => _registered = true)
          .catchError((_) => _registered = false)
          .whenComplete(() => _registering = false);
    } else if (!shouldRegister && (_registered || _registering)) {
      // Tear down even mid-registration: disable() bumps the service's
      // generation so the in-flight initialize() cancels before it can send the
      // token or attach listeners after consent went off.
      _registered = false;
      _registering = false;
      _notifications.disable().catchError((_) {});
    }
  }

  Future<void> dispose() async {
    await _consentSub?.cancel();
    await _authSub?.cancel();
  }
}
