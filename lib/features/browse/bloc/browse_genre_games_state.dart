import 'package:equatable/equatable.dart';
import 'package:picklog/features/games/discovery_game_model.dart';

enum BrowseGenreGamesStatus { initial, loading, success, failure }

class BrowseGenreGamesState extends Equatable {
  const BrowseGenreGamesState({
    this.status = BrowseGenreGamesStatus.initial,
    this.games = const [],
    this.errorMessage,
  });

  final BrowseGenreGamesStatus status;
  final List<DiscoveryGame> games;
  final String? errorMessage;

  bool get isLoading => status == BrowseGenreGamesStatus.loading;
  bool get hasGames => games.isNotEmpty;

  BrowseGenreGamesState copyWith({
    BrowseGenreGamesStatus? status,
    List<DiscoveryGame>? games,
    String? errorMessage,
  }) {
    return BrowseGenreGamesState(
      status: status ?? this.status,
      games: games ?? this.games,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, games, errorMessage];
}
