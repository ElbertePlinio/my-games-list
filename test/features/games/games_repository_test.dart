import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/core/data/services/http/i_http_client.dart';
import 'package:picklog/core/domain/models/api_error.dart';
import 'package:picklog/core/domain/models/api_response.dart';
import 'package:picklog/features/games/anticipated_game_model.dart';
import 'package:picklog/features/games/game_detail_model.dart';
import 'package:picklog/features/games/games_repository.dart';

class MockHttpClient extends Mock implements IHttpClient {}

void main() {
  late GamesRepository repository;
  late MockHttpClient mockHttpClient;

  setUp(() {
    mockHttpClient = MockHttpClient();
    repository = GamesRepository(httpClient: mockHttpClient);
  });

  group('GamesRepository', () {
    group('getAnticipatedGames', () {
      test('returns list of games on successful response', () async {
        // Arrange
        final mockResponse = {
          'games': [
            {
              'id': 52189,
              'name': 'Grand Theft Auto VI',
              'cover_url':
                  'https://images.igdb.com/igdb/image/upload/t_cover_big/co9rwo.jpg',
              'hypes': 764,
              'first_release_date': 1795046400,
              'platforms': [
                {'id': 169, 'name': 'Xbox Series X|S'},
                {'id': 167, 'name': 'PlayStation 5'},
              ],
            },
            {
              'id': 12345,
              'name': 'Another Game',
              'cover_url': '',
              'hypes': 500,
              'first_release_date': 1800000000,
              'platforms': [],
            },
          ],
        };

        when(
          () => mockHttpClient.get<Map<String, dynamic>>('/games/anticipated'),
        ).thenAnswer((_) async => ApiResponse.success(mockResponse));

        // Act
        final games = await repository.getAnticipatedGames();

        // Assert
        expect(games, isA<List<AnticipatedGame>>());
        expect(games.length, 2);
        expect(games[0].id, 52189);
        expect(games[0].name, 'Grand Theft Auto VI');
        expect(games[0].hypes, 764);
        expect(games[0].platforms.length, 2);
        expect(games[1].id, 12345);
        expect(games[1].platforms, isEmpty);

        verify(
          () => mockHttpClient.get<Map<String, dynamic>>('/games/anticipated'),
        ).called(1);
      });

      test('returns empty list when no games in response', () async {
        // Arrange
        final mockResponse = {'games': <Map<String, dynamic>>[]};

        when(
          () => mockHttpClient.get<Map<String, dynamic>>('/games/anticipated'),
        ).thenAnswer((_) async => ApiResponse.success(mockResponse));

        // Act
        final games = await repository.getAnticipatedGames();

        // Assert
        expect(games, isEmpty);
      });

      test('throws exception on API error', () async {
        // Arrange
        const apiError = ApiError(
          name: 'Error',
          message: 'Service unavailable',
          action: 'Try again later',
          statusCode: 503,
          errorCode: 'error.igdb.token.failed',
        );

        when(
          () => mockHttpClient.get<Map<String, dynamic>>('/games/anticipated'),
        ).thenAnswer((_) async => ApiResponse.failure(apiError));

        // Act & Assert
        expect(
          () => repository.getAnticipatedGames(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getGameDetails', () {
      test('returns game details on successful response', () async {
        // Arrange
        final mockResponse = {
          'game': {
            'id': 1942,
            'name': 'The Witcher 3: Wild Hunt',
            'summary': 'An open-world action RPG',
            'storyline': 'Geralt continues his journey...',
            'cover': {'id': 480513, 'url': 'https://images.igdb.com/cover.jpg'},
            'screenshots': [
              {'id': 21107, 'url': 'https://images.igdb.com/screenshot.jpg'},
            ],
            'videos': [
              {'id': 9648, 'video_id': 'yowv6_rspoM'},
            ],
            'genres': [
              {'id': 12, 'name': 'Role-playing (RPG)'},
            ],
            'platforms': [
              {'id': 48, 'name': 'PlayStation 4'},
            ],
            'first_release_date': 1431993600,
            'total_rating': 92.82744671539679,
            'involved_companies': [
              {
                'id': 42142,
                'company': {'id': 908, 'name': 'CD Projekt RED'},
                'developer': true,
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
                'cover': {
                  'id': 85100,
                  'url': 'https://images.igdb.com/skyrim.jpg',
                },
              },
            ],
          },
        };

        when(
          () => mockHttpClient.get<Map<String, dynamic>>('/games/1942'),
        ).thenAnswer((_) async => ApiResponse.success(mockResponse));

        // Act
        final game = await repository.getGameDetails(1942);

        // Assert
        expect(game, isA<GameDetail>());
        expect(game.id, 1942);
        expect(game.name, 'The Witcher 3: Wild Hunt');
        expect(game.summary, 'An open-world action RPG');
        expect(game.cover, isNotNull);
        expect(game.screenshots, hasLength(1));
        expect(game.videos, hasLength(1));
        expect(game.genres, hasLength(1));
        expect(game.platforms, hasLength(1));
        expect(game.totalRating, closeTo(92.827, 0.001));
        expect(game.involvedCompanies, hasLength(1));
        expect(game.websites, hasLength(1));
        expect(game.similarGames, hasLength(1));
        expect(game.developer?.name, 'CD Projekt RED');

        verify(
          () => mockHttpClient.get<Map<String, dynamic>>('/games/1942'),
        ).called(1);
      });

      test('throws exception on API error', () async {
        // Arrange
        const apiError = ApiError(
          name: 'Not Found',
          message: 'Game not found',
          action: 'Check the game ID',
          statusCode: 404,
          errorCode: 'error.games.not_found',
        );

        when(
          () => mockHttpClient.get<Map<String, dynamic>>('/games/99999'),
        ).thenAnswer((_) async => ApiResponse.failure(apiError));

        // Act & Assert
        expect(
          () => repository.getGameDetails(99999),
          throwsA(isA<Exception>()),
        );
      });

      test('returns game with minimal data', () async {
        // Arrange
        final mockResponse = {
          'game': {'id': 1234, 'name': 'Minimal Game'},
        };

        when(
          () => mockHttpClient.get<Map<String, dynamic>>('/games/1234'),
        ).thenAnswer((_) async => ApiResponse.success(mockResponse));

        // Act
        final game = await repository.getGameDetails(1234);

        // Assert
        expect(game.id, 1234);
        expect(game.name, 'Minimal Game');
        expect(game.cover, isNull);
        expect(game.screenshots, isEmpty);
        expect(game.videos, isEmpty);
      });
    });
  });

  group('AnticipatedGame', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 52189,
        'name': 'Test Game',
        'cover_url': 'https://example.com/cover.jpg',
        'hypes': 100,
        'first_release_date': 1795046400,
        'platforms': [
          {'id': 1, 'name': 'PC'},
        ],
      };

      final game = AnticipatedGame.fromJson(json);

      expect(game.id, 52189);
      expect(game.name, 'Test Game');
      expect(game.coverUrl, 'https://example.com/cover.jpg');
      expect(game.hypes, 100);
      expect(game.platforms.length, 1);
      expect(game.platforms[0].name, 'PC');
    });

    test('fromJson handles null values', () {
      final json = {
        'id': 1,
        'name': 'Minimal Game',
        'first_release_date': 1795046400,
      };

      final game = AnticipatedGame.fromJson(json);

      expect(game.id, 1);
      expect(game.name, 'Minimal Game');
      expect(game.coverUrl, '');
      expect(game.hypes, 0);
      expect(game.platforms, isEmpty);
    });

    test('countdownText returns correct format for days', () {
      final futureDate = DateTime.now().add(
        const Duration(days: 45, hours: 12, minutes: 30),
      );
      final game = AnticipatedGame(
        id: 1,
        name: 'Test',
        coverUrl: '',
        hypes: 0,
        firstReleaseDate: futureDate,
        platforms: const [],
      );

      expect(game.countdownText, contains('d'));
      expect(game.countdownText, contains('h'));
      expect(game.countdownText, contains('m'));
    });

    test('countdownText returns Released for past dates', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 1));
      final game = AnticipatedGame(
        id: 1,
        name: 'Test',
        coverUrl: '',
        hypes: 0,
        firstReleaseDate: pastDate,
        platforms: const [],
      );

      expect(game.countdownText, 'Released');
      expect(game.isReleased, true);
    });

    test('platformNames returns comma-separated string', () {
      final game = AnticipatedGame(
        id: 1,
        name: 'Test',
        coverUrl: '',
        hypes: 0,
        firstReleaseDate: DateTime.now().add(const Duration(days: 1)),
        platforms: const [
          GamePlatform(id: 1, name: 'PC'),
          GamePlatform(id: 2, name: 'PlayStation 5'),
        ],
      );

      expect(game.platformNames, 'PC, PlayStation 5');
    });

    test('toJson produces correct output', () {
      final game = AnticipatedGame(
        id: 1,
        name: 'Test',
        coverUrl: 'https://example.com/cover.jpg',
        hypes: 100,
        firstReleaseDate: DateTime.fromMillisecondsSinceEpoch(1795046400000),
        platforms: const [GamePlatform(id: 1, name: 'PC')],
      );

      final json = game.toJson();

      expect(json['id'], 1);
      expect(json['name'], 'Test');
      expect(json['cover_url'], 'https://example.com/cover.jpg');
      expect(json['hypes'], 100);
      expect(json['first_release_date'], 1795046400);
      expect(json['platforms'], isA<List<dynamic>>());
    });
  });
}
