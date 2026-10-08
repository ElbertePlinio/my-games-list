import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';

/// Earliest release year the catalog filters accept.
const int kCatalogMinYear = 1970;

/// Latest release year the catalog filters accept (the API allows two years
/// ahead).
int catalogMaxYear([DateTime? now]) => (now ?? DateTime.now()).year + 2;

/// A platform from `GET /games/platforms`.
class PlatformOption extends Equatable {
  const PlatformOption({
    required this.id,
    required this.name,
    this.abbreviation = '',
  });

  factory PlatformOption.fromJson(Map<String, dynamic> json) => PlatformOption(
    id: json['id'] as int,
    name: json['name'] as String,
    abbreviation: json['abbreviation'] as String? ?? '',
  );

  final int id;
  final String name;
  final String abbreviation;

  /// The short name when the API has one.
  String get label => abbreviation.isNotEmpty ? abbreviation : name;

  @override
  List<Object?> get props => [id, name, abbreviation];
}

/// IGDB catalog filters shared by Explore and Search. The API applies them.
class CatalogFilters extends Equatable {
  const CatalogFilters({
    this.genreIds = const {},
    this.platformIds = const {},
    this.yearFrom,
    this.yearTo,
    this.minRating,
  });

  /// The API accepts at most this many genre or platform ids.
  static const int maxIds = 10;

  final Set<int> genreIds;
  final Set<int> platformIds;
  final int? yearFrom;
  final int? yearTo;

  /// Minimum IGDB rating, 0-100. Null or 0 means none.
  final int? minRating;

  bool get hasYearRange => yearFrom != null || yearTo != null;
  bool get hasMinRating => (minRating ?? 0) > 0;

  bool get isEmpty =>
      genreIds.isEmpty && platformIds.isEmpty && !hasYearRange && !hasMinRating;

  /// Number of active constraints, for badges.
  int get activeCount =>
      genreIds.length +
      platformIds.length +
      (hasYearRange ? 1 : 0) +
      (hasMinRating ? 1 : 0);

  CatalogFilters copyWith({
    Set<int>? genreIds,
    Set<int>? platformIds,
    int? yearFrom,
    int? yearTo,
    bool clearYears = false,
    int? minRating,
    bool clearMinRating = false,
  }) {
    return CatalogFilters(
      genreIds: genreIds ?? this.genreIds,
      platformIds: platformIds ?? this.platformIds,
      yearFrom: clearYears ? null : (yearFrom ?? this.yearFrom),
      yearTo: clearYears ? null : (yearTo ?? this.yearTo),
      minRating: clearMinRating ? null : (minRating ?? this.minRating),
    );
  }

  /// Sets the year range from a slider. The full range clears it.
  CatalogFilters withYearRange(int from, int to, {int? maxYear}) {
    final max = maxYear ?? catalogMaxYear();
    if (from <= kCatalogMinYear && to >= max) {
      return copyWith(clearYears: true);
    }
    return CatalogFilters(
      genreIds: genreIds,
      platformIds: platformIds,
      yearFrom: from <= kCatalogMinYear ? null : from,
      yearTo: to >= max ? null : to,
      minRating: minRating,
    );
  }

  List<int> _sorted(Set<int> ids) =>
      (ids.toList()..sort()).take(maxIds).toList();

  /// Fields for the `POST /games/search` body.
  Map<String, dynamic> toSearchBody() => {
    if (genreIds.isNotEmpty) 'genre_ids': _sorted(genreIds),
    if (platformIds.isNotEmpty) 'platform_ids': _sorted(platformIds),
    'year_from': ?yearFrom,
    'year_to': ?yearTo,
    if (hasMinRating) 'min_rating': minRating,
  };

  /// Query parameters for `GET /games/explore`.
  Map<String, String> toQueryParameters() => {
    if (genreIds.isNotEmpty) 'genre_ids': _sorted(genreIds).join(','),
    if (platformIds.isNotEmpty) 'platform_ids': _sorted(platformIds).join(','),
    if (yearFrom != null) 'year_from': '$yearFrom',
    if (yearTo != null) 'year_to': '$yearTo',
    if (hasMinRating) 'min_rating': '$minRating',
  };

  @override
  List<Object?> get props => [
    genreIds,
    platformIds,
    yearFrom,
    yearTo,
    minRating,
  ];
}

/// Sort keys of `GET /games/explore`.
enum ExploreSort {
  popular('popular'),
  rating('rating'),
  newest('newest'),
  oldest('oldest'),
  name('name');

  const ExploreSort(this.apiValue);

  final String apiValue;

  String localizedName(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      ExploreSort.popular => l10n.exploreSortPopular,
      ExploreSort.rating => l10n.exploreSortRating,
      ExploreSort.newest => l10n.exploreSortNewest,
      ExploreSort.oldest => l10n.exploreSortOldest,
      ExploreSort.name => l10n.exploreSortName,
    };
  }
}

/// Explore filters: the catalog filters plus a server-side sort.
class ExploreFilters extends Equatable {
  const ExploreFilters({
    this.catalog = const CatalogFilters(),
    this.sort = ExploreSort.popular,
  });

  final CatalogFilters catalog;
  final ExploreSort sort;

  bool get isDefault => catalog.isEmpty && sort == ExploreSort.popular;

  ExploreFilters copyWith({CatalogFilters? catalog, ExploreSort? sort}) =>
      ExploreFilters(catalog: catalog ?? this.catalog, sort: sort ?? this.sort);

  Map<String, String> toQueryParameters({
    required int limit,
    required int offset,
  }) => {
    ...catalog.toQueryParameters(),
    'sort': sort.apiValue,
    'limit': '$limit',
    'offset': '$offset',
  };

  @override
  List<Object?> get props => [catalog, sort];
}
