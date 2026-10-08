import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/core/data/services/http/i_http_client.dart';
import 'package:picklog/core/domain/models/api_error.dart';
import 'package:picklog/core/domain/models/api_response.dart';
import 'package:picklog/features/integrations/integrations_models.dart';
import 'package:picklog/features/integrations/integrations_repository.dart';

class _MockHttpClient extends Mock implements IHttpClient {}

ApiError _error(int status, String code) => ApiError(
  name: 'Error',
  message: 'Server text',
  action: 'Retry',
  statusCode: status,
  errorCode: code,
);

Map<String, dynamic> _account({String status = 'ok'}) => {
  'external_id': '765',
  'display_name': 'Hornet',
  'avatar_url': 'https://example.com/a.jpg',
  'linked_at': '2026-10-01T00:00:00Z',
  'last_synced_at': '2026-10-02T00:00:00Z',
  'sync_status': status,
};

void main() {
  late _MockHttpClient http;
  late IntegrationsRepository repository;

  setUp(() {
    http = _MockHttpClient();
    repository = IntegrationsRepository(httpClient: http);
  });

  test('getLinkedAccounts parses every provider', () async {
    when(
      () => http.get<Map<String, dynamic>>('/users/me/linked-accounts'),
    ).thenAnswer(
      (_) async => ApiResponse.success({
        'providers': [
          {
            'provider': 'steam',
            'available': true,
            'experimental': false,
            'linked': true,
            'account': _account(status: 'syncing'),
          },
          const {
            'provider': 'xbox',
            'available': false,
            'experimental': false,
            'linked': false,
          },
          const {
            'provider': 'retroachievements',
            'available': true,
            'experimental': false,
            'linked': false,
          },
          const {
            'provider': 'psn',
            'available': true,
            'experimental': true,
            'linked': false,
          },
          const {'provider': 'future', 'available': true, 'linked': false},
        ],
      }),
    );

    final list = await repository.getLinkedAccounts();

    expect(list.map((p) => p.provider), [
      GameProvider.steam,
      GameProvider.xbox,
      GameProvider.retroAchievements,
      GameProvider.psn,
    ]);
    expect(list.first.isSyncing, isTrue);
    expect(list.first.account!.displayName, 'Hornet');
    expect(list.first.account!.lastSyncedAt, DateTime.utc(2026, 10, 2));
    expect(list[1].available, isFalse);
    expect(list[3].experimental, isTrue);
    expect(list[3].isLinked, isFalse);
  });

  test('link posts the provider and the trimmed identifier', () async {
    when(
      () => http.post<Map<String, dynamic>>(
        '/users/me/linked-accounts',
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) async => ApiResponse.success(_account()));

    final account = await repository.link(GameProvider.steam, '  hornet ');

    expect(account.externalId, '765');
    verify(
      () => http.post<Map<String, dynamic>>(
        '/users/me/linked-accounts',
        data: {'provider': 'steam', 'identifier': 'hornet'},
      ),
    ).called(1);
  });

  test('unlink deletes the provider', () async {
    when(
      () => http.delete<void>('/users/me/linked-accounts/retroachievements'),
    ).thenAnswer((_) async => ApiResponse<void>.success(null));

    await repository.unlink(GameProvider.retroAchievements);

    verify(
      () => http.delete<void>('/users/me/linked-accounts/retroachievements'),
    ).called(1);
  });

  test('sync posts import_library', () async {
    when(
      () => http.post<Map<String, dynamic>>(
        '/users/me/linked-accounts/xbox/sync',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => ApiResponse.success(const {'sync_status': 'syncing'}),
    );

    await repository.sync(GameProvider.xbox, importLibrary: true);

    verify(
      () => http.post<Map<String, dynamic>>(
        '/users/me/linked-accounts/xbox/sync',
        data: {'import_library': true},
      ),
    ).called(1);
  });

  test('getSummary parses totals, recent unlocks and games', () async {
    when(
      () => http.get<Map<String, dynamic>>('/users/me/achievements/summary'),
    ).thenAnswer(
      (_) async => ApiResponse.success(const {
        'total_unlocked': 55,
        'total_available': 164,
        'completion_pct': 33.5,
        'by_provider': [
          {'provider': 'steam', 'unlocked': 45, 'total': 64, 'games': 2},
        ],
        'recent': [
          {
            'provider': 'steam',
            'external_game_id': '1',
            'game_name': 'Hades',
            'achievement_name': 'Escaped',
            'unlocked_at': '2026-10-05T00:00:00Z',
            'rarity_pct': 4.2,
          },
        ],
        'games': [
          {
            'provider': 'steam',
            'external_game_id': '1',
            'name': 'Hades',
            'igdb_id': 113112,
            'unlocked': 30,
            'total': 49,
            'completion_pct': 61.2,
            'last_played_at': '2026-10-05T00:00:00Z',
          },
        ],
      }),
    );

    final summary = await repository.getSummary();

    expect(summary.totalUnlocked, 55);
    expect(summary.completionPct, 33.5);
    expect(summary.byProvider.single.games, 2);
    expect(summary.recent.single.rarityPct, 4.2);
    expect(summary.games.single.igdbId, 113112);
    expect(summary.games.single.fraction, closeTo(0.612, 0.001));
    expect(summary.isEmpty, isFalse);
  });

  test('getGameAchievements encodes the external id', () async {
    when(
      () => http.get<Map<String, dynamic>>(
        '/users/me/achievements/games/psn/NPWR%2F1',
      ),
    ).thenAnswer(
      (_) async => ApiResponse.success(const {
        'provider': 'psn',
        'external_game_id': 'NPWR/1',
        'name': 'Astro Bot',
        'unlocked': 1,
        'total': 2,
        'completion_pct': 50,
        'achievements': [
          {'id': 'a', 'name': 'One', 'unlocked': true},
          {'id': 'b', 'name': 'Two', 'unlocked': false},
        ],
      }),
    );

    final game = await repository.getGameAchievements(
      GameProvider.psn,
      'NPWR/1',
    );

    expect(game.game.name, 'Astro Bot');
    expect(game.achievements, hasLength(2));
    expect(game.sorted.first.unlocked, isTrue);
  });

  test('getAchievementsForGame returns an empty list when unmapped', () async {
    when(
      () => http.get<Map<String, dynamic>>('/games/42/achievements'),
    ).thenAnswer((_) async => ApiResponse.success(const {'games': []}));

    expect(await repository.getAchievementsForGame(42), isEmpty);
  });

  group('error mapping', () {
    final cases = <(ApiError, IntegrationErrorKind)>[
      (
        _error(404, 'error.integration.account_not_found'),
        IntegrationErrorKind.accountNotFound,
      ),
      (
        _error(422, 'error.integration.private_profile'),
        IntegrationErrorKind.privateProfile,
      ),
      (
        _error(429, 'error.integration.sync_too_soon'),
        IntegrationErrorKind.syncTooSoon,
      ),
      (
        _error(503, 'error.integration.unavailable'),
        IntegrationErrorKind.unavailable,
      ),
      (
        _error(400, 'error.validation.integration.identifier.invalid'),
        IntegrationErrorKind.invalidIdentifier,
      ),
      (
        _error(502, 'error.integration.upstream'),
        IntegrationErrorKind.upstream,
      ),
      (_error(0, 'error.network.connection'), IntegrationErrorKind.network),
      (_error(500, 'error.server.database'), IntegrationErrorKind.unknown),
    ];

    for (final (error, kind) in cases) {
      test('${error.errorCode} maps to $kind', () async {
        when(
          () => http.post<Map<String, dynamic>>(
            '/users/me/linked-accounts',
            data: any(named: 'data'),
          ),
        ).thenAnswer((_) async => ApiResponse.failure(error));

        await expectLater(
          repository.link(GameProvider.steam, 'x'),
          throwsA(
            isA<IntegrationException>().having((e) => e.kind, 'kind', kind),
          ),
        );
      });
    }
  });
}
