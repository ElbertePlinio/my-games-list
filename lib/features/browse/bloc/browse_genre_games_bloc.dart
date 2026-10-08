import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picklog/core/domain/models/app_failure.dart';
import 'package:picklog/features/browse/bloc/browse_genre_games_event.dart';
import 'package:picklog/features/browse/bloc/browse_genre_games_state.dart';
import 'package:picklog/features/games/i_games_repository.dart';

class BrowseGenreGamesBloc
    extends Bloc<BrowseGenreGamesEvent, BrowseGenreGamesState> {
  BrowseGenreGamesBloc({required IGamesRepository gamesRepository})
    : _gamesRepository = gamesRepository,
      super(const BrowseGenreGamesState()) {
    on<BrowseGenreGamesLoadRequested>(_onLoadRequested);
    on<BrowseGenreGamesLoadMore>(_onLoadMore);
  }

  final IGamesRepository _gamesRepository;

  static const pageSize = 40;

  /// The API rejects offsets beyond this.
  static const maxOffset = 10000;

  Future<void> _onLoadRequested(
    BrowseGenreGamesLoadRequested event,
    Emitter<BrowseGenreGamesState> emit,
  ) async {
    if (state.status == BrowseGenreGamesStatus.loading) return;

    emit(
      state.copyWith(
        status: BrowseGenreGamesStatus.loading,
        genreId: event.genreId,
      ),
    );
    try {
      final response = await _gamesRepository.getGamesByGenre(
        event.genreId,
        limit: pageSize,
      );
      emit(
        state.copyWith(
          status: BrowseGenreGamesStatus.success,
          games: response.games,
          hasMore: response.hasMore && pageSize < maxOffset,
          nextOffset: pageSize,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: BrowseGenreGamesStatus.failure,
          errorKind: AppErrorKind.from(e),
        ),
      );
    }
  }

  Future<void> _onLoadMore(
    BrowseGenreGamesLoadMore event,
    Emitter<BrowseGenreGamesState> emit,
  ) async {
    final genreId = state.genreId;
    if (genreId == null || !state.canLoadMore) return;

    emit(state.copyWith(status: BrowseGenreGamesStatus.loadingMore));
    try {
      final response = await _gamesRepository.getGamesByGenre(
        genreId,
        limit: pageSize,
        offset: state.nextOffset,
      );
      final nextOffset = state.nextOffset + pageSize;
      emit(
        state.copyWith(
          status: BrowseGenreGamesStatus.success,
          games: [...state.games, ...response.games],
          hasMore: response.hasMore && nextOffset < maxOffset,
          nextOffset: nextOffset,
        ),
      );
    } catch (e) {
      // Keep what is loaded; the screen offers a retry at the end.
      emit(
        state.copyWith(
          status: BrowseGenreGamesStatus.success,
          errorKind: AppErrorKind.from(e),
        ),
      );
    }
  }
}
