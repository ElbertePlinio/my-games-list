import 'package:equatable/equatable.dart';
import 'package:picklog/features/games/discovery_game_model.dart';

enum RecommendationsStatus { initial, loading, success, failure }

class RecommendationsState extends Equatable {
  const RecommendationsState({
    this.status = RecommendationsStatus.initial,
    this.games = const [],
    this.errorMessage,
  });

  final RecommendationsStatus status;
  final List<DiscoveryGame> games;
  final String? errorMessage;

  bool get isLoading => status == RecommendationsStatus.loading;
  bool get hasGames => games.isNotEmpty;

  RecommendationsState copyWith({
    RecommendationsStatus? status,
    List<DiscoveryGame>? games,
    String? errorMessage,
  }) {
    return RecommendationsState(
      status: status ?? this.status,
      games: games ?? this.games,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, games, errorMessage];
}
