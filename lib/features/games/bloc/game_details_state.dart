import 'package:equatable/equatable.dart';
import 'package:picklog/core/domain/models/app_failure.dart';
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
    this.errorKind,
  });

  final GameDetailsStatus status;
  final GameDetail? game;

  /// Why loading failed. The screen maps it to a localized message.
  final AppErrorKind? errorKind;

  /// Creates a copy of this state with the given fields replaced.
  GameDetailsState copyWith({
    GameDetailsStatus? status,
    GameDetail? game,
    AppErrorKind? errorKind,
  }) {
    return GameDetailsState(
      status: status ?? this.status,
      game: game ?? this.game,
      errorKind: errorKind ?? this.errorKind,
    );
  }

  @override
  List<Object?> get props => [status, game, errorKind];
}
