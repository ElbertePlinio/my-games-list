import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/core/domain/models/app_failure.dart';
import 'package:picklog/features/library/browse/library_browse_bloc.dart';
import 'package:picklog/features/library/browse/library_browse_event.dart';
import 'package:picklog/features/library/browse/library_browse_state.dart';
import 'package:picklog/features/library/library_entry_model.dart';
import 'package:picklog/features/library/library_query.dart';
import 'package:picklog/features/library/library_repository.dart';

import '../../../mocks/mock_services.dart';
import '../library_fixtures.dart';

class _MockRepo extends Mock implements LibraryRepository {}

LibraryEntriesResponse _page(List<LibraryEntry> entries, int total) =>
    LibraryEntriesResponse(entries: entries, totalCount: total);

List<LibraryEntry> _entries(int from, int count) => [
  for (var i = from; i < from + count; i++)
    entry(id: 'e$i', igdbId: i, name: 'Game $i'),
];

void main() {
  late _MockRepo repo;
  late MockLocalStorageService storage;

  setUpAll(() => registerFallbackValue(const LibraryFilters()));

  setUp(() {
    repo = _MockRepo();
    storage = MockLocalStorageService();
  });

  LibraryBrowseBloc build() => LibraryBrowseBloc(
    libraryRepository: repo,
    storage: storage,
    queryDebounce: Duration.zero,
  );

  void stubPage(List<LibraryEntry> entries, int total, {int? offset}) {
    when(
      () => repo.queryLibrary(
        any(),
        any(),
        limit: any(named: 'limit'),
        offset: offset == null ? null : any(named: 'offset'),
      ),
    ).thenAnswer((_) async => _page(entries, total));
  }

  group('LibraryBrowseBloc', () {
    blocTest<LibraryBrowseBloc, LibraryBrowseState>(
      'start restores the saved grid mode and loads the first page',
      setUp: () {
        storage.setString(LibraryBrowseBloc.viewModeKey, 'grid');
        stubPage(_entries(0, 2), 2);
      },
      build: build,
      act: (b) => b.add(const LibraryBrowseStarted(userId: 'u1')),
      expect: () => [
        isA<LibraryBrowseState>().having(
          (s) => s.viewMode,
          'viewMode',
          LibraryViewMode.grid,
        ),
        isA<LibraryBrowseState>().having((s) => s.isLoading, 'loading', true),
        isA<LibraryBrowseState>()
            .having((s) => s.entries.length, 'entries', 2)
            .having((s) => s.hasMore, 'hasMore', false),
      ],
      verify: (_) => verify(
        () => repo.queryLibrary(
          'u1',
          const LibraryFilters(),
          limit: LibraryBrowseBloc.pageSize,
        ),
      ).called(1),
    );

    blocTest<LibraryBrowseBloc, LibraryBrowseState>(
      'filter, sort and query changes reload with the new filters',
      setUp: () => stubPage(_entries(0, 1), 1),
      build: build,
      seed: () => const LibraryBrowseState(
        status: LibraryBrowseStatus.success,
        userId: 'u1',
      ),
      act: (b) async {
        b.add(
          const LibraryBrowseFiltersChanged(
            LibraryFilters(statuses: {GameStatus.playing}),
          ),
        );
        await Future<void>.delayed(Duration.zero);
        b.add(const LibraryBrowseSortChanged(LibrarySort.scoreDesc));
        await Future<void>.delayed(Duration.zero);
        b.add(const LibraryBrowseQueryChanged(' zelda '));
        await Future<void>.delayed(const Duration(milliseconds: 10));
      },
      verify: (b) {
        expect(
          b.state.filters,
          const LibraryFilters(
            statuses: {GameStatus.playing},
            sort: LibrarySort.scoreDesc,
            query: 'zelda',
          ),
        );
        verify(
          () => repo.queryLibrary(
            'u1',
            const LibraryFilters(
              statuses: {GameStatus.playing},
              sort: LibrarySort.scoreDesc,
              query: 'zelda',
            ),
            limit: LibraryBrowseBloc.pageSize,
          ),
        ).called(1);
      },
    );

    test(
      'trailing whitespace while a search is pending keeps it running',
      () async {
        final pending = Completer<LibraryEntriesResponse>();
        when(
          () => repo.queryLibrary(any(), any(), limit: any(named: 'limit')),
        ).thenAnswer((_) => pending.future);
        final bloc = build()
          ..emit(
            const LibraryBrowseState(
              status: LibraryBrowseStatus.success,
              userId: 'u1',
            ),
          );
        addTearDown(bloc.close);

        bloc.add(const LibraryBrowseQueryChanged('zelda'));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(bloc.state.isLoading, isTrue);
        bloc.add(const LibraryBrowseQueryChanged('zelda '));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        pending.complete(_page(_entries(0, 1), 1));
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(bloc.state.status, LibraryBrowseStatus.success);
        expect(bloc.state.entries.length, 1);
        verify(
          () => repo.queryLibrary(any(), any(), limit: any(named: 'limit')),
        ).called(1);
      },
    );

    blocTest<LibraryBrowseBloc, LibraryBrowseState>(
      'load more appends the next page with limit and offset',
      setUp: () => when(
        () => repo.queryLibrary(
          any(),
          any(),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => _page(_entries(50, 50), 120)),
      build: build,
      seed: () => LibraryBrowseState(
        status: LibraryBrowseStatus.success,
        userId: 'u1',
        entries: _entries(0, 50),
        totalCount: 120,
        nextOffset: 50,
        hasMore: true,
      ),
      act: (b) => b.add(const LibraryBrowseLoadMore()),
      expect: () => [
        isA<LibraryBrowseState>().having(
          (s) => s.isLoadingMore,
          'loadingMore',
          true,
        ),
        isA<LibraryBrowseState>()
            .having((s) => s.entries.length, 'entries', 100)
            .having((s) => s.nextOffset, 'nextOffset', 100)
            .having((s) => s.hasMore, 'hasMore', true),
      ],
      verify: (_) => verify(
        () => repo.queryLibrary(
          'u1',
          const LibraryFilters(),
          limit: LibraryBrowseBloc.pageSize,
          offset: 50,
        ),
      ).called(1),
    );

    blocTest<LibraryBrowseBloc, LibraryBrowseState>(
      'a failed page keeps the loaded entries and reports the error',
      setUp: () => when(
        () => repo.queryLibrary(
          any(),
          any(),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenThrow(Exception('offline')),
      build: build,
      seed: () => LibraryBrowseState(
        status: LibraryBrowseStatus.success,
        userId: 'u1',
        entries: _entries(0, 50),
        totalCount: 60,
        nextOffset: 50,
        hasMore: true,
      ),
      act: (b) => b.add(const LibraryBrowseLoadMore()),
      skip: 1,
      expect: () => [
        isA<LibraryBrowseState>()
            .having((s) => s.entries.length, 'entries', 50)
            .having((s) => s.loadMoreFailed, 'loadMoreFailed', true)
            .having((s) => s.errorKind, 'kind', AppErrorKind.unknown),
      ],
    );

    blocTest<LibraryBrowseBloc, LibraryBrowseState>(
      'a failed first page with nothing loaded is a failure',
      setUp: () => when(
        () => repo.queryLibrary(any(), any(), limit: any(named: 'limit')),
      ).thenThrow(Exception('boom')),
      build: build,
      act: (b) => b.add(const LibraryBrowseStarted(userId: 'u1')),
      verify: (b) => expect(b.state.status, LibraryBrowseStatus.failure),
    );

    blocTest<LibraryBrowseBloc, LibraryBrowseState>(
      'view mode changes are saved to preferences',
      build: build,
      act: (b) =>
          b.add(const LibraryBrowseViewModeChanged(LibraryViewMode.grid)),
      expect: () => [
        isA<LibraryBrowseState>().having(
          (s) => s.viewMode,
          'mode',
          LibraryViewMode.grid,
        ),
      ],
      verify: (_) async => expect(
        await storage.getString(LibraryBrowseBloc.viewModeKey),
        'grid',
      ),
    );

    blocTest<LibraryBrowseBloc, LibraryBrowseState>(
      'deleted entries drop from the list without a reload',
      build: build,
      seed: () => LibraryBrowseState(
        status: LibraryBrowseStatus.success,
        userId: 'u1',
        entries: _entries(0, 3),
        totalCount: 3,
        nextOffset: 3,
      ),
      act: (b) async {
        b.add(LibraryBrowseSourceChanged(_entries(0, 3)));
        await Future<void>.delayed(Duration.zero);
        b.add(
          LibraryBrowseSourceChanged([
            entry(id: 'e0', igdbId: 0, name: 'Game 0'),
            entry(id: 'e2', igdbId: 2, name: 'Game 2'),
          ]),
        );
      },
      verify: (b) {
        expect(b.state.entries.map((e) => e.id), ['e0', 'e2']);
        expect(b.state.totalCount, 2);
        verifyNever(
          () => repo.queryLibrary(any(), any(), limit: any(named: 'limit')),
        );
      },
    );

    blocTest<LibraryBrowseBloc, LibraryBrowseState>(
      'an edited entry patches its row and reloads the query',
      setUp: () => stubPage(_entries(0, 3), 3),
      build: build,
      seed: () => LibraryBrowseState(
        status: LibraryBrowseStatus.success,
        userId: 'u1',
        entries: _entries(0, 3),
        totalCount: 3,
        nextOffset: 3,
      ),
      act: (b) async {
        b.add(LibraryBrowseSourceChanged(_entries(0, 3)));
        await Future<void>.delayed(Duration.zero);
        b.add(
          LibraryBrowseSourceChanged([
            entry(id: 'e0', igdbId: 0, name: 'Game 0', favorite: true),
            ..._entries(1, 2),
          ]),
        );
      },
      verify: (b) {
        expect(b.state.entries.map((e) => e.id), ['e0', 'e1', 'e2']);
        // The reload answered with the older row; the shared library wins.
        expect(b.state.entries.first.isFavorite, isTrue);
        verify(
          () => repo.queryLibrary(any(), any(), limit: any(named: 'limit')),
        ).called(1);
      },
    );

    final filtered = <String, (LibraryFilters, LibraryEntry, LibraryEntry)>{
      'status': (
        const LibraryFilters(statuses: {GameStatus.planned}),
        entry(id: 'e0', igdbId: 0, name: 'Game 0'),
        entry(id: 'e0', igdbId: 0, name: 'Game 0', status: GameStatus.playing),
      ),
      'favorite': (
        const LibraryFilters(favoritesOnly: true),
        entry(id: 'e0', igdbId: 0, name: 'Game 0', favorite: true),
        entry(id: 'e0', igdbId: 0, name: 'Game 0'),
      ),
      'collection': (
        const LibraryFilters(collectionId: 'c-1'),
        entry(id: 'e0', igdbId: 0, name: 'Game 0', collectionIds: ['c-1']),
        entry(id: 'e0', igdbId: 0, name: 'Game 0'),
      ),
    };
    for (final MapEntry(key: name, value: (filters, before, after))
        in filtered.entries) {
      final other = entry(
        id: 'e1',
        igdbId: 1,
        name: 'Game 1',
        favorite: true,
        collectionIds: ['c-1'],
      );
      blocTest<LibraryBrowseBloc, LibraryBrowseState>(
        'an entry that leaves the $name filter leaves the list and the count',
        // The reload may still see the old row; it must not come back.
        setUp: () => stubPage([before, other], 2),
        build: build,
        seed: () => LibraryBrowseState(
          status: LibraryBrowseStatus.success,
          userId: 'u1',
          filters: filters,
          entries: [before, other],
          totalCount: 2,
          nextOffset: 2,
        ),
        act: (b) async {
          b.add(LibraryBrowseSourceChanged([before, other]));
          await Future<void>.delayed(Duration.zero);
          b.add(LibraryBrowseSourceChanged([after, other]));
        },
        verify: (b) {
          expect(b.state.entries.map((e) => e.id), ['e1']);
          expect(b.state.totalCount, 1);
          verify(
            () => repo.queryLibrary(any(), any(), limit: any(named: 'limit')),
          ).called(1);
        },
      );
    }

    blocTest<LibraryBrowseBloc, LibraryBrowseState>(
      'a newly added library entry reloads the first page',
      setUp: () => stubPage(_entries(0, 4), 4),
      build: build,
      seed: () => LibraryBrowseState(
        status: LibraryBrowseStatus.success,
        userId: 'u1',
        entries: _entries(0, 3),
        totalCount: 3,
      ),
      act: (b) async {
        b.add(LibraryBrowseSourceChanged(_entries(0, 3)));
        await Future<void>.delayed(Duration.zero);
        b.add(LibraryBrowseSourceChanged(_entries(0, 4)));
      },
      verify: (b) => expect(b.state.entries.length, 4),
    );
  });
}
