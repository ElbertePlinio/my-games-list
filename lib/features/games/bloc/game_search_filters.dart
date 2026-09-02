import 'package:equatable/equatable.dart';
import 'package:picklog/features/games/search_game_model.dart';

/// How search results are ordered. [relevance] keeps the API's original
/// ordering; the others are applied client-side over the loaded results.
enum GameSearchSort { relevance, nameAsc, yearDesc, yearAsc }

/// Client-side refinement applied to the loaded search results.
///
/// The search API is text-only (it binds query/limit/offset), so genre,
/// platform and year filtering plus sorting are computed over the results the
/// API already returned, using the fields the [SearchGame] model exposes.
class GameSearchFilters extends Equatable {
  const GameSearchFilters({
    this.sort = GameSearchSort.relevance,
    this.genreIds = const {},
    this.platformIds = const {},
    this.year,
  });

  final GameSearchSort sort;
  final Set<int> genreIds;
  final Set<int> platformIds;
  final int? year;

  bool get isEmpty =>
      sort == GameSearchSort.relevance &&
      genreIds.isEmpty &&
      platformIds.isEmpty &&
      year == null;

  /// Number of active filter constraints (sort excluded — it is always set).
  int get activeFilterCount =>
      genreIds.length + platformIds.length + (year != null ? 1 : 0);

  GameSearchFilters copyWith({
    GameSearchSort? sort,
    Set<int>? genreIds,
    Set<int>? platformIds,
    int? year,
    bool clearYear = false,
  }) {
    return GameSearchFilters(
      sort: sort ?? this.sort,
      genreIds: genreIds ?? this.genreIds,
      platformIds: platformIds ?? this.platformIds,
      year: clearYear ? null : (year ?? this.year),
    );
  }

  /// Applies the active filters and sort to [games].
  List<SearchGame> apply(List<SearchGame> games) {
    final filtered = games.where((game) {
      if (genreIds.isNotEmpty &&
          !game.genres.any((g) => genreIds.contains(g.id))) {
        return false;
      }
      if (platformIds.isNotEmpty &&
          !game.platforms.any((p) => platformIds.contains(p.id))) {
        return false;
      }
      // Match on the UTC year so the filter agrees with the year facet and the
      // API's midnight-UTC release timestamps regardless of the device zone.
      if (year != null && game.firstReleaseDate?.toUtc().year != year) {
        return false;
      }
      return true;
    }).toList();

    switch (sort) {
      case GameSearchSort.relevance:
        break;
      case GameSearchSort.nameAsc:
        filtered.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      case GameSearchSort.yearDesc:
        filtered.sort(_byYear(descending: true));
      case GameSearchSort.yearAsc:
        filtered.sort(_byYear(descending: false));
    }

    return filtered;
  }

  /// Sorts by full release date, always pushing games without a release date
  /// to the end regardless of direction. Comparing the whole [DateTime] (not
  /// just the year) keeps same-year results in correct chronological order.
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
  List<Object?> get props => [sort, genreIds, platformIds, year];
}
