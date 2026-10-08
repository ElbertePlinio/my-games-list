import 'package:equatable/equatable.dart';
import 'package:picklog/core/domain/models/app_failure.dart';
import 'package:picklog/features/games/bloc/game_search_filters.dart';
import 'package:picklog/features/games/search_game_model.dart';

enum GameSearchStatus { initial, loading, success, failure, loadingMore }

class GameSearchState extends Equatable {
  const GameSearchState({
    this.status = GameSearchStatus.initial,
    this.games = const [],
    this.query = '',
    this.errorKind,
    this.hasMore = true,
    this.currentOffset = 0,
    this.offsetLimitReached = false,
    this.filters = const GameSearchFilters(),
  });

  final GameSearchStatus status;

  /// Results accumulated across pages, in API order.
  final List<SearchGame> games;
  final String query;

  /// Why the last request failed. With [GameSearchStatus.failure] the first
  /// page failed; with results on screen a "load more" failed.
  final AppErrorKind? errorKind;
  final bool hasMore;
  final int currentOffset;
  final bool offsetLimitReached;
  final GameSearchFilters filters;

  /// Results in the chosen order. The API already applied the filters.
  List<SearchGame> get visibleGames => filters.sortGames(games);

  bool get isLoading => status == GameSearchStatus.loading;
  bool get isLoadingMore => status == GameSearchStatus.loadingMore;
  bool get hasGames => games.isNotEmpty;

  /// True when the search succeeded but returned nothing.
  bool get isEmpty => games.isEmpty && status == GameSearchStatus.success;

  /// True when nothing matched and catalog filters are active, so the empty
  /// state can suggest clearing them instead of changing the query.
  bool get isEmptyByFilters => isEmpty && !filters.catalog.isEmpty;

  bool get canLoadMore => hasMore && !offsetLimitReached && !isLoadingMore;

  /// True when results are shown but fetching the next page failed.
  bool get loadMoreFailed =>
      errorKind != null && status == GameSearchStatus.success;
  bool get hasActiveFilters => !filters.isEmpty;

  GameSearchState copyWith({
    GameSearchStatus? status,
    List<SearchGame>? games,
    String? query,
    AppErrorKind? errorKind,
    bool? hasMore,
    int? currentOffset,
    bool? offsetLimitReached,
    GameSearchFilters? filters,
  }) {
    return GameSearchState(
      status: status ?? this.status,
      games: games ?? this.games,
      query: query ?? this.query,
      errorKind: errorKind,
      hasMore: hasMore ?? this.hasMore,
      currentOffset: currentOffset ?? this.currentOffset,
      offsetLimitReached: offsetLimitReached ?? this.offsetLimitReached,
      filters: filters ?? this.filters,
    );
  }

  @override
  List<Object?> get props => [
    status,
    games,
    query,
    errorKind,
    hasMore,
    currentOffset,
    offsetLimitReached,
    filters,
  ];
}
