import 'package:equatable/equatable.dart';
import 'package:picklog/features/games/discovery_game_model.dart';

enum DiscoveryGamesStatus { initial, loading, success, failure, loadingMore }

enum DiscoveryViewMode { grid, list }

/// State for a single discovery type
class DiscoveryTypeState extends Equatable {
  const DiscoveryTypeState({
    this.status = DiscoveryGamesStatus.initial,
    this.games = const [],
    this.errorMessage,
    this.hasMore = true,
    this.currentOffset = 0,
    this.offsetLimitReached = false,
  });

  final DiscoveryGamesStatus status;
  final List<DiscoveryGame> games;
  final String? errorMessage;
  final bool hasMore;
  final int currentOffset;
  final bool offsetLimitReached;

  bool get isLoading => status == DiscoveryGamesStatus.loading;
  bool get isLoadingMore => status == DiscoveryGamesStatus.loadingMore;
  bool get hasGames => games.isNotEmpty;
  bool get isEmpty => games.isEmpty && status == DiscoveryGamesStatus.success;
  bool get canLoadMore => hasMore && !offsetLimitReached && !isLoadingMore;

  DiscoveryTypeState copyWith({
    DiscoveryGamesStatus? status,
    List<DiscoveryGame>? games,
    String? errorMessage,
    bool? hasMore,
    int? currentOffset,
    bool? offsetLimitReached,
  }) {
    return DiscoveryTypeState(
      status: status ?? this.status,
      games: games ?? this.games,
      errorMessage: errorMessage,
      hasMore: hasMore ?? this.hasMore,
      currentOffset: currentOffset ?? this.currentOffset,
      offsetLimitReached: offsetLimitReached ?? this.offsetLimitReached,
    );
  }

  @override
  List<Object?> get props => [
    status,
    games,
    errorMessage,
    hasMore,
    currentOffset,
    offsetLimitReached,
  ];
}

/// Main state that holds state for all discovery types
class DiscoveryGamesState extends Equatable {
  const DiscoveryGamesState({
    this.stateByType = const {},
    this.viewMode = DiscoveryViewMode.grid,
    // Tracks which type load-more/refresh act on (set on load requested).
    this.activeDiscoveryType = DiscoveryType.trending,
  });

  /// State for each discovery type
  final Map<DiscoveryType, DiscoveryTypeState> stateByType;
  final DiscoveryViewMode viewMode;

  /// The discovery type the load-more/refresh events operate on.
  final DiscoveryType activeDiscoveryType;

  /// Get state for a specific discovery type
  DiscoveryTypeState getStateForType(DiscoveryType type) {
    return stateByType[type] ?? const DiscoveryTypeState();
  }

  bool get isGridView => viewMode == DiscoveryViewMode.grid;

  /// Update state for a specific discovery type
  DiscoveryGamesState updateTypeState(
    DiscoveryType type,
    DiscoveryTypeState Function(DiscoveryTypeState) update,
  ) {
    final currentTypeState = getStateForType(type);
    final newTypeState = update(currentTypeState);
    return DiscoveryGamesState(
      stateByType: {...stateByType, type: newTypeState},
      viewMode: viewMode,
      activeDiscoveryType: activeDiscoveryType,
    );
  }

  DiscoveryGamesState copyWith({
    Map<DiscoveryType, DiscoveryTypeState>? stateByType,
    DiscoveryViewMode? viewMode,
    DiscoveryType? activeDiscoveryType,
  }) {
    return DiscoveryGamesState(
      stateByType: stateByType ?? this.stateByType,
      viewMode: viewMode ?? this.viewMode,
      activeDiscoveryType: activeDiscoveryType ?? this.activeDiscoveryType,
    );
  }

  @override
  List<Object?> get props => [stateByType, viewMode, activeDiscoveryType];
}
