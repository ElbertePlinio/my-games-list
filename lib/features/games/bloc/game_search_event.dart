import 'package:equatable/equatable.dart';
import 'package:picklog/features/games/bloc/game_search_filters.dart';

abstract class GameSearchEvent extends Equatable {
  const GameSearchEvent();

  @override
  List<Object?> get props => [];
}

class GameSearchQueryChanged extends GameSearchEvent {
  const GameSearchQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

class GameSearchLoadMore extends GameSearchEvent {
  const GameSearchLoadMore();
}

/// Retries the failed request: the first page, or the next page after a
/// failed "load more".
class GameSearchRetryRequested extends GameSearchEvent {
  const GameSearchRetryRequested();
}

class GameSearchClear extends GameSearchEvent {
  const GameSearchClear();
}

/// Applies new client-side filters/sort to the current results.
class GameSearchFiltersChanged extends GameSearchEvent {
  const GameSearchFiltersChanged(this.filters);

  final GameSearchFilters filters;

  @override
  List<Object?> get props => [filters];
}

/// Removes all active filters and resets sort to relevance.
class GameSearchFiltersCleared extends GameSearchEvent {
  const GameSearchFiltersCleared();
}
