import 'package:equatable/equatable.dart';

abstract class BrowseGenreGamesEvent extends Equatable {
  const BrowseGenreGamesEvent();

  @override
  List<Object?> get props => [];
}

/// Loads (or reloads) the first page for a genre.
class BrowseGenreGamesLoadRequested extends BrowseGenreGamesEvent {
  const BrowseGenreGamesLoadRequested(this.genreId);

  final int genreId;

  @override
  List<Object?> get props => [genreId];
}

/// Appends the next page for the genre already loaded.
class BrowseGenreGamesLoadMore extends BrowseGenreGamesEvent {
  const BrowseGenreGamesLoadMore();
}
