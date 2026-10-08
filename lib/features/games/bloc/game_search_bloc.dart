import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picklog/core/domain/models/app_failure.dart';
import 'package:picklog/features/games/i_games_repository.dart';
import 'package:picklog/features/games/bloc/game_search_event.dart';
import 'package:picklog/features/games/bloc/game_search_filters.dart';
import 'package:picklog/features/games/bloc/game_search_state.dart';
import 'package:stream_transform/stream_transform.dart';

/// Debounce transformer for search events
EventTransformer<GameSearchQueryChanged> debounce(Duration duration) {
  return (events, mapper) => events.debounce(duration).switchMap(mapper);
}

class GameSearchBloc extends Bloc<GameSearchEvent, GameSearchState> {
  GameSearchBloc({required IGamesRepository gamesRepository})
    : _gamesRepository = gamesRepository,
      super(const GameSearchState()) {
    on<GameSearchQueryChanged>(
      _onQueryChanged,
      transformer: debounce(_debounceDuration),
    );
    on<GameSearchLoadMore>(_onLoadMore);
    on<GameSearchRetryRequested>(_onRetryRequested);
    on<GameSearchClear>(_onClear);
    on<GameSearchFiltersChanged>(_onFiltersChanged);
    on<GameSearchFiltersCleared>(_onFiltersCleared);
  }

  final IGamesRepository _gamesRepository;

  static const int _pageSize = 20;
  static const int _maxOffset = 10000;
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  Future<void> _onQueryChanged(
    GameSearchQueryChanged event,
    Emitter<GameSearchState> emit,
  ) async {
    final query = event.query.trim();

    if (query.isEmpty) {
      _generation++;
      emit(GameSearchState(filters: state.filters));
      return;
    }

    // If query is the same as current, do nothing
    if (query == state.query) {
      return;
    }

    await _search(query, emit);
  }

  /// Bumped on every first-page search so an older response never replaces
  /// a newer query or filter set.
  int _generation = 0;

  Future<void> _search(String query, Emitter<GameSearchState> emit) async {
    // Start a fresh search. Filters stay: the API applies them to any query.
    final generation = ++_generation;
    emit(
      state.copyWith(
        status: GameSearchStatus.loading,
        query: query,
        games: [],
        currentOffset: 0,
        offsetLimitReached: false,
      ),
    );

    try {
      final response = await _gamesRepository.searchGames(
        query,
        limit: _pageSize,
        offset: 0,
        filters: state.filters.catalog,
      );
      if (generation != _generation) return;

      emit(
        state.copyWith(
          status: GameSearchStatus.success,
          games: response.games,
          hasMore: response.hasMore,
          currentOffset: _pageSize,
        ),
      );
    } catch (e) {
      if (generation != _generation) return;
      emit(
        state.copyWith(
          status: GameSearchStatus.failure,
          errorKind: AppErrorKind.from(e),
        ),
      );
    }
  }

  Future<void> _onLoadMore(
    GameSearchLoadMore event,
    Emitter<GameSearchState> emit,
  ) async {
    // Prevent duplicate loads
    if (state.isLoadingMore || !state.canLoadMore) {
      return;
    }

    // Check if next offset would exceed limit
    final nextOffset = state.currentOffset;
    if (nextOffset >= _maxOffset) {
      emit(state.copyWith(offsetLimitReached: true, hasMore: false));
      return;
    }

    final generation = _generation;
    emit(state.copyWith(status: GameSearchStatus.loadingMore));

    try {
      final response = await _gamesRepository.searchGames(
        state.query,
        limit: _pageSize,
        offset: nextOffset,
        filters: state.filters.catalog,
      );
      if (generation != _generation) return;

      emit(
        state.copyWith(
          status: GameSearchStatus.success,
          games: [...state.games, ...response.games],
          hasMore: response.hasMore && (nextOffset + _pageSize) < _maxOffset,
          currentOffset: nextOffset + _pageSize,
        ),
      );
    } catch (e) {
      if (generation != _generation) return;
      // Keep existing games, just show error
      emit(
        state.copyWith(
          status: GameSearchStatus.success,
          errorKind: AppErrorKind.from(e),
        ),
      );
    }
  }

  Future<void> _onRetryRequested(
    GameSearchRetryRequested event,
    Emitter<GameSearchState> emit,
  ) async {
    if (state.query.isEmpty) return;
    if (state.status == GameSearchStatus.failure) {
      await _search(state.query, emit);
    } else if (state.loadMoreFailed) {
      await _onLoadMore(const GameSearchLoadMore(), emit);
    }
  }

  void _onClear(GameSearchClear event, Emitter<GameSearchState> emit) {
    // Clearing the text keeps the chosen filters for the next query.
    _generation++;
    emit(GameSearchState(filters: state.filters));
  }

  Future<void> _onFiltersChanged(
    GameSearchFiltersChanged event,
    Emitter<GameSearchState> emit,
  ) => _applyFilters(event.filters, emit);

  Future<void> _onFiltersCleared(
    GameSearchFiltersCleared event,
    Emitter<GameSearchState> emit,
  ) => _applyFilters(const GameSearchFilters(), emit);

  /// A sort change reorders the loaded results. A catalog filter change runs
  /// the query again because the API applies those filters.
  Future<void> _applyFilters(
    GameSearchFilters filters,
    Emitter<GameSearchState> emit,
  ) async {
    final catalogChanged = filters.catalog != state.filters.catalog;
    emit(state.copyWith(filters: filters));
    if (catalogChanged && state.query.isNotEmpty) {
      await _search(state.query, emit);
    }
  }
}
