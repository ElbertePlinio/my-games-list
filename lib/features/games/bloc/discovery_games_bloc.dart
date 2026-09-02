import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picklog/features/games/i_games_repository.dart';
import 'package:picklog/features/games/bloc/discovery_games_event.dart';
import 'package:picklog/features/games/bloc/discovery_games_state.dart';

class DiscoveryGamesBloc
    extends Bloc<DiscoveryGamesEvent, DiscoveryGamesState> {
  DiscoveryGamesBloc({required IGamesRepository gamesRepository})
    : _gamesRepository = gamesRepository,
      super(const DiscoveryGamesState()) {
    on<DiscoveryGamesLoadRequested>(_onLoadRequested);
    on<DiscoveryGamesLoadMore>(_onLoadMore);
    on<DiscoveryGamesViewModeToggled>(_onViewModeToggled);
    on<DiscoveryGamesRefreshRequested>(_onRefreshRequested);
  }

  final IGamesRepository _gamesRepository;

  static const int _pageSize = 50;
  static const int _maxOffset = 10000;

  Future<void> _onLoadRequested(
    DiscoveryGamesLoadRequested event,
    Emitter<DiscoveryGamesState> emit,
  ) async {
    final type = event.type;

    // Update state for this specific discovery type
    emit(
      state
          .updateTypeState(type, (typeState) {
            return typeState.copyWith(
              status: DiscoveryGamesStatus.loading,
              games: [],
              currentOffset: 0,
              offsetLimitReached: false,
              hasMore: true,
            );
          })
          .copyWith(activeDiscoveryType: type),
    );

    try {
      final response = await _gamesRepository.getDiscoveryGames(
        type,
        limit: _pageSize,
        offset: 0,
      );

      emit(
        state.updateTypeState(type, (typeState) {
          return typeState.copyWith(
            status: DiscoveryGamesStatus.success,
            games: response.games,
            hasMore: response.hasMore,
            currentOffset: _pageSize,
          );
        }),
      );
    } catch (e) {
      emit(
        state.updateTypeState(type, (typeState) {
          return typeState.copyWith(
            status: DiscoveryGamesStatus.failure,
            errorMessage: e.toString(),
          );
        }),
      );
    }
  }

  Future<void> _onLoadMore(
    DiscoveryGamesLoadMore event,
    Emitter<DiscoveryGamesState> emit,
  ) async {
    final type = state.activeDiscoveryType;
    final typeState = state.getStateForType(type);

    // Prevent duplicate loads
    if (typeState.isLoadingMore) {
      return;
    }

    // Check if we have more data to load
    if (!typeState.hasMore || typeState.offsetLimitReached) {
      return;
    }

    // Check if next offset would exceed limit
    final nextOffset = typeState.currentOffset;
    if (nextOffset >= _maxOffset) {
      emit(
        state.updateTypeState(type, (ts) {
          return ts.copyWith(offsetLimitReached: true, hasMore: false);
        }),
      );
      return;
    }

    emit(
      state.updateTypeState(type, (ts) {
        return ts.copyWith(status: DiscoveryGamesStatus.loadingMore);
      }),
    );

    try {
      final response = await _gamesRepository.getDiscoveryGames(
        type,
        limit: _pageSize,
        offset: nextOffset,
      );

      // Calculate if we can load more
      final newOffset = nextOffset + _pageSize;
      final canLoadMoreAfterThis = response.hasMore && newOffset < _maxOffset;

      emit(
        state.updateTypeState(type, (ts) {
          return ts.copyWith(
            status: DiscoveryGamesStatus.success,
            games: [...ts.games, ...response.games],
            hasMore: canLoadMoreAfterThis,
            currentOffset: newOffset,
            offsetLimitReached: newOffset >= _maxOffset,
          );
        }),
      );
    } catch (e) {
      // On error, revert to success status but keep existing games
      emit(
        state.updateTypeState(type, (ts) {
          return ts.copyWith(
            status: DiscoveryGamesStatus.success,
            errorMessage: e.toString(),
          );
        }),
      );
    }
  }

  void _onViewModeToggled(
    DiscoveryGamesViewModeToggled event,
    Emitter<DiscoveryGamesState> emit,
  ) {
    final newMode = state.isGridView
        ? DiscoveryViewMode.list
        : DiscoveryViewMode.grid;
    emit(state.copyWith(viewMode: newMode));
  }

  Future<void> _onRefreshRequested(
    DiscoveryGamesRefreshRequested event,
    Emitter<DiscoveryGamesState> emit,
  ) async {
    final type = state.activeDiscoveryType;

    // Keep existing games visible while refreshing
    emit(
      state.updateTypeState(type, (ts) {
        return ts.copyWith(
          status: DiscoveryGamesStatus.loading,
          currentOffset: 0,
          offsetLimitReached: false,
          hasMore: true,
        );
      }),
    );

    try {
      final response = await _gamesRepository.getDiscoveryGames(
        type,
        limit: _pageSize,
        offset: 0,
      );

      emit(
        state.updateTypeState(type, (ts) {
          return ts.copyWith(
            status: DiscoveryGamesStatus.success,
            games: response.games,
            hasMore: response.hasMore,
            currentOffset: _pageSize,
          );
        }),
      );
    } catch (e) {
      emit(
        state.updateTypeState(type, (ts) {
          return ts.copyWith(
            status: DiscoveryGamesStatus.failure,
            errorMessage: e.toString(),
          );
        }),
      );
    }
  }
}
