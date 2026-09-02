import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      emit(const GameSearchState());
      return;
    }

    // If query is the same as current, do nothing
    if (query == state.query) {
      return;
    }

    // Start fresh search. Filters are reset because the available facets are
    // derived from results, which a new query replaces.
    emit(
      state.copyWith(
        status: GameSearchStatus.loading,
        query: query,
        games: [],
        currentOffset: 0,
        offsetLimitReached: false,
        filters: const GameSearchFilters(),
      ),
    );

    try {
      final response = await _gamesRepository.searchGames(
        query,
        limit: _pageSize,
        offset: 0,
      );

      emit(
        state.copyWith(
          status: GameSearchStatus.success,
          games: response.games,
          hasMore: response.hasMore,
          currentOffset: _pageSize,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: GameSearchStatus.failure,
          errorMessage: e.toString(),
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

    emit(state.copyWith(status: GameSearchStatus.loadingMore));

    try {
      final response = await _gamesRepository.searchGames(
        state.query,
        limit: _pageSize,
        offset: nextOffset,
      );

      emit(
        state.copyWith(
          status: GameSearchStatus.success,
          games: [...state.games, ...response.games],
          hasMore: response.hasMore && (nextOffset + _pageSize) < _maxOffset,
          currentOffset: nextOffset + _pageSize,
        ),
      );
    } catch (e) {
      // Keep existing games, just show error
      emit(
        state.copyWith(
          status: GameSearchStatus.success,
          errorMessage: 'Failed to load more results',
        ),
      );
    }
  }

  void _onClear(GameSearchClear event, Emitter<GameSearchState> emit) {
    emit(const GameSearchState());
  }

  void _onFiltersChanged(
    GameSearchFiltersChanged event,
    Emitter<GameSearchState> emit,
  ) {
    emit(state.copyWith(filters: event.filters));
  }

  void _onFiltersCleared(
    GameSearchFiltersCleared event,
    Emitter<GameSearchState> emit,
  ) {
    emit(state.copyWith(filters: const GameSearchFilters()));
  }
}
