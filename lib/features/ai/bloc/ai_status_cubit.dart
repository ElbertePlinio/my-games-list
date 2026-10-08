import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picklog/features/ai/ai_models.dart';
import 'package:picklog/features/ai/ai_repository.dart';

enum AiStatusLoad { initial, loading, ready, failure }

class AiStatusState extends Equatable {
  const AiStatusState({
    this.load = AiStatusLoad.initial,
    this.status,
    this.isSavingConsent = false,
    this.consentErrorKind,
  });

  final AiStatusLoad load;
  final AiStatus? status;
  final bool isSavingConsent;

  /// Set when the last consent change failed.
  final AiErrorKind? consentErrorKind;

  bool get isEnabled => status?.enabled ?? false;
  bool get isConsented => status?.consented ?? false;

  AiStatusState copyWith({
    AiStatusLoad? load,
    AiStatus? status,
    bool? isSavingConsent,
    AiErrorKind? consentErrorKind,
  }) {
    return AiStatusState(
      load: load ?? this.load,
      status: status ?? this.status,
      isSavingConsent: isSavingConsent ?? this.isSavingConsent,
      consentErrorKind: consentErrorKind,
    );
  }

  @override
  List<Object?> get props => [load, status, isSavingConsent, consentErrorKind];
}

/// AI availability, consent and daily usage for the signed-in user.
///
/// Route-scoped: home, settings and each AI screen get their own instance.
class AiStatusCubit extends Cubit<AiStatusState> {
  AiStatusCubit({required AiRepository repository})
    : _repository = repository,
      super(const AiStatusState());

  final AiRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(load: AiStatusLoad.loading));
    try {
      final status = await _repository.getStatus();
      if (isClosed) return;
      emit(state.copyWith(load: AiStatusLoad.ready, status: status));
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(load: AiStatusLoad.failure));
    }
  }

  /// Grants or revokes consent. Returns true when the server accepted it.
  Future<bool> setConsent(bool granted) async {
    if (state.isSavingConsent) return false;
    emit(state.copyWith(isSavingConsent: true));
    try {
      final result = await _repository.setConsent(granted: granted);
      if (isClosed) return result.consented == granted;
      final current = state.status;
      emit(
        state.copyWith(
          isSavingConsent: false,
          status: current?.copyWith(consented: result.consented),
        ),
      );
      return result.consented == granted;
    } catch (e) {
      if (isClosed) return false;
      emit(
        state.copyWith(
          isSavingConsent: false,
          consentErrorKind: AiErrorKind.from(e),
        ),
      );
      return false;
    }
  }

  /// Marks consent as missing after the server answered consent_required.
  void markConsentMissing() {
    final current = state.status;
    if (current == null || !current.consented) return;
    emit(state.copyWith(status: current.copyWith(consented: false)));
  }

  /// Updates the usage counter from a fresh `remaining_today` value.
  void updateRemaining(int remainingToday) {
    final current = state.status;
    if (current == null) return;
    final used = (current.dailyLimit - remainingToday).clamp(
      0,
      current.dailyLimit,
    );
    emit(state.copyWith(status: current.copyWith(usedToday: used)));
  }
}
