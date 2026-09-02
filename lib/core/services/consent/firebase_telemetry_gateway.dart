import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart' show FlutterErrorDetails;

import 'package:picklog/core/services/consent/consent_category.dart';
import 'package:picklog/core/services/consent/telemetry_gateway.dart';
import 'package:picklog/core/services/notification_service.dart';

/// Production [TelemetryGateway] backed by Firebase Crashlytics and the FCM
/// [NotificationService]. Keeps every concrete SDK call behind the gateway
/// interface so [ConsentService] stays Firebase-free and unit-testable.
class FirebaseTelemetryGateway implements TelemetryGateway {
  FirebaseTelemetryGateway({required NotificationService notificationService})
    : _notificationService = notificationService;

  final NotificationService _notificationService;

  // Accessed lazily so construction does not throw in environments where
  // Firebase is not initialized (e.g. tests).
  FirebaseCrashlytics get _crashlytics => FirebaseCrashlytics.instance;

  @override
  Future<void> applyConsent(
    ConsentCategory category, {
    required bool granted,
  }) async {
    switch (category) {
      case ConsentCategory.crash:
        await _crashlytics.setCrashlyticsCollectionEnabled(granted);
        if (!granted) {
          // Drop anything buffered before revocation so it is never sent.
          await _crashlytics.deleteUnsentReports();
        }
      case ConsentCategory.push:
        // Granting push does not register here — registration is contextual and
        // requires authentication (handled by the consent consumers). Revoking
        // tears the collector down immediately.
        if (!granted) {
          await _notificationService.disable();
        }
      case ConsentCategory.analytics:
        // No analytics SDK is shipped yet; this is the wiring seam for #19.
        break;
    }
  }

  @override
  Future<void> recordFlutterError(FlutterErrorDetailsLike details) async {
    if (details is FlutterErrorDetails) {
      await _crashlytics.recordFlutterError(details);
    }
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace stack, {
    bool fatal = false,
  }) async {
    await _crashlytics.recordError(error, stack, fatal: fatal);
  }
}

/// Debug/test gateway that performs no collection. Used so non-production
/// builds and tests never touch Firebase even when consent is granted.
class NoopTelemetryGateway implements TelemetryGateway {
  const NoopTelemetryGateway();

  @override
  Future<void> applyConsent(
    ConsentCategory category, {
    required bool granted,
  }) async {}

  @override
  Future<void> recordFlutterError(FlutterErrorDetailsLike details) async {}

  @override
  Future<void> recordError(
    Object error,
    StackTrace stack, {
    bool fatal = false,
  }) async {}
}
