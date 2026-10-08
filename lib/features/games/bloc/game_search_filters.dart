import 'package:equatable/equatable.dart';
import 'package:picklog/features/games/catalog_filters.dart';
import 'package:picklog/features/games/search_game_model.dart';

/// How search results are ordered. [relevance] keeps the API order. The
/// search API has no sort, so the others reorder the loaded results.
enum GameSearchSort { relevance, nameAsc, yearDesc, yearAsc }

/// Search refinement: server-side [catalog] filters plus a client-side sort.
class GameSearchFilters extends Equatable {
  const GameSearchFilters({
    this.sort = GameSearchSort.relevance,
    this.catalog = const CatalogFilters(),
  });

  final GameSearchSort sort;

  /// Genre, platform, year and rating filters sent to `POST /games/search`.
  final CatalogFilters catalog;

  bool get isEmpty => sort == GameSearchSort.relevance && catalog.isEmpty;

  /// Number of active filter constraints (sort excluded).
  int get activeFilterCount => catalog.activeCount;

  GameSearchFilters copyWith({GameSearchSort? sort, CatalogFilters? catalog}) {
    return GameSearchFilters(
      sort: sort ?? this.sort,
      catalog: catalog ?? this.catalog,
    );
  }

  /// Orders [games] by [sort]. Relevance keeps the API order.
  List<SearchGame> sortGames(List<SearchGame> games) {
    if (sort == GameSearchSort.relevance) return games;
    final sorted = List.of(games);
    switch (sort) {
      case GameSearchSort.relevance:
        break;
      case GameSearchSort.nameAsc:
        sorted.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      case GameSearchSort.yearDesc:
        sorted.sort(_byYear(descending: true));
      case GameSearchSort.yearAsc:
        sorted.sort(_byYear(descending: false));
    }
    return sorted;
  }

  /// Sorts by full release date, always pushing games without a release date
  /// to the end regardless of direction.
  Comparator<SearchGame> _byYear({required bool descending}) {
    return (a, b) {
      final ad = a.firstReleaseDate;
      final bd = b.firstReleaseDate;
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return descending ? bd.compareTo(ad) : ad.compareTo(bd);
    };
  }

  @override
  List<Object?> get props => [sort, catalog];
}
