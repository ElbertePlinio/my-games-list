import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:picklog/core/services/consent/consent_category.dart';
import 'package:picklog/core/services/consent/consent_service.dart';
import 'package:picklog/features/consent/bloc/consent_state.dart';

/// Thin presentation layer over [ConsentService].
///
/// Keeps consent logic out of widgets: it reflects the service's current state,
/// stays in sync with the service's [ConsentService.changes] stream (so a
/// revoke triggered elsewhere, e.g. logout teardown, updates the UI), and
/// forwards every user action straight to the service, which owns persistence
/// and the collector side-effects.
class ConsentCubit extends Cubit<ConsentState> {
  ConsentCubit(this._service)
    : super(
        ConsentState(
          hasAnswered: _service.hasAnswered,
          granted: _snapshot(_service),
        ),
      ) {
    _subscription = _service.changes.listen((_) => _sync());
  }

  final ConsentService _service;
  late final StreamSubscription<ConsentCategory> _subscription;

  /// True while a user action is persisting. Guards against a second tap
  /// starting an opposite operation mid-write, which (since categories are
  /// mutated sequentially) could otherwise leave a mixed persisted state.
  bool _isSaving = false;

  static Map<ConsentCategory, bool> _snapshot(ConsentService service) => {
    for (final category in ConsentCategory.values)
      category: service.isGranted(category),
  };

  void _sync() {
    emit(
      ConsentState(
        hasAnswered: _service.hasAnswered,
        granted: _snapshot(_service),
        isSaving: _isSaving,
      ),
    );
  }

  /// Runs a persisting action, exposing [ConsentState.isSaving] for its
  /// duration and ignoring re-entrant calls while one is in flight.
  Future<void> _runGuarded(Future<void> Function() action) async {
    if (_isSaving) return;
    _isSaving = true;
    _sync();
    try {
      await action();
      await _service.markAnswered();
    } finally {
      _isSaving = false;
      _sync();
    }
  }

  /// Sets a single category's consent and records that the user has answered.
  /// Used by the settings switches.
  Future<void> setCategory(ConsentCategory category, {required bool granted}) {
    return _runGuarded(() async {
      if (granted) {
        await _service.grant(category);
      } else {
        await _service.revoke(category);
      }
    });
  }

  /// Grants every category (first-run "Accept all").
  Future<void> acceptAll() {
    return _runGuarded(() async {
      for (final category in ConsentCategory.values) {
        await _service.grant(category);
      }
    });
  }

  /// Denies every category (first-run "Reject all"). Collection stays off.
  Future<void> rejectAll() {
    return _runGuarded(() async {
      for (final category in ConsentCategory.values) {
        await _service.revoke(category);
      }
    });
  }

  /// Applies a per-category map from the first-run "Customize" sheet.
  Future<void> applyChoices(Map<ConsentCategory, bool> choices) {
    return _runGuarded(() async {
      for (final entry in choices.entries) {
        if (entry.value) {
          await _service.grant(entry.key);
        } else {
          await _service.revoke(entry.key);
        }
      }
    });
  }

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
