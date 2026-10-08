import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picklog/core/domain/models/app_failure.dart';
import 'package:picklog/features/games/catalog_filters.dart';
import 'package:picklog/features/games/discovery_game_model.dart';
import 'package:picklog/features/games/i_games_repository.dart';

abstract class ExploreEvent extends Equatable {
  const ExploreEvent();

  @override
  List<Object?> get props => [];
}

/// Loads the first page with the current filters.
class ExploreLoadRequested extends ExploreEvent {
  const ExploreLoadRequested();
}

/// Applies new filters and reloads from the first page.
class ExploreFiltersChanged extends ExploreEvent {
  const ExploreFiltersChanged(this.filters);

  final ExploreFilters filters;

  @override
  List<Object?> get props => [filters];
}

class ExploreLoadMore extends ExploreEvent {
  const ExploreLoadMore();
}

enum ExploreStatus { initial, loading, loadingMore, success, failure }

class ExploreState extends Equatable {
  const ExploreState({
    this.status = ExploreStatus.initial,
    this.filters = const ExploreFilters(),
    this.games = const [],
    this.hasMore = false,
    this.nextOffset = 0,
    this.errorKind,
  });

  final ExploreStatus status;
  final ExploreFilters filters;
  final List<DiscoveryGame> games;
  final bool hasMore;
  final int nextOffset;
  final AppErrorKind? errorKind;

  bool get isLoading => status == ExploreStatus.loading;
  bool get isLoadingMore => status == ExploreStatus.loadingMore;
  bool get hasGames => games.isNotEmpty;
  bool get canLoadMore => hasMore && !isLoading && !isLoadingMore;
  bool get loadMoreFailed =>
      errorKind != null && status == ExploreStatus.success;

  ExploreState copyWith({
    ExploreStatus? status,
    ExploreFilters? filters,
    List<DiscoveryGame>? games,
    bool? hasMore,
    int? nextOffset,
    AppErrorKind? errorKind,
  }) {
    return ExploreState(
      status: status ?? this.status,
      filters: filters ?? this.filters,
      games: games ?? this.games,
      hasMore: hasMore ?? this.hasMore,
      nextOffset: nextOffset ?? this.nextOffset,
      errorKind: errorKind,
    );
  }

  @override
  List<Object?> get props => [
    status,
    filters,
    games,
    hasMore,
    nextOffset,
    errorKind,
  ];
}

/// Catalog explorer over `GET /games/explore` with infinite scroll.
class ExploreBloc extends Bloc<ExploreEvent, ExploreState> {
  ExploreBloc({required IGamesRepository gamesRepository})
    : _repository = gamesRepository,
      super(const ExploreState()) {
    on<ExploreLoadRequested>(_onLoad);
    on<ExploreFiltersChanged>(_onFiltersChanged);
    on<ExploreLoadMore>(_onLoadMore);
  }

  final IGamesRepository _repository;

  static const int pageSize = 30;

  /// The API rejects offsets beyond this.
  static const int maxOffset = 10000;

  int _generation = 0;

  Future<void> _onLoad(
    ExploreLoadRequested event,
    Emitter<ExploreState> emit,
  ) => _loadFirstPage(emit);

  Future<void> _onFiltersChanged(
    ExploreFiltersChanged event,
    Emitter<ExploreState> emit,
  ) async {
    if (event.filters == state.filters &&
        state.status != ExploreStatus.initial) {
      return;
    }
    emit(state.copyWith(filters: event.filters, status: state.status));
    await _loadFirstPage(emit);
  }

  Future<void> _loadFirstPage(Emitter<ExploreState> emit) async {
    final generation = ++_generation;
    final filters = state.filters;
    emit(
      state.copyWith(
        status: ExploreStatus.loading,
        games: const [],
        hasMore: false,
        nextOffset: 0,
      ),
    );
    try {
      final response = await _repository.exploreGames(filters, limit: pageSize);
      if (generation != _generation) return;
      emit(
        state.copyWith(
          status: ExploreStatus.success,
          games: response.games,
          hasMore: response.hasMore && pageSize <= maxOffset,
          nextOffset: pageSize,
        ),
      );
    } catch (e) {
      if (generation != _generation) return;
      emit(
        state.copyWith(
          status: ExploreStatus.failure,
          errorKind: AppErrorKind.from(e),
        ),
      );
    }
  }

  Future<void> _onLoadMore(
    ExploreLoadMore event,
    Emitter<ExploreState> emit,
  ) async {
    if (!state.canLoadMore) return;
    final offset = state.nextOffset;
    if (offset > maxOffset) {
      emit(state.copyWith(hasMore: false));
      return;
    }
    final generation = _generation;
    emit(state.copyWith(status: ExploreStatus.loadingMore));
    try {
      final response = await _repository.exploreGames(
        state.filters,
        limit: pageSize,
        offset: offset,
      );
      if (generation != _generation) return;
      final seen = {for (final g in state.games) g.id};
      final next = offset + pageSize;
      emit(
        state.copyWith(
          status: ExploreStatus.success,
          games: [
            ...state.games,
            ...response.games.where((g) => !seen.contains(g.id)),
          ],
          hasMore: response.hasMore && next <= maxOffset,
          nextOffset: next,
        ),
      );
    } catch (e) {
      if (generation != _generation) return;
      emit(
        state.copyWith(
          status: ExploreStatus.success,
          errorKind: AppErrorKind.from(e),
        ),
      );
    }
  }
}
