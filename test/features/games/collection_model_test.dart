import 'package:flutter_test/flutter_test.dart';
import 'package:picklog/features/games/collection_model.dart';

void main() {
  group('GameCollection', () {
    test('parses a collection and maps igdb_id to the game id', () {
      final c = GameCollection.fromJson(const {
        'id': 'c1',
        'slug': 'top-rpgs',
        'title': 'Top RPGs',
        'description': 'The best RPGs',
        'cover_image_url': 'https://img/cover.jpg',
        'games': [
          {'igdb_id': 1942, 'name': 'The Witcher 3', 'cover_url': 'u'},
        ],
      });

      expect(c.id, 'c1');
      expect(c.slug, 'top-rpgs');
      expect(c.title, 'Top RPGs');
      expect(c.description, 'The best RPGs');
      expect(c.games, hasLength(1));
      expect(c.games.first.id, 1942); // mapped from igdb_id
      expect(c.games.first.coverUrl, 'u');
    });

    test('CollectionsResponse parses a list and defaults to empty', () {
      final r = CollectionsResponse.fromJson(const {
        'collections': [
          {'id': 'a', 'slug': 's', 'title': 'T', 'games': <dynamic>[]},
        ],
      });
      expect(r.collections, hasLength(1));

      final empty = CollectionsResponse.fromJson(const <String, dynamic>{});
      expect(empty.collections, isEmpty);
    });
  });
}
