import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:picklog/features/games/bloc/anticipated_games_event.dart';
import 'package:picklog/features/games/bloc/anticipated_games_state.dart';
import 'package:picklog/features/games/i_games_repository.dart';

/// BLoC for managing anticipated games state
class AnticipatedGamesBloc
    extends Bloc<AnticipatedGamesEvent, AnticipatedGamesState> {
  AnticipatedGamesBloc({required IGamesRepository gamesRepository})
    : _gamesRepository = gamesRepository,
      super(const AnticipatedGamesState()) {
    on<AnticipatedGamesLoadRequested>(_onLoadRequested);
    on<AnticipatedGamesRefreshRequested>(_onRefreshRequested);
    on<AnticipatedGamesCountdownTick>(_onCountdownTick);
  }

  final IGamesRepository _gamesRepository;
  Timer? _countdownTimer;

  /// Starts the countdown timer that updates every minute
  void startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => add(const AnticipatedGamesCountdownTick()),
    );
  }

  /// Stops the countdown timer
  void stopCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  Future<void> _onLoadRequested(
    AnticipatedGamesLoadRequested event,
    Emitter<AnticipatedGamesState> emit,
  ) async {
    if (state.status == AnticipatedGamesStatus.loading) return;

    emit(state.copyWith(status: AnticipatedGamesStatus.loading));

    try {
      final games = await _gamesRepository.getAnticipatedGames();
      emit(
        state.copyWith(
          status: AnticipatedGamesStatus.success,
          games: games,
          lastUpdated: DateTime.now(),
        ),
      );
      startCountdownTimer();
    } catch (e) {
      emit(
        state.copyWith(
          status: AnticipatedGamesStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onRefreshRequested(
    AnticipatedGamesRefreshRequested event,
    Emitter<AnticipatedGamesState> emit,
  ) async {
    try {
      final games = await _gamesRepository.getAnticipatedGames();
      emit(
        state.copyWith(
          status: AnticipatedGamesStatus.success,
          games: games,
          lastUpdated: DateTime.now(),
        ),
      );
    } catch (e) {
      // On refresh failure, keep existing games but show error
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  void _onCountdownTick(
    AnticipatedGamesCountdownTick event,
    Emitter<AnticipatedGamesState> emit,
  ) {
    // Increment the countdown tick counter to force UI rebuild
    emit(state.copyWith(countdownTick: state.countdownTick + 1));
  }

  @override
  Future<void> close() {
    stopCountdownTimer();
    return super.close();
  }
}
