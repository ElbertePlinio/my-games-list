import 'package:flutter_test/flutter_test.dart';
import 'package:picklog/core/utils/image_utils.dart';

void main() {
  group('getHighResUrl', () {
    test('adds https prefix to URL starting with //', () {
      const url = '//images.igdb.com/igdb/image/upload/t_thumb/co9rwo.jpg';
      final result = getHighResUrl(url, ImageSize.coverBig);

      expect(result, startsWith('https://'));
      expect(result, contains('t_cover_big'));
    });

    test('does not modify URL already starting with https', () {
      const url =
          'https://images.igdb.com/igdb/image/upload/t_thumb/co9rwo.jpg';
      final result = getHighResUrl(url, ImageSize.coverBig);

      expect(result, startsWith('https://'));
      expect(
        result,
        equals(
          'https://images.igdb.com/igdb/image/upload/t_cover_big/co9rwo.jpg',
        ),
      );
    });

    test('replaces t_thumb with t_cover_big', () {
      const url = '//images.igdb.com/igdb/image/upload/t_thumb/co9rwo.jpg';
      final result = getHighResUrl(url, ImageSize.coverBig);

      expect(result, contains('t_cover_big'));
      expect(result, isNot(contains('t_thumb')));
    });

    test('replaces t_thumb with t_1080p', () {
      const url = '//images.igdb.com/igdb/image/upload/t_thumb/screenshot.jpg';
      final result = getHighResUrl(url, ImageSize.hd1080);

      expect(result, contains('t_1080p'));
      expect(result, isNot(contains('t_thumb')));
    });

    test('replaces t_thumb with t_screenshot_med', () {
      const url = '//images.igdb.com/igdb/image/upload/t_thumb/screenshot.jpg';
      final result = getHighResUrl(url, ImageSize.screenshotMed);

      expect(result, contains('t_screenshot_med'));
    });

    test('replaces t_cover_small with t_cover_big', () {
      const url =
          'https://images.igdb.com/igdb/image/upload/t_cover_small/co9rwo.jpg';
      final result = getHighResUrl(url, ImageSize.coverBig);

      expect(result, contains('t_cover_big'));
      expect(result, isNot(contains('t_cover_small')));
    });

    test('handles empty URL gracefully', () {
      final result = getHighResUrl('', ImageSize.coverBig);
      expect(result, isEmpty);
    });

    test('returns original URL if no size identifier found', () {
      const url = 'https://example.com/image.jpg';
      final result = getHighResUrl(url, ImageSize.coverBig);

      expect(result, equals(url));
    });

    test('works with t_720p size', () {
      const url = '//images.igdb.com/igdb/image/upload/t_thumb/image.jpg';
      final result = getHighResUrl(url, ImageSize.hd720);

      expect(result, contains('t_720p'));
    });
  });

  group('ImageSize constants', () {
    test('has correct values', () {
      expect(ImageSize.thumb, equals('t_thumb'));
      expect(ImageSize.coverSmall, equals('t_cover_small'));
      expect(ImageSize.coverBig, equals('t_cover_big'));
      expect(ImageSize.screenshotMed, equals('t_screenshot_med'));
      expect(ImageSize.hd720, equals('t_720p'));
      expect(ImageSize.hd1080, equals('t_1080p'));
    });
  });
}
