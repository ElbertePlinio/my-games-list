import 'package:picklog/features/library/library_entry_model.dart';

/// Library entry JSON in the API shape, with the overhaul fields.
Map<String, dynamic> entryJson({
  String id = 'entry-1',
  int igdbId = 42,
  String name = 'Hollow Knight',
  String status = 'planned',
  bool favorite = false,
  int? platformId = 6,
  int? playtime,
  List<String> collectionIds = const [],
}) => {
  'id': id,
  'user_id': 'user-1',
  'game': {
    'id': 'g-$id',
    'igdb_id': igdbId,
    'name': name,
    'cover_url': null,
    'last_synced_at': '2026-01-01T00:00:00Z',
    'total_rating': 88.5,
    'slug': 'hollow-knight',
    'genres': [
      {'id': 31, 'name': 'Adventure'},
    ],
  },
  if (platformId != null)
    'platform': {
      'id': 'p-$platformId',
      'igdb_platform_id': platformId,
      'name': 'Platform $platformId',
      'abbreviation': 'P$platformId',
    },
  'status': status,
  'playtime_minutes': ?playtime,
  'is_favorite': favorite,
  'created_at': '2026-01-01T00:00:00Z',
  'updated_at': '2026-01-02T00:00:00Z',
  'collection_ids': collectionIds,
};

/// A parsed [LibraryEntry].
LibraryEntry entry({
  String id = 'entry-1',
  int igdbId = 42,
  String name = 'Hollow Knight',
  GameStatus status = GameStatus.planned,
  bool favorite = false,
  int? platformId = 6,
  int? playtime,
  List<String> collectionIds = const [],
}) => LibraryEntry.fromJson(
  entryJson(
    id: id,
    igdbId: igdbId,
    name: name,
    status: status.toApiString(),
    favorite: favorite,
    platformId: platformId,
    playtime: playtime,
    collectionIds: collectionIds,
  ),
);

Map<String, dynamic> collectionJson({
  String id = 'c-1',
  String name = 'Couch co-op',
  int count = 2,
  String? description,
}) => {
  'id': id,
  'name': name,
  'description': ?description,
  'game_count': count,
  'cover_urls': ['a', 'b'],
  'created_at': '2026-01-01T00:00:00Z',
  'updated_at': '2026-01-02T00:00:00Z',
};
