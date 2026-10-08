import 'package:flutter_test/flutter_test.dart';
import 'package:picklog/features/games/bloc/game_search_filters.dart';
import 'package:picklog/features/games/catalog_filters.dart';
import 'package:picklog/features/games/search_game_model.dart';

SearchGame _game({
  required int id,
  required String name,
  DateTime? releaseDate,
  List<GameGenre> genres = const [],
  List<GamePlatform> platforms = const [],
}) {
  return SearchGame(
    id: id,
    name: name,
    firstReleaseDate: releaseDate,
    genres: genres,
    platforms: platforms,
  );
}

void main() {
  group('GameSearchFilters.sortGames by date', () {
    test('Newest first orders same-year games by full date, newest first', () {
      final jan = _game(
        id: 1,
        name: 'January',
        releaseDate: DateTime(2020, 1, 15),
      );
      final dec = _game(
        id: 2,
        name: 'December',
        releaseDate: DateTime(2020, 12, 20),
      );

      // Loaded order is January then December; the sort must reorder them.
      const filters = GameSearchFilters(sort: GameSearchSort.yearDesc);
      final result = filters.sortGames([jan, dec]);

      expect(result.map((g) => g.id).toList(), [dec.id, jan.id]);
    });

    test('Oldest first orders same-year games by full date, oldest first', () {
      final jan = _game(
        id: 1,
        name: 'January',
        releaseDate: DateTime(2020, 1, 15),
      );
      final dec = _game(
        id: 2,
        name: 'December',
        releaseDate: DateTime(2020, 12, 20),
      );

      // Loaded order is December then January; the sort must reorder them.
      const filters = GameSearchFilters(sort: GameSearchSort.yearAsc);
      final result = filters.sortGames([dec, jan]);

      expect(result.map((g) => g.id).toList(), [jan.id, dec.id]);
    });

    test('games without a release date are pushed last in both directions', () {
      final dated = _game(
        id: 1,
        name: 'Dated',
        releaseDate: DateTime(2020, 6, 1),
      );
      final undated = _game(id: 2, name: 'Undated');

      final desc = const GameSearchFilters(
        sort: GameSearchSort.yearDesc,
      ).sortGames([undated, dated]);
      expect(desc.map((g) => g.id).toList(), [dated.id, undated.id]);

      final asc = const GameSearchFilters(
        sort: GameSearchSort.yearAsc,
      ).sortGames([undated, dated]);
      expect(asc.map((g) => g.id).toList(), [dated.id, undated.id]);
    });
  });

  group('GameSearchFilters state', () {
    test('relevance keeps the API order and counts only catalog filters', () {
      final a = _game(id: 1, name: 'B');
      final b = _game(id: 2, name: 'A');
      const filters = GameSearchFilters(
        catalog: CatalogFilters(genreIds: {1, 2}, minRating: 70),
      );
      expect(filters.sortGames([a, b]).map((g) => g.id), [1, 2]);
      expect(filters.activeFilterCount, 3);
      expect(filters.isEmpty, isFalse);
      expect(const GameSearchFilters().isEmpty, isTrue);
    });
  });
}
