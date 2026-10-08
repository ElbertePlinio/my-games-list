import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picklog/features/games/catalog_filters.dart';
import 'package:picklog/features/games/game_detail_model.dart';
import 'package:picklog/features/games/i_games_repository.dart';

enum FilterOptionsStatus { initial, loading, success, failure }

class FilterOptionsState extends Equatable {
  const FilterOptionsState({
    this.status = FilterOptionsStatus.initial,
    this.genres = const [],
    this.platforms = const [],
  });

  final FilterOptionsStatus status;
  final List<Genre> genres;
  final List<PlatformOption> platforms;

  String? genreName(int id) {
    for (final g in genres) {
      if (g.id == id) return g.name;
    }
    return null;
  }

  String? platformLabel(int id) {
    for (final p in platforms) {
      if (p.id == id) return p.label;
    }
    return null;
  }

  @override
  List<Object?> get props => [status, genres, platforms];
}

/// Loads the genre and platform lists that filter panels offer.
class FilterOptionsCubit extends Cubit<FilterOptionsState> {
  FilterOptionsCubit({required IGamesRepository gamesRepository})
    : _repository = gamesRepository,
      super(const FilterOptionsState());

  final IGamesRepository _repository;

  /// Loads both lists. One failed list does not hide the other.
  Future<void> load() async {
    if (state.status == FilterOptionsStatus.loading) return;
    emit(
      FilterOptionsState(
        status: FilterOptionsStatus.loading,
        genres: state.genres,
        platforms: state.platforms,
      ),
    );
    Future<T?> attempt<T>(Future<T> Function() call) async {
      try {
        return await call();
      } catch (_) {
        return null;
      }
    }

    final results = await Future.wait([
      attempt(_repository.getGenres),
      attempt(_repository.getPlatforms),
    ]);
    final genres = results[0] as List<Genre>?;
    final platforms = results[1] as List<PlatformOption>?;
    if (isClosed) return;
    final failed = genres == null && platforms == null;
    emit(
      FilterOptionsState(
        status: failed
            ? FilterOptionsStatus.failure
            : FilterOptionsStatus.success,
        genres: genres ?? state.genres,
        platforms: platforms ?? state.platforms,
      ),
    );
  }
}
