import 'dart:async';

import 'package:picklog/core/data/services/storage/local_storage_service.dart';
import 'package:picklog/core/services/consent/consent_category.dart';
import 'package:picklog/core/services/consent/telemetry_gateway.dart';

/// Central gate for all telemetry/marketing data collection (LGPD).
///
/// Consent is persisted per [ConsentCategory] and **defaults to denied** until
/// the user explicitly grants it. Granting/revoking immediately applies the
/// corresponding collector side-effect through the [TelemetryGateway] (e.g.
/// enabling Crashlytics, deleting the FCM token), so revocation actually stops
/// collection rather than only hiding a setting.
///
/// This is the mechanism only — the consent UI (#19) consumes this service to
/// flip categories. The service installs no UI and reads no policy text.
class ConsentService {
  ConsentService({
    required LocalStorageService storage,
    required TelemetryGateway gateway,
  }) : _storage = storage,
       _gateway = gateway;

  final LocalStorageService _storage;
  final TelemetryGateway _gateway;

  /// Storage key for the "user has made an explicit consent choice" flag.
  static const String answeredStorageKey = 'consent_answered';

  final Map<ConsentCategory, bool> _granted = {
    for (final category in ConsentCategory.values) category: false,
  };

  bool _answered = false;

  final _changes = StreamController<ConsentCategory>.broadcast();

  /// Emits a category whenever its consent flag changes.
  Stream<ConsentCategory> get changes => _changes.stream;

  /// Loads persisted consent and applies each collector's current state.
  ///
  /// Must be called during startup before any collector is touched. Defaults
  /// every category to denied when storage has no value, then pushes that state
  /// to the gateway so a fresh install collects nothing.
  Future<void> load() async {
    _answered = await _readAnswered();
    for (final category in ConsentCategory.values) {
      final stored = await _readStored(category);
      _granted[category] = stored;
      await _gateway.applyConsent(category, granted: stored);
    }
  }

  /// Whether the user has already made an explicit consent choice. Defaults to
  /// `false` so a fresh install shows the first-run consent prompt; flips to
  /// `true` via [markAnswered] once the user accepts, rejects, or customizes,
  /// so the prompt is not shown again.
  bool get hasAnswered => _answered;

  /// Persists that the user has made an explicit consent choice, so the
  /// first-run prompt is not shown again. Idempotent.
  Future<void> markAnswered() async {
    if (_answered) return;
    _answered = true;
    await _storage.setBool(answeredStorageKey, true);
  }

  /// Whether the user has granted consent for [category]. Denied by default.
  bool isGranted(ConsentCategory category) => _granted[category] ?? false;

  /// Grants consent for [category], persists it, and enables its collector.
  Future<void> grant(ConsentCategory category) => _set(category, true);

  /// Revokes consent for [category], persists it, and stops/clears its
  /// collector (e.g. disables Crashlytics, deletes the FCM token).
  Future<void> revoke(ConsentCategory category) => _set(category, false);

  /// Revokes consent for every category, persisting denied and tearing down
  /// each collector. Called on logout/session teardown so a shared device does
  /// not leak the previous account's consent to the next account (which would
  /// otherwise inherit it and start collecting). The next account starts
  /// denied and must grant again.
  Future<void> revokeAll() async {
    for (final category in ConsentCategory.values) {
      await _set(category, false);
    }
    // Clear the "answered" flag too: the next account on a shared device must
    // see the first-run consent prompt again rather than inheriting this one.
    _answered = false;
    await _storage.remove(answeredStorageKey);
    // Signal listeners so the cubit re-reads [hasAnswered] and re-shows the
    // first-run banner. The per-category [_set] calls above stay silent when a
    // category was already denied, so without this a same-session logout +
    // re-login would leave the banner hidden for the next account.
    _changes.add(ConsentCategory.values.first);
  }

  Future<void> _set(ConsentCategory category, bool granted) async {
    if (_granted[category] == granted) return;
    _granted[category] = granted;
    await _storage.setBool(category.storageKey, granted);
    await _gateway.applyConsent(category, granted: granted);
    _changes.add(category);
  }

  /// Forwards a Flutter framework error to the gateway only when crash consent
  /// is granted; otherwise it is dropped. Wired to `FlutterError.onError`.
  Future<void> reportFlutterError(FlutterErrorDetailsLike details) async {
    if (!isGranted(ConsentCategory.crash)) return;
    await _gateway.recordFlutterError(details);
  }

  /// Forwards an uncaught platform error to the gateway only when crash consent
  /// is granted; otherwise it is dropped. Wired to `PlatformDispatcher.onError`.
  Future<void> reportError(
    Object error,
    StackTrace stack, {
    bool fatal = false,
  }) async {
    if (!isGranted(ConsentCategory.crash)) return;
    await _gateway.recordError(error, stack, fatal: fatal);
  }

  Future<bool> _readStored(ConsentCategory category) async {
    try {
      return await _storage.getBool(category.storageKey) ?? false;
    } catch (_) {
      // Storage can be unavailable (locked keystore, tests); fail closed.
      return false;
    }
  }

  Future<bool> _readAnswered() async {
    try {
      return await _storage.getBool(answeredStorageKey) ?? false;
    } catch (_) {
      // Fail open to "not answered" so the prompt is shown rather than skipped.
      return false;
    }
  }

  Future<void> dispose() => _changes.close();
}
