import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/core/data/services/http/i_http_client.dart';
import 'package:picklog/core/domain/models/api_error.dart';
import 'package:picklog/core/domain/models/api_response.dart';
import 'package:picklog/features/library/library_entry_model.dart';
import 'package:picklog/features/library/library_repository.dart';

class MockHttpClient extends Mock implements IHttpClient {}

void main() {
  late LibraryRepository repository;
  late MockHttpClient mockHttpClient;

  setUp(() {
    mockHttpClient = MockHttpClient();
    repository = LibraryRepository(httpClient: mockHttpClient);
  });

  final mockLibraryEntry = {
    'id': 'entry-uuid-1',
    'user_id': 'user-uuid-1',
    'game': {
      'id': 'game-uuid-1',
      'igdb_id': 1942,
      'name': 'The Witcher 3: Wild Hunt',
      'cover_url':
          'https://images.igdb.com/igdb/image/upload/t_cover_big/co1wyy.jpg',
      'first_release_date': '2015-05-19T00:00:00Z',
      'last_synced_at': '2026-01-27T10:00:00Z',
    },
    'platform': {
      'id': 'platform-uuid-1',
      'igdb_platform_id': 6,
      'name': 'PC (Microsoft Windows)',
      'abbreviation': 'PC',
      'logo_url': null,
    },
    'status': 'finished',
    'score': 95,
    'playtime_minutes': 1200,
    'start_date': '2024-01-01',
    'end_date': '2024-02-15',
    'difficulty': 'Normal',
    'is_favorite': true,
    'notes': 'Amazing game!',
    'created_at': '2024-01-01T00:00:00Z',
    'updated_at': '2024-02-15T00:00:00Z',
  };

  group('LibraryRepository', () {
    group('getLibrary', () {
      test('returns list of entries on successful response', () async {
        // Arrange
        final mockResponse = {
          'entries': [mockLibraryEntry],
          'total_count': 1,
        };

        when(
          () => mockHttpClient.get<Map<String, dynamic>>(
            '/users/user-uuid-1/library',
          ),
        ).thenAnswer((_) async => ApiResponse.success(mockResponse));

        // Act
        final entries = await repository.getLibrary('user-uuid-1');

        // Assert
        expect(entries, isA<List<LibraryEntry>>());
        expect(entries.length, 1);
        expect(entries[0].id, 'entry-uuid-1');
        expect(entries[0].game.name, 'The Witcher 3: Wild Hunt');
        expect(entries[0].status, GameStatus.finished);
        expect(entries[0].isFavorite, true);
        expect(entries[0].score, 95);

        verify(
          () => mockHttpClient.get<Map<String, dynamic>>(
            '/users/user-uuid-1/library',
          ),
        ).called(1);
      });

      test('applies favorites_only filter correctly', () async {
        // Arrange
        final mockResponse = {
          'entries': [mockLibraryEntry],
          'total_count': 1,
        };

        when(
          () => mockHttpClient.get<Map<String, dynamic>>(
            '/users/user-uuid-1/library?favorites_only=true',
          ),
        ).thenAnswer((_) async => ApiResponse.success(mockResponse));

        // Act
        final entries = await repository.getLibrary(
          'user-uuid-1',
          favoritesOnly: true,
        );

        // Assert
        expect(entries.length, 1);
        verify(
          () => mockHttpClient.get<Map<String, dynamic>>(
            '/users/user-uuid-1/library?favorites_only=true',
          ),
        ).called(1);
      });

      test('applies status filter correctly', () async {
        // Arrange
        final mockResponse = {
          'entries': [mockLibraryEntry],
          'total_count': 1,
        };

        when(
          () => mockHttpClient.get<Map<String, dynamic>>(
            '/users/user-uuid-1/library?status=playing',
          ),
        ).thenAnswer((_) async => ApiResponse.success(mockResponse));

        // Act
        final entries = await repository.getLibrary(
          'user-uuid-1',
          status: GameStatus.playing,
        );

        // Assert
        expect(entries.length, 1);
        verify(
          () => mockHttpClient.get<Map<String, dynamic>>(
            '/users/user-uuid-1/library?status=playing',
          ),
        ).called(1);
      });

      test('throws exception on error response', () async {
        // Arrange
        when(
          () => mockHttpClient.get<Map<String, dynamic>>(
            '/users/user-uuid-1/library',
          ),
        ).thenAnswer(
          (_) async => ApiResponse<Map<String, dynamic>>.failure(
            const ApiError(
              name: 'Unauthorized',
              message: 'You must be authenticated',
              action: 'Please sign in',
              statusCode: 401,
              errorCode: 'error.auth.unauthorized',
            ),
          ),
        );

        // Act & Assert
        expect(() => repository.getLibrary('user-uuid-1'), throwsException);
      });
    });

    group('addToLibrary', () {
      test('adds game successfully with all parameters', () async {
        // Arrange
        when(
          () => mockHttpClient.post<Map<String, dynamic>>(
            '/library',
            data: any(named: 'data'),
          ),
        ).thenAnswer((_) async => ApiResponse.success(mockLibraryEntry));

        // Act
        final entry = await repository.addToLibrary(
          igdbId: 1942,
          status: GameStatus.playing,
          igdbPlatformId: 6,
          score: 80,
          playtimeMinutes: 120,
          isFavorite: true,
        );

        // Assert
        expect(entry, isA<LibraryEntry>());
        expect(entry.game.igdbId, 1942);

        verify(
          () => mockHttpClient.post<Map<String, dynamic>>(
            '/library',
            data: {
              'igdb_id': 1942,
              'status': 'playing',
              'is_favorite': true,
              'igdb_platform_id': 6,
              'score': 80,
              'playtime_minutes': 120,
            },
          ),
        ).called(1);
      });

      test('adds game with minimal parameters', () async {
        // Arrange
        when(
          () => mockHttpClient.post<Map<String, dynamic>>(
            '/library',
            data: any(named: 'data'),
          ),
        ).thenAnswer((_) async => ApiResponse.success(mockLibraryEntry));

        // Act
        final entry = await repository.addToLibrary(
          igdbId: 1942,
          status: GameStatus.planned,
        );

        // Assert
        expect(entry, isA<LibraryEntry>());

        verify(
          () => mockHttpClient.post<Map<String, dynamic>>(
            '/library',
            data: {'igdb_id': 1942, 'status': 'planned', 'is_favorite': false},
          ),
        ).called(1);
      });
    });

    group('toggleFavorite', () {
      test('toggles favorite successfully', () async {
        // Arrange
        final toggledEntry = Map<String, dynamic>.from(mockLibraryEntry);
        toggledEntry['is_favorite'] = false;

        when(
          () => mockHttpClient.post<Map<String, dynamic>>(
            '/library/entry-uuid-1/favorite',
          ),
        ).thenAnswer((_) async => ApiResponse.success(toggledEntry));

        // Act
        final entry = await repository.toggleFavorite('entry-uuid-1');

        // Assert
        expect(entry.isFavorite, false);

        verify(
          () => mockHttpClient.post<Map<String, dynamic>>(
            '/library/entry-uuid-1/favorite',
          ),
        ).called(1);
      });
    });

    group('updateLibraryEntry', () {
      test('updates entry with partial data', () async {
        // Arrange
        final updatedEntry = Map<String, dynamic>.from(mockLibraryEntry);
        updatedEntry['score'] = 100;
        updatedEntry['status'] = 'finished';

        when(
          () => mockHttpClient.put<Map<String, dynamic>>(
            '/library/entry-uuid-1',
            data: any(named: 'data'),
          ),
        ).thenAnswer((_) async => ApiResponse.success(updatedEntry));

        // Act
        final entry = await repository.updateLibraryEntry(
          entryId: 'entry-uuid-1',
          score: 100,
          status: GameStatus.finished,
        );

        // Assert
        expect(entry.score, 100);
        expect(entry.status, GameStatus.finished);

        verify(
          () => mockHttpClient.put<Map<String, dynamic>>(
            '/library/entry-uuid-1',
            data: {'score': 100, 'status': 'finished'},
          ),
        ).called(1);
      });
    });

    group('deleteLibraryEntry', () {
      test('deletes entry successfully', () async {
        // Arrange
        when(
          () => mockHttpClient.delete<Map<String, dynamic>>(
            '/library/entry-uuid-1',
          ),
        ).thenAnswer(
          (_) async => ApiResponse.success(const {'message': 'Deleted'}),
        );

        // Act & Assert - should not throw
        await expectLater(
          repository.deleteLibraryEntry('entry-uuid-1'),
          completes,
        );

        verify(
          () => mockHttpClient.delete<Map<String, dynamic>>(
            '/library/entry-uuid-1',
          ),
        ).called(1);
      });
    });
  });

  group('LibraryEntry model', () {
    test('fromJson parses all fields correctly', () {
      final entry = LibraryEntry.fromJson(mockLibraryEntry);

      expect(entry.id, 'entry-uuid-1');
      expect(entry.userId, 'user-uuid-1');
      expect(entry.game.igdbId, 1942);
      expect(entry.game.name, 'The Witcher 3: Wild Hunt');
      expect(entry.platform?.abbreviation, 'PC');
      expect(entry.status, GameStatus.finished);
      expect(entry.score, 95);
      expect(entry.playtimeMinutes, 1200);
      expect(entry.isFavorite, true);
      expect(entry.notes, 'Amazing game!');
    });

    test('playtimeFormatted returns correct format', () {
      final entry = LibraryEntry.fromJson(mockLibraryEntry);
      expect(entry.playtimeFormatted, '20.0 hrs');

      // Test with 0 playtime
      final noPlaytimeEntry = {...mockLibraryEntry, 'playtime_minutes': 0};
      final entry2 = LibraryEntry.fromJson(noPlaytimeEntry);
      expect(entry2.playtimeFormatted, '0 hrs');

      // Test with minutes only (less than 1 hour)
      final shortPlaytimeEntry = {...mockLibraryEntry, 'playtime_minutes': 45};
      final entry3 = LibraryEntry.fromJson(shortPlaytimeEntry);
      expect(entry3.playtimeFormatted, '45 min');
    });

    test('copyWith creates correct copy', () {
      final entry = LibraryEntry.fromJson(mockLibraryEntry);
      final copy = entry.copyWith(isFavorite: false, score: 100);

      expect(copy.isFavorite, false);
      expect(copy.score, 100);
      expect(copy.game.name, entry.game.name); // Unchanged
      expect(copy.status, entry.status); // Unchanged
    });
  });

  group('GameStatus', () {
    test('fromString parses all statuses', () {
      expect(GameStatus.fromString('planned'), GameStatus.planned);
      expect(GameStatus.fromString('playing'), GameStatus.playing);
      expect(GameStatus.fromString('finished'), GameStatus.finished);
      expect(GameStatus.fromString('dropped'), GameStatus.dropped);
      expect(GameStatus.fromString('on_hold'), GameStatus.onHold);
      expect(GameStatus.fromString('unknown'), GameStatus.planned); // Default
    });

    test('toApiString returns correct strings', () {
      expect(GameStatus.planned.toApiString(), 'planned');
      expect(GameStatus.playing.toApiString(), 'playing');
      expect(GameStatus.finished.toApiString(), 'finished');
      expect(GameStatus.dropped.toApiString(), 'dropped');
      expect(GameStatus.onHold.toApiString(), 'on_hold');
    });

    test('displayName returns user-friendly names', () {
      expect(GameStatus.planned.displayName, 'Planned');
      expect(GameStatus.playing.displayName, 'Playing');
      expect(GameStatus.finished.displayName, 'Finished');
      expect(GameStatus.dropped.displayName, 'Dropped');
      expect(GameStatus.onHold.displayName, 'On Hold');
    });
  });
}
