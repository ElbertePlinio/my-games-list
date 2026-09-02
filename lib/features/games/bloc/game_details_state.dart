import 'package:equatable/equatable.dart';
import 'package:picklog/features/games/game_detail_model.dart';

/// Status of the game details loading operation.
enum GameDetailsStatus {
  /// Initial state before any action.
  initial,

  /// Currently loading game details.
  loading,

  /// Successfully loaded game details.
  success,

  /// Failed to load game details.
  failure,
}

/// State for the game details BLoC.
class GameDetailsState extends Equatable {
  const GameDetailsState({
    this.status = GameDetailsStatus.initial,
    this.game,
    this.errorMessage,
  });

  final GameDetailsStatus status;
  final GameDetail? game;
  final String? errorMessage;

  /// Creates a copy of this state with the given fields replaced.
  GameDetailsState copyWith({
    GameDetailsStatus? status,
    GameDetail? game,
    String? errorMessage,
  }) {
    return GameDetailsState(
      status: status ?? this.status,
      game: game ?? this.game,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, game, errorMessage];
}
