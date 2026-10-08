import 'package:flutter_test/flutter_test.dart';
import 'package:picklog/features/games/catalog_filters.dart';

void main() {
  test('search body and explore params carry only set filters', () {
    const filters = CatalogFilters(
      genreIds: {31, 12},
      platformIds: {6},
      yearFrom: 2015,
      minRating: 80,
    );
    expect(filters.toSearchBody(), {
      'genre_ids': [12, 31],
      'platform_ids': [6],
      'year_from': 2015,
      'min_rating': 80,
    });
    expect(filters.toQueryParameters(), {
      'genre_ids': '12,31',
      'platform_ids': '6',
      'year_from': '2015',
      'min_rating': '80',
    });
    expect(const CatalogFilters().toSearchBody(), isEmpty);
  });

  test('id lists are capped at 10 for the API', () {
    final filters = CatalogFilters(genreIds: {for (var i = 1; i <= 12; i++) i});
    expect((filters.toSearchBody()['genre_ids'] as List).length, 10);
  });

  test('a full year range clears the years and a zero rating is none', () {
    final max = catalogMaxYear(DateTime(2026));
    final filters = const CatalogFilters(
      yearFrom: 2000,
    ).withYearRange(kCatalogMinYear, max, maxYear: max);
    expect(filters.hasYearRange, isFalse);
    final partial = const CatalogFilters().withYearRange(
      2010,
      max,
      maxYear: max,
    );
    expect(partial.yearFrom, 2010);
    expect(partial.yearTo, isNull);
    expect(const CatalogFilters(minRating: 0).isEmpty, isTrue);
    expect(partial.activeCount, 1);
  });

  test('explore filters add sort, limit and offset', () {
    const filters = ExploreFilters(
      catalog: CatalogFilters(genreIds: {12}),
      sort: ExploreSort.newest,
    );
    expect(filters.toQueryParameters(limit: 30, offset: 60), {
      'genre_ids': '12',
      'sort': 'newest',
      'limit': '30',
      'offset': '60',
    });
    expect(const ExploreFilters().isDefault, isTrue);
  });
}
