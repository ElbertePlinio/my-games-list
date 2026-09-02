import 'package:picklog/core/services/consent/consent_category.dart';

/// Mockable seam over the concrete data collectors (Firebase Crashlytics, FCM,
/// analytics). [ConsentService] talks only to this interface so consent logic
/// can be unit-tested without a live Firebase instance.
///
/// Implementations must be idempotent: enabling an already-enabled collector or
/// disabling an already-disabled one is a no-op.
abstract class TelemetryGateway {
  /// Applies the granted/revoked state for a single [category] to its
  /// underlying collector.
  ///
  /// - [ConsentCategory.crash]: toggles Crashlytics collection. When revoked,
  ///   collection stops and any pending reports are cleared.
  /// - [ConsentCategory.push]: when revoked, the FCM token is deleted and the
  ///   backend is notified to drop it. Granting push is intentionally a no-op
  ///   here — registration happens contextually once the user is authenticated
  ///   (see [ConsentService] consumers), not on a cold start.
  /// - [ConsentCategory.analytics]: toggles analytics collection (no-op while
  ///   the app ships no analytics SDK).
  Future<void> applyConsent(ConsentCategory category, {required bool granted});

  /// Reports a Flutter framework error to Crashlytics. Called by the error
  /// hooks installed in `main`; must no-op when crash consent is denied.
  Future<void> recordFlutterError(FlutterErrorDetailsLike details);

  /// Reports an uncaught platform error to Crashlytics. Called by the
  /// `PlatformDispatcher.onError` hook; must no-op when crash consent is denied.
  Future<void> recordError(Object error, StackTrace stack, {bool fatal});
}

/// Minimal structural stand-in for `FlutterErrorDetails` so the gateway
/// interface does not force test doubles to import the Flutter SDK error type.
typedef FlutterErrorDetailsLike = Object;
