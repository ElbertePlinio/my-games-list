import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/core/data/services/http/i_http_client.dart';
import 'package:picklog/core/domain/models/api_error.dart';
import 'package:picklog/core/domain/models/api_response.dart';
import 'package:picklog/core/domain/models/app_failure.dart';
import 'package:picklog/features/library/library_entry_model.dart';
import 'package:picklog/features/library/library_query.dart';
import 'package:picklog/features/library/library_repository.dart';

import 'library_fixtures.dart';

class _MockHttp extends Mock implements IHttpClient {}

void main() {
  late _MockHttp http;
  late LibraryRepository repository;

  setUp(() {
    http = _MockHttp();
    repository = LibraryRepository(httpClient: http);
  });

  test('queryLibrary sends the filters as query parameters', () async {
    when(
      () => http.get<Map<String, dynamic>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => ApiResponse.success({
        'entries': [entryJson()],
        'total_count': 120,
      }),
    );

    final response = await repository.queryLibrary(
      'user-1',
      const LibraryFilters(
        statuses: {GameStatus.planned},
        sort: LibrarySort.nameAsc,
      ),
      limit: 50,
      offset: 50,
    );

    expect(response.totalCount, 120);
    expect(response.entries.single.game.genres, isNotEmpty);
    verify(
      () => http.get<Map<String, dynamic>>(
        '/users/user-1/library',
        queryParameters: {
          'status': 'planned',
          'sort': 'name_asc',
          'limit': '50',
          'offset': '50',
        },
      ),
    ).called(1);
  });

  test('queryLibrary throws an ApiException with the API error', () async {
    const error = ApiError(
      name: 'Validation',
      message: 'bad',
      action: 'fix',
      statusCode: 400,
      errorCode: 'error.validation.sort.invalid',
    );
    when(
      () => http.get<Map<String, dynamic>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer((_) async => ApiResponse.failure(error));

    expect(
      () => repository.queryLibrary('user-1', const LibraryFilters()),
      throwsA(isA<ApiException>().having((e) => e.error, 'error', error)),
    );
  });
}
