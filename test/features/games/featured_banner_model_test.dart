import 'package:flutter_test/flutter_test.dart';
import 'package:picklog/features/games/featured_banner_model.dart';

void main() {
  group('FeaturedBanner', () {
    test('parses a banner with a linked game', () {
      final banner = FeaturedBanner.fromJson(const {
        'id': 'abc',
        'title': 'Hero',
        'subtitle': 'Sub',
        'image_url': 'https://img/banner.jpg',
        'position': 0,
        'game': {
          'igdb_id': 1942,
          'name': 'The Witcher 3',
          'cover_url': 'https://img/cover.jpg',
        },
      });

      expect(banner.id, 'abc');
      expect(banner.title, 'Hero');
      expect(banner.subtitle, 'Sub');
      expect(banner.imageUrl, 'https://img/banner.jpg');
      expect(banner.game, isNotNull);
      expect(banner.game!.igdbId, 1942);
      expect(banner.game!.coverUrl, 'https://img/cover.jpg');
    });

    test('parses a banner without a game or subtitle', () {
      final banner = FeaturedBanner.fromJson(const {
        'id': 'b2',
        'title': 'No Game',
        'image_url': 'https://img/b2.jpg',
        'position': 1,
      });

      expect(banner.game, isNull);
      expect(banner.subtitle, isNull);
      expect(banner.position, 1);
    });

    test('FeaturedBannersResponse parses a list and defaults to empty', () {
      final resp = FeaturedBannersResponse.fromJson(const {
        'banners': [
          {'id': 'a', 'title': 'A', 'image_url': 'u', 'position': 0},
        ],
      });
      expect(resp.banners, hasLength(1));

      final empty = FeaturedBannersResponse.fromJson(const <String, dynamic>{});
      expect(empty.banners, isEmpty);
    });
  });
}
