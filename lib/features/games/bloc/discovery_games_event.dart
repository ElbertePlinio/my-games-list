import 'package:equatable/equatable.dart';
import 'package:picklog/features/games/discovery_game_model.dart';

abstract class DiscoveryGamesEvent extends Equatable {
  const DiscoveryGamesEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load initial discovery games
class DiscoveryGamesLoadRequested extends DiscoveryGamesEvent {
  const DiscoveryGamesLoadRequested(this.type);

  final DiscoveryType type;

  @override
  List<Object?> get props => [type];
}

/// Event to load more games for infinite scroll
class DiscoveryGamesLoadMore extends DiscoveryGamesEvent {
  const DiscoveryGamesLoadMore();
}

/// Event to toggle between grid and list view
class DiscoveryGamesViewModeToggled extends DiscoveryGamesEvent {
  const DiscoveryGamesViewModeToggled();
}

/// Event to refresh the games list
class DiscoveryGamesRefreshRequested extends DiscoveryGamesEvent {
  const DiscoveryGamesRefreshRequested();
}
