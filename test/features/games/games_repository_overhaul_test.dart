import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/core/data/services/http/i_http_client.dart';
import 'package:picklog/core/domain/models/api_response.dart';
import 'package:picklog/features/games/catalog_filters.dart';
import 'package:picklog/features/games/discovery_game_model.dart';
import 'package:picklog/features/games/games_repository.dart';

class _MockHttp extends Mock implements IHttpClient {}

void main() {
  late _MockHttp http;
  late GamesRepository repo;

  setUp(() {
    http = _MockHttp();
    repo = GamesRepository(httpClient: http);
  });

  test('exploreGames sends the filters and parses dates and genres', () async {
    when(
      () => http.get<Map<String, dynamic>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => ApiResponse.success(const {
        'games': [
          {
            'id': 1,
            'name': 'Hades II',
            'cover_url': 'c',
            'total_rating': 91.2,
            'first_release_date': '2025-09-25T00:00:00Z',
            'genres': [
              {'id': 12, 'name': 'RPG'},
            ],
          },
        ],
        'type': 'explore',
        'total_count': 1,
        'has_more': false,
        'offset': 0,
        'limit': 30,
      }),
    );

    final page = await repo.exploreGames(
      const ExploreFilters(
        catalog: CatalogFilters(platformIds: {6}, yearTo: 2025),
        sort: ExploreSort.newest,
      ),
      limit: 30,
    );

    expect(page.games.single.releaseYear, 2025);
    expect(page.games.single.genres.single.name, 'RPG');
    verify(
      () => http.get<Map<String, dynamic>>(
        '/games/explore',
        queryParameters: {
          'platform_ids': '6',
          'year_to': '2025',
          'sort': 'newest',
          'limit': '30',
          'offset': '0',
        },
      ),
    ).called(1);
  });

  test('getPlatforms parses the curated list', () async {
    when(() => http.get<Map<String, dynamic>>(any())).thenAnswer(
      (_) async => ApiResponse.success(const {
        'platforms': [
          {'id': 167, 'name': 'PlayStation 5', 'abbreviation': 'PS5'},
          {'id': 3, 'name': 'Linux', 'abbreviation': ''},
        ],
      }),
    );
    final platforms = await repo.getPlatforms();
    expect(platforms.map((p) => p.label), ['PS5', 'Linux']);
    verify(() => http.get<Map<String, dynamic>>('/games/platforms'));
  });

  test('searchGames adds the filter fields to the body', () async {
    when(
      () => http.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
    ).thenAnswer(
      (_) async => ApiResponse.success(const {
        'games': <dynamic>[],
        'total_count': 0,
        'has_more': false,
        'offset': 0,
        'limit': 20,
      }),
    );
    await repo.searchGames(
      'zelda',
      filters: const CatalogFilters(genreIds: {31}, minRating: 75),
    );
    verify(
      () => http.post<Map<String, dynamic>>(
        '/games/search',
        data: {
          'query': 'zelda',
          'limit': 20,
          'offset': 0,
          'genre_ids': [31],
          'min_rating': 75,
        },
      ),
    ).called(1);
  });

  group('recommendation reasons', () {
    DiscoveryGame parse(Object? reason) =>
        DiscoveryGame.fromJson({'id': 1, 'name': 'x', 'reason': reason});

    test('parses each type and ignores unknown ones', () {
      expect(
        parse({'type': 'similar', 'source_game_name': 'Hades'}).reason,
        const RecommendationReason(
          type: RecommendationReasonType.similar,
          sourceGameName: 'Hades',
        ),
      );
      expect(
        parse({'type': 'genre', 'genre_name': 'RPG'}).reason?.genreName,
        'RPG',
      );
      expect(
        parse({'type': 'popular'}).reason?.type,
        RecommendationReasonType.popular,
      );
      expect(parse({'type': 'mystery'}).reason, isNull);
      expect(parse(null).reason, isNull);
    });
  });
}
