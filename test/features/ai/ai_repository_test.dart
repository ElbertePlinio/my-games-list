import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/core/data/services/http/i_http_client.dart';
import 'package:picklog/core/domain/models/api_error.dart';
import 'package:picklog/core/domain/models/api_response.dart';
import 'package:picklog/core/domain/models/app_failure.dart';
import 'package:picklog/features/ai/ai_models.dart';
import 'package:picklog/features/ai/ai_repository.dart';

class _MockHttpClient extends Mock implements IHttpClient {}

ApiError _error(int status, String code) => ApiError(
  name: 'Error',
  message: 'Server text',
  action: 'Retry',
  statusCode: status,
  errorCode: code,
);

void main() {
  late _MockHttpClient http;
  late AiRepository repository;

  setUp(() {
    http = _MockHttpClient();
    repository = AiRepository(httpClient: http);
  });

  group('getStatus', () {
    test('parses the status response', () async {
      when(() => http.get<Map<String, dynamic>>('/ai/status')).thenAnswer(
        (_) async => ApiResponse.success(const {
          'enabled': true,
          'consented': false,
          'daily_limit': 20,
          'used_today': 3,
          'model': 'gpt-6-luna',
        }),
      );

      final status = await repository.getStatus();

      expect(status.enabled, isTrue);
      expect(status.consented, isFalse);
      expect(status.dailyLimit, 20);
      expect(status.usedToday, 3);
      expect(status.remainingToday, 17);
      expect(status.model, 'gpt-6-luna');
    });
  });

  group('setConsent', () {
    test('sends granted and parses consented_at', () async {
      when(
        () => http.put<Map<String, dynamic>>(
          '/users/me/ai-consent',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => ApiResponse.success(const {
          'consented': true,
          'consented_at': '2026-10-08T10:00:00Z',
        }),
      );

      final result = await repository.setConsent(granted: true);

      expect(result.consented, isTrue);
      expect(result.consentedAt, DateTime.utc(2026, 10, 8, 10));
      verify(
        () => http.put<Map<String, dynamic>>(
          '/users/me/ai-consent',
          data: {'granted': true},
        ),
      ).called(1);
    });

    test('revoking returns a null consented_at', () async {
      when(
        () => http.put<Map<String, dynamic>>(
          '/users/me/ai-consent',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => ApiResponse.success(const {
          'consented': false,
          'consented_at': null,
        }),
      );

      final result = await repository.setConsent(granted: false);

      expect(result.consented, isFalse);
      expect(result.consentedAt, isNull);
    });
  });

  group('playNext', () {
    test('sends only the fields that are set and parses picks', () async {
      when(
        () => http.post<Map<String, dynamic>>(
          '/ai/play-next',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => ApiResponse.success(const {
          'picks': [
            {
              'library_entry_id': 'e1',
              'game': {'igdb_id': 7, 'name': 'Hades', 'cover_url': 'c.jpg'},
              'reason': 'Fits your evening.',
              'estimated_session_minutes': 40,
            },
          ],
          'model': 'gpt-6-luna',
          'generated_at': '2026-10-08T20:00:00Z',
          'remaining_today': 15,
        }),
      );

      final result = await repository.playNext(
        const PlayNextRequest(
          minutesAvailable: 60,
          mood: AiMood.chill,
          note: '  one hand  ',
        ),
      );

      expect(result.picks, hasLength(1));
      expect(result.picks.first.libraryEntryId, 'e1');
      expect(result.picks.first.game.igdbId, 7);
      expect(result.picks.first.game.coverUrl, 'c.jpg');
      expect(result.picks.first.estimatedSessionMinutes, 40);
      expect(result.remainingToday, 15);
      expect(result.generatedAt, DateTime.utc(2026, 10, 8, 20));
      verify(
        () => http.post<Map<String, dynamic>>(
          '/ai/play-next',
          data: {'minutes_available': 60, 'mood': 'chill', 'note': 'one hand'},
        ),
      ).called(1);
    });

    test('an empty backlog returns no picks', () async {
      when(
        () => http.post<Map<String, dynamic>>(
          '/ai/play-next',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async =>
            ApiResponse.success(const {'picks': [], 'remaining_today': 20}),
      );

      final result = await repository.playNext(const PlayNextRequest());

      expect(result.picks, isEmpty);
      verify(
        () => http.post<Map<String, dynamic>>(
          '/ai/play-next',
          data: <String, dynamic>{},
        ),
      ).called(1);
    });
  });

  group('discover', () {
    test('sends a trimmed prompt and parses picks', () async {
      when(
        () => http.post<Map<String, dynamic>>(
          '/ai/discover',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => ApiResponse.success(const {
          'picks': [
            {
              'game': {
                'id': 10,
                'name': 'Stardew Valley',
                'cover_url': '',
                'total_rating': 88.4,
                'first_release_date': '2016-02-26T00:00:00Z',
              },
              'reason': 'Calm farming.',
            },
          ],
          'remaining_today': 12,
        }),
      );

      final result = await repository.discover(prompt: '  cozy  ');

      final game = result.picks.single.game;
      expect(game.id, 10);
      expect(game.coverUrl, isNull);
      expect(game.totalRating, 88.4);
      expect(game.firstReleaseDate?.year, 2016);
      expect(result.remainingToday, 12);
      verify(
        () => http.post<Map<String, dynamic>>(
          '/ai/discover',
          data: {'prompt': 'cozy'},
        ),
      ).called(1);
    });
  });

  group('error mapping', () {
    final cases = <(ApiError, AiErrorKind)>[
      (_error(503, 'error.ai.unavailable'), AiErrorKind.unavailable),
      (_error(403, 'error.ai.consent_required'), AiErrorKind.consentRequired),
      (_error(429, 'error.ai.quota_exceeded'), AiErrorKind.quotaExceeded),
      (_error(502, 'error.ai.upstream'), AiErrorKind.upstream),
      (_error(408, 'error.network.timeout'), AiErrorKind.network),
      (_error(429, 'error.api.unknown'), AiErrorKind.quotaExceeded),
      (_error(500, 'error.server.database'), AiErrorKind.unknown),
    ];

    for (final (error, kind) in cases) {
      test('${error.statusCode} ${error.errorCode} maps to $kind', () async {
        when(
          () => http.post<Map<String, dynamic>>(
            '/ai/play-next',
            data: any(named: 'data'),
          ),
        ).thenAnswer((_) async => ApiResponse.failure(error));

        await expectLater(
          repository.playNext(const PlayNextRequest()),
          throwsA(isA<AiException>().having((e) => e.kind, 'kind', kind)),
        );
      });
    }

    test('status errors also throw a typed exception', () async {
      when(() => http.get<Map<String, dynamic>>('/ai/status')).thenAnswer(
        (_) async => ApiResponse.failure(_error(503, 'error.ai.unavailable')),
      );

      await expectLater(
        repository.getStatus(),
        throwsA(
          isA<AiException>().having(
            (e) => e.kind,
            'kind',
            AiErrorKind.unavailable,
          ),
        ),
      );
    });

    test('from maps ApiException and unknown objects', () {
      expect(
        AiErrorKind.from(ApiException(_error(429, 'error.ai.quota_exceeded'))),
        AiErrorKind.quotaExceeded,
      );
      expect(AiErrorKind.from(Exception('boom')), AiErrorKind.unknown);
    });
  });
}
