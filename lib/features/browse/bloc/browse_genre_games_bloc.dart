import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picklog/features/browse/bloc/browse_genre_games_event.dart';
import 'package:picklog/features/browse/bloc/browse_genre_games_state.dart';
import 'package:picklog/features/games/i_games_repository.dart';

class BrowseGenreGamesBloc
    extends Bloc<BrowseGenreGamesEvent, BrowseGenreGamesState> {
  BrowseGenreGamesBloc({required IGamesRepository gamesRepository})
    : _gamesRepository = gamesRepository,
      super(const BrowseGenreGamesState()) {
    on<BrowseGenreGamesLoadRequested>(_onLoadRequested);
  }

  final IGamesRepository _gamesRepository;

  static const _pageSize = 40;

  Future<void> _onLoadRequested(
    BrowseGenreGamesLoadRequested event,
    Emitter<BrowseGenreGamesState> emit,
  ) async {
    if (state.status == BrowseGenreGamesStatus.loading) return;

    emit(state.copyWith(status: BrowseGenreGamesStatus.loading));
    try {
      final response = await _gamesRepository.getGamesByGenre(
        event.genreId,
        limit: _pageSize,
      );
      emit(
        state.copyWith(
          status: BrowseGenreGamesStatus.success,
          games: response.games,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: BrowseGenreGamesStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
