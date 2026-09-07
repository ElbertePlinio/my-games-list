import 'package:flutter_test/flutter_test.dart';
import 'package:picklog/features/games/game_detail_model.dart';

void main() {
  group('GameDetail', () {
    final completeJson = {
      'id': 1942,
      'name': 'The Witcher 3: Wild Hunt',
      'summary': 'An open-world action RPG',
      'storyline': 'Geralt\'s story continues...',
      'cover': {'id': 480513, 'url': 'https://images.igdb.com/cover.jpg'},
      'screenshots': [
        {'id': 21107, 'url': 'https://images.igdb.com/screenshot1.jpg'},
        {'id': 21108, 'url': 'https://images.igdb.com/screenshot2.jpg'},
      ],
      'videos': [
        {'id': 9648, 'video_id': 'yowv6_rspoM'},
      ],
      'genres': [
        {'id': 12, 'name': 'Role-playing (RPG)'},
        {'id': 31, 'name': 'Adventure'},
      ],
      'platforms': [
        {'id': 48, 'name': 'PlayStation 4'},
        {'id': 6, 'name': 'PC (Microsoft Windows)'},
      ],
      'first_release_date': 1431993600,
      'total_rating': 92.82744671539679,
      'involved_companies': [
        {
          'id': 42142,
          'company': {'id': 908, 'name': 'CD Projekt RED'},
          'developer': true,
        },
        {
          'id': 17436,
          'company': {'id': 50, 'name': 'WB Games'},
          'developer': false,
        },
      ],
      'websites': [
        {
          'id': 19107,
          'url': 'https://store.steampowered.com/app/292030',
          'category': 13,
        },
      ],
      'similar_games': [
        {
          'id': 472,
          'name': 'The Elder Scrolls V: Skyrim',
          'cover': {'id': 85100, 'url': 'https://images.igdb.com/skyrim.jpg'},
        },
      ],
    };

    test('fromJson parses complete data correctly', () {
      final game = GameDetail.fromJson(completeJson);

      expect(game.id, equals(1942));
      expect(game.name, equals('The Witcher 3: Wild Hunt'));
      expect(game.summary, equals('An open-world action RPG'));
      expect(game.storyline, equals('Geralt\'s story continues...'));
      expect(game.cover, isNotNull);
      expect(game.cover!.id, equals(480513));
      expect(game.screenshots, hasLength(2));
      expect(game.videos, hasLength(1));
      expect(game.genres, hasLength(2));
      expect(game.platforms, hasLength(2));
      expect(game.firstReleaseDate, isNotNull);
      expect(game.totalRating, closeTo(92.827, 0.001));
      expect(game.involvedCompanies, hasLength(2));
      expect(game.websites, hasLength(1));
      expect(game.similarGames, hasLength(1));
    });

    test('fromJson handles minimal data', () {
      final minimalJson = {'id': 1234, 'name': 'Minimal Game'};

      final game = GameDetail.fromJson(minimalJson);

      expect(game.id, equals(1234));
      expect(game.name, equals('Minimal Game'));
      expect(game.summary, isNull);
      expect(game.storyline, isNull);
      expect(game.cover, isNull);
      expect(game.screenshots, isEmpty);
      expect(game.videos, isEmpty);
      expect(game.genres, isEmpty);
      expect(game.platforms, isEmpty);
      expect(game.firstReleaseDate, isNull);
      expect(game.totalRating, isNull);
      expect(game.involvedCompanies, isEmpty);
      expect(game.websites, isEmpty);
      expect(game.similarGames, isEmpty);
    });

    test('fiveStarRating converts 100 scale to 5 scale', () {
      final game = GameDetail.fromJson(completeJson);
      // 92.82744671539679 / 20 = 4.641372335769839
      expect(game.fiveStarRating, closeTo(4.64, 0.01));
    });

    test('fiveStarRating returns 0 when totalRating is null', () {
      final game = GameDetail.fromJson(const {'id': 1, 'name': 'Test'});
      expect(game.fiveStarRating, equals(0.0));
    });

    test('developer returns developer company', () {
      final game = GameDetail.fromJson(completeJson);
      expect(game.developer, isNotNull);
      expect(game.developer!.name, equals('CD Projekt RED'));
    });

    test('developer returns null when no developer', () {
      final jsonWithoutDev = {
        'id': 1,
        'name': 'Test',
        'involved_companies': [
          {
            'id': 1,
            'company': {'id': 1, 'name': 'Publisher'},
            'developer': false,
          },
        ],
      };
      final game = GameDetail.fromJson(jsonWithoutDev);
      expect(game.developer, isNull);
    });

    test('publishers returns non-developer companies', () {
      final game = GameDetail.fromJson(completeJson);
      expect(game.publishers, hasLength(1));
      expect(game.publishers.first.name, equals('WB Games'));
    });

    test('hasCover returns true when cover exists', () {
      final game = GameDetail.fromJson(completeJson);
      expect(game.hasCover, isTrue);
    });

    test('hasCover returns false when cover is null', () {
      final game = GameDetail.fromJson(const {'id': 1, 'name': 'Test'});
      expect(game.hasCover, isFalse);
    });

    test('isReleased returns true for past release date', () {
      final pastJson = {
        'id': 1,
        'name': 'Test',
        'first_release_date': 1431993600, // May 2015
      };
      final game = GameDetail.fromJson(pastJson);
      expect(game.isReleased, isTrue);
    });

    test('isReleased returns false for future release date', () {
      // Set a future timestamp (year 2030)
      final futureJson = {
        'id': 1,
        'name': 'Test',
        'first_release_date': 1893456000,
      };
      final game = GameDetail.fromJson(futureJson);
      expect(game.isReleased, isFalse);
    });

    test('isReleased returns false when no release date', () {
      final game = GameDetail.fromJson(const {'id': 1, 'name': 'Test'});
      expect(game.isReleased, isFalse);
    });

    test('props equality works correctly', () {
      final game1 = GameDetail.fromJson(completeJson);
      final game2 = GameDetail.fromJson(completeJson);
      expect(game1, equals(game2));
    });
  });

  group('Video', () {
    test('thumbnailUrl returns correct YouTube URL', () {
      final video = Video.fromJson(const {'id': 1, 'video_id': 'abc123'});
      expect(
        video.thumbnailUrl,
        equals('https://img.youtube.com/vi/abc123/mqdefault.jpg'),
      );
    });

    test('highQualityThumbnailUrl returns correct URL', () {
      final video = Video.fromJson(const {'id': 1, 'video_id': 'abc123'});
      expect(
        video.highQualityThumbnailUrl,
        equals('https://img.youtube.com/vi/abc123/maxresdefault.jpg'),
      );
    });
  });

  group('SimilarGame', () {
    test('fromJson parses with cover', () {
      final json = {
        'id': 472,
        'name': 'Skyrim',
        'cover': {'id': 123, 'url': 'https://example.com/cover.jpg'},
      };
      final game = SimilarGame.fromJson(json);
      expect(game.cover, isNotNull);
      expect(game.cover!.url, equals('https://example.com/cover.jpg'));
    });

    test('fromJson handles missing cover', () {
      final json = {'id': 472, 'name': 'Skyrim'};
      final game = SimilarGame.fromJson(json);
      expect(game.cover, isNull);
    });
  });

  group('GameDetailResponse', () {
    test('fromJson parses correctly', () {
      final json = {
        'game': {'id': 1942, 'name': 'The Witcher 3'},
      };
      final response = GameDetailResponse.fromJson(json);
      expect(response.game.id, equals(1942));
      expect(response.game.name, equals('The Witcher 3'));
    });
  });

  group('Genre', () {
    test('fromJson parses correctly', () {
      final json = {'id': 12, 'name': 'RPG'};
      final genre = Genre.fromJson(json);
      expect(genre.id, equals(12));
      expect(genre.name, equals('RPG'));
    });

    test('props equality', () {
      final genre1 = Genre.fromJson(const {'id': 12, 'name': 'RPG'});
      final genre2 = Genre.fromJson(const {'id': 12, 'name': 'RPG'});
      expect(genre1, equals(genre2));
    });
  });

  group('Platform', () {
    test('fromJson parses correctly', () {
      final json = {'id': 48, 'name': 'PlayStation 4'};
      final platform = Platform.fromJson(json);
      expect(platform.id, equals(48));
      expect(platform.name, equals('PlayStation 4'));
    });
  });

  group('InvolvedCompany', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 42142,
        'company': {'id': 908, 'name': 'CD Projekt RED'},
        'developer': true,
      };
      final ic = InvolvedCompany.fromJson(json);
      expect(ic.id, equals(42142));
      expect(ic.company.name, equals('CD Projekt RED'));
      expect(ic.developer, isTrue);
    });

    test('developer defaults to false when missing', () {
      final json = {
        'id': 1,
        'company': {'id': 1, 'name': 'Test'},
      };
      final ic = InvolvedCompany.fromJson(json);
      expect(ic.developer, isFalse);
    });
  });

  group('Website', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 19107,
        'url': 'https://store.steampowered.com/app/292030',
        'category': 13,
      };
      final website = Website.fromJson(json);
      expect(website.id, equals(19107));
      expect(website.url, contains('steampowered'));
      expect(website.category, equals(13));
    });
  });
}
