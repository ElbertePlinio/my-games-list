import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picklog/features/ai/ai_models.dart';
import 'package:picklog/features/ai/ai_repository.dart';

/// Longest prompt the API accepts.
const int kDiscoverPromptMax = 300;

enum DiscoverStatus { initial, loading, success, failure }

class DiscoverState extends Equatable {
  const DiscoverState({
    this.status = DiscoverStatus.initial,
    this.prompt = '',
    this.picks = const [],
    this.remainingToday,
    this.errorKind,
  });

  final DiscoverStatus status;

  /// The prompt used for the current results.
  final String prompt;
  final List<DiscoverPick> picks;
  final int? remainingToday;
  final AiErrorKind? errorKind;

  bool get isLoading => status == DiscoverStatus.loading;

  DiscoverState copyWith({
    DiscoverStatus? status,
    String? prompt,
    List<DiscoverPick>? picks,
    int? remainingToday,
    AiErrorKind? errorKind,
  }) {
    return DiscoverState(
      status: status ?? this.status,
      prompt: prompt ?? this.prompt,
      picks: picks ?? this.picks,
      remainingToday: remainingToday ?? this.remainingToday,
      errorKind: errorKind,
    );
  }

  @override
  List<Object?> get props => [status, prompt, picks, remainingToday, errorKind];
}

/// Prompt-driven discovery of games the user does not own yet.
class DiscoverCubit extends Cubit<DiscoverState> {
  DiscoverCubit({required AiRepository repository})
    : _repository = repository,
      super(const DiscoverState());

  final AiRepository _repository;

  Future<void> discover(String prompt) async {
    if (state.isLoading) return;
    final trimmed = prompt.trim();
    final bounded = trimmed.length > kDiscoverPromptMax
        ? trimmed.substring(0, kDiscoverPromptMax)
        : trimmed;
    emit(state.copyWith(status: DiscoverStatus.loading, prompt: bounded));
    try {
      final result = await _repository.discover(prompt: bounded);
      if (isClosed) return;
      emit(
        state.copyWith(
          status: DiscoverStatus.success,
          picks: result.picks,
          remainingToday: result.remainingToday,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: DiscoverStatus.failure,
          errorKind: AiErrorKind.from(e),
        ),
      );
    }
  }

  /// Runs the last prompt again.
  Future<void> retry() => discover(state.prompt);
}
