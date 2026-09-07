import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/core/data/services/http/i_http_client.dart';
import 'package:picklog/core/domain/models/api_response.dart';
import 'package:picklog/features/games/games_repository.dart';

class MockHttpClient extends Mock implements IHttpClient {}

void main() {
  late MockHttpClient mockHttp;
  late GamesRepository repository;

  setUp(() {
    mockHttp = MockHttpClient();
    repository = GamesRepository(httpClient: mockHttp);
  });

  group('GamesRepository.getGenres', () {
    test('parses the genres list', () async {
      when(
        () => mockHttp.get<Map<String, dynamic>>('/games/genres'),
      ).thenAnswer(
        (_) async => ApiResponse.success(const {
          'genres': [
            {
              'id': 12,
              'name': 'Role-playing (RPG)',
              'slug': 'role-playing-rpg',
            },
            {'id': 31, 'name': 'Adventure', 'slug': 'adventure'},
          ],
        }),
      );

      final genres = await repository.getGenres();

      expect(genres, hasLength(2));
      expect(genres.first.id, 12);
      expect(genres.first.name, 'Role-playing (RPG)');
    });
  });

  group('GamesRepository.getGamesByGenre', () {
    test('sends type=by_genre with the genre_id query param', () async {
      when(
        () => mockHttp.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => ApiResponse.success(const {
          'games': <dynamic>[],
          'type': 'by_genre',
          'total_count': 0,
          'has_more': false,
          'offset': 0,
          'limit': 40,
        }),
      );

      await repository.getGamesByGenre(12, limit: 40);

      final captured =
          verify(
                () => mockHttp.get<Map<String, dynamic>>(
                  '/games/discovery',
                  queryParameters: captureAny(named: 'queryParameters'),
                ),
              ).captured.single
              as Map<String, dynamic>;

      expect(captured['type'], 'by_genre');
      expect(captured['genre_id'], '12');
      expect(captured['limit'], '40');
    });
  });
}
