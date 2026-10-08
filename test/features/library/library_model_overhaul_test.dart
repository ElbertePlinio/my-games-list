import 'package:flutter_test/flutter_test.dart';
import 'package:picklog/features/library/library_entry_model.dart';

import 'library_fixtures.dart';

void main() {
  test('parses genres, total rating, slug and collection ids', () {
    final e = LibraryEntry.fromJson(entryJson(collectionIds: ['c-1', 'c-2']));
    expect(e.game.genres.single.name, 'Adventure');
    expect(e.game.totalRating, 88.5);
    expect(e.game.slug, 'hollow-knight');
    expect(e.collectionIds, ['c-1', 'c-2']);
  });

  test('missing overhaul fields default to empty lists', () {
    final json = entryJson();
    (json['game'] as Map<String, dynamic>).remove('genres');
    json.remove('collection_ids');
    final e = LibraryEntry.fromJson(json);
    expect(e.game.genres, isEmpty);
    expect(e.collectionIds, isEmpty);
  });

  test('round trips through toJson and copyWith keeps collections', () {
    final e = entry(collectionIds: ['c-1']);
    expect(LibraryEntry.fromJson(e.toJson()), e);
    expect(e.copyWith(isFavorite: true).collectionIds, ['c-1']);
    expect(e.copyWith(collectionIds: []).collectionIds, isEmpty);
  });
}
