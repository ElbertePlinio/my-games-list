import 'package:equatable/equatable.dart';
import 'package:picklog/features/games/anticipated_game_model.dart';

/// Enum representing the status of anticipated games loading
enum AnticipatedGamesStatus { initial, loading, success, failure }

/// State class for anticipated games
class AnticipatedGamesState extends Equatable {
  const AnticipatedGamesState({
    this.status = AnticipatedGamesStatus.initial,
    this.games = const [],
    this.errorMessage,
    this.lastUpdated,
    this.countdownTick = 0,
  });

  final AnticipatedGamesStatus status;
  final List<AnticipatedGame> games;
  final String? errorMessage;
  final DateTime? lastUpdated;

  /// Counter that increments on each countdown tick to force UI rebuild
  final int countdownTick;

  /// Returns true if the state is in loading status
  bool get isLoading => status == AnticipatedGamesStatus.loading;

  /// Returns true if games have been loaded successfully
  bool get hasGames => games.isNotEmpty;

  AnticipatedGamesState copyWith({
    AnticipatedGamesStatus? status,
    List<AnticipatedGame>? games,
    String? errorMessage,
    DateTime? lastUpdated,
    int? countdownTick,
  }) {
    return AnticipatedGamesState(
      status: status ?? this.status,
      games: games ?? this.games,
      errorMessage: errorMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      countdownTick: countdownTick ?? this.countdownTick,
    );
  }

  @override
  List<Object?> get props => [
    status,
    games,
    errorMessage,
    lastUpdated,
    countdownTick,
  ];
}
