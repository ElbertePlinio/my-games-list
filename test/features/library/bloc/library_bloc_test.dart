import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picklog/core/data/services/http/i_http_client.dart';
import 'package:picklog/core/domain/models/api_response.dart';
import 'package:picklog/core/domain/models/app_failure.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/features/library/bloc/library_bloc.dart';
import 'package:picklog/features/library/bloc/library_event.dart';
import 'package:picklog/features/library/bloc/library_state.dart';
import 'package:picklog/features/library/library_entry_model.dart';
import 'package:picklog/features/library/library_repository.dart';

class MockLibraryRepository extends Mock implements LibraryRepository {}

class MockHttpClient extends Mock implements IHttpClient {}

void main() {
  late MockLibraryRepository mockRepository;

  setUp(() {
    mockRepository = MockLibraryRepository();
  });

  final mockGame = CachedGame(
    id: 'game-uuid-1',
    igdbId: 1942,
    name: 'The Witcher 3: Wild Hunt',
    coverUrl:
        'https://images.igdb.com/igdb/image/upload/t_cover_big/co1wyy.jpg',
    firstReleaseDate: DateTime(2015, 5, 19),
    lastSyncedAt: DateTime.now(),
  );

  const mockPlatform = CachedPlatform(
    id: 'platform-uuid-1',
    igdbPlatformId: 6,
    name: 'PC (Microsoft Windows)',
    abbreviation: 'PC',
  );

  final mockEntries = [
    LibraryEntry(
      id: 'entry-uuid-1',
      userId: 'user-uuid-1',
      game: mockGame,
      platform: mockPlatform,
      status: GameStatus.finished,
      score: 95,
      playtimeMinutes: 1200,
      startDate: DateTime(2024, 1, 1),
      endDate: DateTime(2024, 2, 15),
      difficulty: 'Normal',
      isFavorite: true,
      notes: 'Amazing game!',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 2, 15),
    ),
    LibraryEntry(
      id: 'entry-uuid-2',
      userId: 'user-uuid-1',
      game: CachedGame(
        id: 'game-uuid-2',
        igdbId: 1020,
        name: 'Grand Theft Auto V',
        coverUrl:
            'https://images.igdb.com/igdb/image/upload/t_cover_big/co1tnw.jpg',
        lastSyncedAt: DateTime.now(),
      ),
      status: GameStatus.playing,
      score: null,
      playtimeMinutes: 500,
      isFavorite: false,
      createdAt: DateTime(2024, 3, 1),
      updatedAt: DateTime(2024, 3, 15),
    ),
  ];

  group('LibraryBloc', () {
    group('LibraryLoadRequested', () {
      blocTest<LibraryBloc, LibraryState>(
        'emits [loading, success] when load is requested successfully',
        build: () {
          when(
            () => mockRepository.getLibrary('user-uuid-1'),
          ).thenAnswer((_) async => mockEntries);
          return LibraryBloc(libraryRepository: mockRepository);
        },
        act: (bloc) =>
            bloc.add(const LibraryLoadRequested(userId: 'user-uuid-1')),
        expect: () => [
          predicate<LibraryState>(
            (state) =>
                state.status == LibraryStatus.loading &&
                state.userId == 'user-uuid-1',
          ),
          predicate<LibraryState>(
            (state) =>
                state.status == LibraryStatus.success &&
                state.entries.length == 2 &&
                state.entries[0].game.name == 'The Witcher 3: Wild Hunt',
          ),
        ],
        verify: (_) {
          verify(() => mockRepository.getLibrary('user-uuid-1')).called(1);
        },
      );

      blocTest<LibraryBloc, LibraryState>(
        'emits [loading, failure] when load fails',
        build: () {
          when(
            () => mockRepository.getLibrary('user-uuid-1'),
          ).thenThrow(Exception('Network error'));
          return LibraryBloc(libraryRepository: mockRepository);
        },
        act: (bloc) =>
            bloc.add(const LibraryLoadRequested(userId: 'user-uuid-1')),
        expect: () => [
          predicate<LibraryState>(
            (state) => state.status == LibraryStatus.loading,
          ),
          predicate<LibraryState>(
            (state) =>
                state.status == LibraryStatus.failure &&
                state.failure ==
                    const LibraryFailure(
                      LibraryAction.load,
                      AppErrorKind.unknown,
                    ),
          ),
        ],
      );
    });

    group('LibraryToggleFavoriteRequested', () {
      blocTest<LibraryBloc, LibraryState>(
        'optimistically toggles favorite and keeps state on success',
        build: () {
          when(
            () => mockRepository.toggleFavorite('entry-uuid-1'),
          ).thenAnswer((_) async => mockEntries[0].copyWith(isFavorite: false));
          return LibraryBloc(libraryRepository: mockRepository);
        },
        seed: () => LibraryState(
          status: LibraryStatus.success,
          entries: mockEntries,
          userId: 'user-uuid-1',
        ),
        act: (bloc) => bloc.add(
          const LibraryToggleFavoriteRequested(entryId: 'entry-uuid-1'),
        ),
        expect: () => [
          predicate<LibraryState>(
            (state) =>
                state.entries[0].isFavorite ==
                    false && // Optimistically toggled
                state.entries[1].isFavorite == false, // Unchanged
          ),
        ],
        verify: (_) {
          verify(() => mockRepository.toggleFavorite('entry-uuid-1')).called(1);
        },
      );

      blocTest<LibraryBloc, LibraryState>(
        'rolls back favorite toggle on failure',
        build: () {
          when(
            () => mockRepository.toggleFavorite('entry-uuid-1'),
          ).thenThrow(Exception('Network error'));
          return LibraryBloc(libraryRepository: mockRepository);
        },
        seed: () => LibraryState(
          status: LibraryStatus.success,
          entries: mockEntries,
          userId: 'user-uuid-1',
        ),
        act: (bloc) => bloc.add(
          const LibraryToggleFavoriteRequested(entryId: 'entry-uuid-1'),
        ),
        expect: () => [
          predicate<LibraryState>(
            (state) =>
                state.entries[0].isFavorite == false, // Optimistically toggled
          ),
          predicate<LibraryState>(
            (state) =>
                state.entries[0].isFavorite == true && // Rolled back
                state.failure?.action == LibraryAction.toggleFavorite,
          ),
        ],
      );
    });

    group('LibraryDeleteEntryRequested', () {
      blocTest<LibraryBloc, LibraryState>(
        'optimistically removes entry and keeps removed on success',
        build: () {
          when(
            () => mockRepository.deleteLibraryEntry('entry-uuid-1'),
          ).thenAnswer((_) async {});
          return LibraryBloc(libraryRepository: mockRepository);
        },
        seed: () => LibraryState(
          status: LibraryStatus.success,
          entries: mockEntries,
          userId: 'user-uuid-1',
        ),
        act: (bloc) => bloc.add(
          const LibraryDeleteEntryRequested(entryId: 'entry-uuid-1'),
        ),
        expect: () => [
          predicate<LibraryState>(
            (state) =>
                state.entries.length == 1 &&
                state.entries[0].id == 'entry-uuid-2',
          ),
        ],
        verify: (_) {
          verify(
            () => mockRepository.deleteLibraryEntry('entry-uuid-1'),
          ).called(1);
        },
      );

      blocTest<LibraryBloc, LibraryState>(
        'rolls back deletion on failure',
        build: () {
          when(
            () => mockRepository.deleteLibraryEntry('entry-uuid-1'),
          ).thenThrow(Exception('Network error'));
          return LibraryBloc(libraryRepository: mockRepository);
        },
        seed: () => LibraryState(
          status: LibraryStatus.success,
          entries: mockEntries,
          userId: 'user-uuid-1',
        ),
        act: (bloc) => bloc.add(
          const LibraryDeleteEntryRequested(entryId: 'entry-uuid-1'),
        ),
        expect: () => [
          predicate<LibraryState>(
            (state) => state.entries.length == 1, // Optimistically removed
          ),
          predicate<LibraryState>(
            (state) =>
                state.entries.length == 2 && // Rolled back
                state.failure?.action == LibraryAction.delete,
          ),
        ],
      );
    });

    group('LibraryFilterToggled', () {
      blocTest<LibraryBloc, LibraryState>(
        'toggles favorites filter correctly',
        build: () => LibraryBloc(libraryRepository: mockRepository),
        seed: () => LibraryState(
          status: LibraryStatus.success,
          entries: mockEntries,
          userId: 'user-uuid-1',
        ),
        act: (bloc) =>
            bloc.add(const LibraryFilterToggled(showFavoritesOnly: true)),
        expect: () => [
          predicate<LibraryState>((state) => state.showFavoritesOnly == true),
        ],
      );
    });

    group('LibraryStatusFilterChanged', () {
      blocTest<LibraryBloc, LibraryState>(
        'sets status filter correctly',
        build: () => LibraryBloc(libraryRepository: mockRepository),
        seed: () => LibraryState(
          status: LibraryStatus.success,
          entries: mockEntries,
          userId: 'user-uuid-1',
        ),
        act: (bloc) => bloc.add(
          const LibraryStatusFilterChanged(status: GameStatus.playing),
        ),
        expect: () => [
          predicate<LibraryState>(
            (state) => state.statusFilter == GameStatus.playing,
          ),
        ],
      );

      blocTest<LibraryBloc, LibraryState>(
        'clears status filter when null',
        build: () => LibraryBloc(libraryRepository: mockRepository),
        seed: () => LibraryState(
          status: LibraryStatus.success,
          entries: mockEntries,
          userId: 'user-uuid-1',
          statusFilter: GameStatus.playing,
        ),
        act: (bloc) => bloc.add(const LibraryStatusFilterChanged()),
        expect: () => [
          predicate<LibraryState>((state) => state.statusFilter == null),
        ],
      );
    });

    group('LibraryUpdateEntryRequested', () {
      // A real repository over a fake HTTP client, so the test checks the
      // body that reaches PUT /library/{id}.
      late MockHttpClient http;

      setUp(() {
        http = MockHttpClient();
        when(
          () => http.put<Map<String, dynamic>>(any(), data: any(named: 'data')),
        ).thenAnswer(
          (_) async => ApiResponse.success(
            mockEntries[0].copyWith(status: GameStatus.playing).toJson(),
          ),
        );
      });

      blocTest<LibraryBloc, LibraryState>(
        'a status change and its undo keep score, dates, difficulty and notes',
        build: () =>
            LibraryBloc(libraryRepository: LibraryRepository(httpClient: http)),
        seed: () =>
            LibraryState(status: LibraryStatus.success, entries: mockEntries),
        act: (bloc) async {
          // The same events the swipe, the row menu and the undo send.
          bloc.add(
            LibraryUpdateEntryRequested(
              entry: mockEntries[0],
              status: GameStatus.playing,
            ),
          );
          await Future<void>.delayed(Duration.zero);
          bloc.add(
            LibraryUpdateEntryRequested(
              entry: mockEntries[0],
              status: GameStatus.finished,
            ),
          );
        },
        verify: (bloc) {
          final bodies = verify(
            () => http.put<Map<String, dynamic>>(
              '/library/entry-uuid-1',
              data: captureAny(named: 'data'),
            ),
          ).captured;
          const kept = {
            'score': 95,
            'start_date': '2024-01-01',
            'end_date': '2024-02-15',
            'difficulty': 'Normal',
            'notes': 'Amazing game!',
          };
          expect(bodies, [
            {'status': 'playing', ...kept},
            {'status': 'finished', ...kept},
          ]);
          expect(bloc.state.entries.first.score, 95);
        },
      );
    });

    group('LibraryAddGameRequested', () {
      blocTest<LibraryBloc, LibraryState>(
        'adds game to library successfully',
        build: () {
          when(
            () => mockRepository.addToLibrary(
              igdbId: 1942,
              status: GameStatus.planned,
              igdbPlatformId: null,
              score: null,
              playtimeMinutes: null,
              startDate: null,
              endDate: null,
              difficulty: null,
              isFavorite: false,
              notes: null,
            ),
          ).thenAnswer((_) async => mockEntries[0]);
          return LibraryBloc(libraryRepository: mockRepository);
        },
        seed: () => LibraryState(
          status: LibraryStatus.success,
          entries: [mockEntries[1]],
          userId: 'user-uuid-1',
        ),
        act: (bloc) => bloc.add(
          const LibraryAddGameRequested(
            igdbId: 1942,
            status: GameStatus.planned,
          ),
        ),
        expect: () => [
          predicate<LibraryState>((state) => state.isAddingGame == true),
          predicate<LibraryState>(
            (state) =>
                state.isAddingGame == false &&
                state.entries.length == 2 &&
                state.entries[0].game.igdbId == 1942 &&
                state.gameAddedOrUpdated == true,
          ),
          predicate<LibraryState>((state) => state.gameAddedOrUpdated == false),
        ],
      );
    });

    group('filteredEntries', () {
      test('filters by favorites only', () {
        final state = LibraryState(
          status: LibraryStatus.success,
          entries: mockEntries,
          showFavoritesOnly: true,
        );

        expect(state.filteredEntries.length, 1);
        expect(state.filteredEntries[0].isFavorite, true);
      });

      test('filters by status', () {
        final state = LibraryState(
          status: LibraryStatus.success,
          entries: mockEntries,
          statusFilter: GameStatus.playing,
        );

        expect(state.filteredEntries.length, 1);
        expect(state.filteredEntries[0].status, GameStatus.playing);
      });

      test('combines filters correctly', () {
        final state = LibraryState(
          status: LibraryStatus.success,
          entries: mockEntries,
          showFavoritesOnly: true,
          statusFilter: GameStatus.playing,
        );

        // Both filters active: favorites + playing
        // Only first entry is favorite but it's finished, not playing
        expect(state.filteredEntries.length, 0);
      });
    });
  });

  group('collection membership', () {
    LibraryState seeded() => LibraryState(
      status: LibraryStatus.success,
      entries: [
        _overhaulEntry('a', ['c-1', 'c-2']),
        _overhaulEntry('b', ['c-2']),
      ],
    );

    blocTest<LibraryBloc, LibraryState>(
      'LibraryEntryCollectionsChanged patches one entry',
      build: () => LibraryBloc(libraryRepository: _NoopRepository()),
      seed: seeded,
      act: (b) => b.add(
        const LibraryEntryCollectionsChanged(
          entryId: 'b',
          collectionIds: ['c-3'],
        ),
      ),
      verify: (b) {
        expect(b.state.entries[0].collectionIds, ['c-1', 'c-2']);
        expect(b.state.entries[1].collectionIds, ['c-3']);
      },
    );

    blocTest<LibraryBloc, LibraryState>(
      'LibraryCollectionRemoved drops the id everywhere',
      build: () => LibraryBloc(libraryRepository: _NoopRepository()),
      seed: seeded,
      act: (b) => b.add(const LibraryCollectionRemoved(collectionId: 'c-2')),
      verify: (b) {
        expect(b.state.entries[0].collectionIds, ['c-1']);
        expect(b.state.entries[1].collectionIds, isEmpty);
      },
    );
  });
}

class _NoopRepository extends Mock implements LibraryRepository {}

LibraryEntry _overhaulEntry(String id, List<String> collections) {
  final now = DateTime(2026);
  return LibraryEntry(
    id: id,
    userId: 'u',
    game: CachedGame(
      id: 'g$id',
      igdbId: id.hashCode,
      name: id,
      lastSyncedAt: now,
    ),
    status: GameStatus.planned,
    isFavorite: false,
    createdAt: now,
    updatedAt: now,
    collectionIds: collections,
  );
}
