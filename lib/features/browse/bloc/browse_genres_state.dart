import 'package:equatable/equatable.dart';
import 'package:picklog/features/games/game_detail_model.dart';

enum BrowseGenresStatus { initial, loading, success, failure }

class BrowseGenresState extends Equatable {
  const BrowseGenresState({
    this.status = BrowseGenresStatus.initial,
    this.genres = const [],
    this.errorMessage,
  });

  final BrowseGenresStatus status;
  final List<Genre> genres;
  final String? errorMessage;

  bool get isLoading => status == BrowseGenresStatus.loading;
  bool get hasGenres => genres.isNotEmpty;

  BrowseGenresState copyWith({
    BrowseGenresStatus? status,
    List<Genre>? genres,
    String? errorMessage,
  }) {
    return BrowseGenresState(
      status: status ?? this.status,
      genres: genres ?? this.genres,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, genres, errorMessage];
}
