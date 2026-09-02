import 'package:picklog/core/data/services/storage/local_storage_service.dart';

/// Persists the one-time "first run onboarding" flag.
///
/// Onboarding must be shown exactly once per install. Wrapping the storage
/// key here keeps the splash/router flow agnostic of the key name and makes
/// the completion check trivially mockable in tests.
class OnboardingService {
  OnboardingService(this._storageService);

  final LocalStorageService _storageService;

  static const String _completedKey = 'onboarding_completed';

  /// Whether the user has already finished (or skipped) onboarding.
  ///
  /// Defaults to `false` so a fresh install — or any read failure — shows the
  /// welcome flow rather than silently skipping it.
  Future<bool> isCompleted() async {
    try {
      return await _storageService.getBool(_completedKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Marks onboarding as done so it is never shown again on this install.
  Future<void> markCompleted() async {
    await _storageService.setBool(_completedKey, true);
  }
}
