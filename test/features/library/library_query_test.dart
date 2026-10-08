import 'package:flutter_test/flutter_test.dart';
import 'package:picklog/features/library/library_entry_model.dart';
import 'package:picklog/features/library/library_query.dart';

void main() {
  group('LibraryFilters.toQueryParameters', () {
    test('defaults send nothing but paging', () {
      expect(const LibraryFilters().toQueryParameters(), isEmpty);
      expect(const LibraryFilters().toQueryParameters(limit: 50), {
        'limit': '50',
      });
    });

    test('builds every server-side filter in a stable order', () {
      const filters = LibraryFilters(
        statuses: {GameStatus.onHold, GameStatus.playing},
        favoritesOnly: true,
        query: '  zelda ',
        genreIds: {31, 12},
        platformIds: {167, 6},
        minScore: 70,
        collectionId: 'c-1',
        sort: LibrarySort.scoreDesc,
      );
      expect(filters.toQueryParameters(limit: 50, offset: 100), {
        'status': 'playing,on_hold',
        'favorites_only': 'true',
        'q': 'zelda',
        'genre_ids': '12,31',
        'platform_ids': '6,167',
        'min_score': '70',
        'collection_id': 'c-1',
        'sort': 'score_desc',
        'limit': '50',
        'offset': '100',
      });
    });

    test('caps q at 100 characters and skips offset 0', () {
      final params = LibraryFilters(
        query: 'x' * 150,
      ).toQueryParameters(offset: 0);
      expect(params['q']!.length, 100);
      expect(params.containsKey('offset'), isFalse);
    });

    test('every sort key maps to the API value', () {
      expect(LibrarySort.values.map((s) => s.apiValue), [
        'updated_desc',
        'added_desc',
        'name_asc',
        'score_desc',
        'playtime_desc',
        'release_desc',
        'rating_desc',
      ]);
    });
  });

  group('LibraryFilters state', () {
    test('hasActiveFilters ignores the sort', () {
      expect(
        const LibraryFilters(sort: LibrarySort.nameAsc).hasActiveFilters,
        isFalse,
      );
      expect(const LibraryFilters(minScore: 10).hasActiveFilters, isTrue);
      expect(const LibraryFilters(query: 'a').hasActiveFilters, isTrue);
    });

    test('cleared keeps the sort and copyWith clears optional values', () {
      const filters = LibraryFilters(
        minScore: 50,
        collectionId: 'c',
        sort: LibrarySort.nameAsc,
        favoritesOnly: true,
      );
      expect(
        filters.cleared(),
        const LibraryFilters(sort: LibrarySort.nameAsc),
      );
      final copy = filters.copyWith(clearMinScore: true, clearCollection: true);
      expect(copy.minScore, isNull);
      expect(copy.collectionId, isNull);
      expect(copy.activeChipCount, 1);
    });
  });
}
