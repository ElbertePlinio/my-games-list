import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/core/data/services/http/i_http_client.dart';
import 'package:picklog/core/domain/models/api_error.dart';
import 'package:picklog/core/domain/models/api_response.dart';
import 'package:picklog/core/domain/models/app_failure.dart';
import 'package:picklog/features/library/collections/bloc/collection_detail_cubit.dart';
import 'package:picklog/features/library/collections/bloc/user_collections_bloc.dart';
import 'package:picklog/features/library/collections/bloc/user_collections_event.dart';
import 'package:picklog/features/library/collections/bloc/user_collections_state.dart';
import 'package:picklog/features/library/collections/collection_failure.dart';
import 'package:picklog/features/library/collections/user_collection_model.dart';
import 'package:picklog/features/library/collections/user_collections_repository.dart';

import '../library_fixtures.dart';

class _MockHttp extends Mock implements IHttpClient {}

class _MockRepo extends Mock implements UserCollectionsRepository {}

ApiException _apiError(int status, String code) => ApiException(
  ApiError(
    name: 'n',
    message: 'm',
    action: 'a',
    statusCode: status,
    errorCode: code,
  ),
);

UserCollection _collection([String id = 'c-1', String name = 'Couch co-op']) =>
    UserCollection.fromJson(collectionJson(id: id, name: name));

void main() {
  group('UserCollectionsRepository', () {
    late _MockHttp http;
    late UserCollectionsRepository repo;

    setUp(() {
      http = _MockHttp();
      repo = UserCollectionsRepository(httpClient: http);
    });

    test('lists collections', () async {
      when(() => http.get<Map<String, dynamic>>(any())).thenAnswer(
        (_) async => ApiResponse.success({
          'collections': [collectionJson()],
        }),
      );
      final list = await repo.getCollections();
      expect(list.single.name, 'Couch co-op');
      expect(list.single.coverUrls, ['a', 'b']);
      verify(() => http.get<Map<String, dynamic>>('/users/me/collections'));
    });

    test('creates with name and optional description', () async {
      when(
        () => http.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer((_) async => ApiResponse.success(collectionJson()));
      await repo.createCollection(name: 'Couch co-op');
      verify(
        () => http.post<Map<String, dynamic>>(
          '/users/me/collections',
          data: {'name': 'Couch co-op'},
        ),
      );
    });

    test('a duplicate name maps to duplicateName', () async {
      when(
        () => http.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => ApiResponse.failure(
          const ApiError(
            name: 'n',
            message: 'm',
            action: 'a',
            statusCode: 409,
            errorCode: 'error.collection.duplicate_name',
          ),
        ),
      );
      await expectLater(
        repo.createCollection(name: 'x'),
        throwsA(
          predicate(
            (e) =>
                CollectionErrorKind.fromError(e!) ==
                CollectionErrorKind.duplicateName,
          ),
        ),
      );
    });

    test('gets the detail with entries in order', () async {
      when(() => http.get<Map<String, dynamic>>(any())).thenAnswer(
        (_) async => ApiResponse.success({
          ...collectionJson(),
          'entries': [entryJson(id: 'a'), entryJson(id: 'b')],
        }),
      );
      final detail = await repo.getCollection('c-1');
      expect(detail.entries.map((e) => e.id), ['a', 'b']);
      verify(() => http.get<Map<String, dynamic>>('/users/me/collections/c-1'));
    });

    test('patch, delete and membership use the contract paths', () async {
      when(
        () => http.patch<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer((_) async => ApiResponse.success(collectionJson()));
      when(
        () => http.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer((_) async => ApiResponse.success(collectionJson()));
      when(
        () => http.delete<dynamic>(any()),
      ).thenAnswer((_) async => ApiResponse<dynamic>.success(null));

      await repo.updateCollection('c-1', description: '');
      await repo.addEntry('c-1', 'e-1');
      await repo.removeEntry('c-1', 'e-1');
      await repo.deleteCollection('c-1');

      verify(
        () => http.patch<Map<String, dynamic>>(
          '/users/me/collections/c-1',
          data: {'description': ''},
        ),
      );
      verify(
        () => http.post<Map<String, dynamic>>(
          '/users/me/collections/c-1/entries',
          data: {'library_entry_id': 'e-1'},
        ),
      );
      verify(
        () => http.delete<dynamic>('/users/me/collections/c-1/entries/e-1'),
      );
      verify(() => http.delete<dynamic>('/users/me/collections/c-1'));
    });
  });

  group('CollectionErrorKind', () {
    test('maps the collection error codes', () {
      expect(
        CollectionErrorKind.fromError(
          _apiError(409, 'error.collection.limit_reached'),
        ),
        CollectionErrorKind.limitReached,
      );
      expect(
        CollectionErrorKind.fromError(
          _apiError(409, 'error.collection.entries_limit_reached'),
        ),
        CollectionErrorKind.entriesLimitReached,
      );
      expect(
        CollectionErrorKind.fromError(Exception('x')),
        CollectionErrorKind.other,
      );
    });
  });

  group('UserCollectionsBloc', () {
    late _MockRepo repo;
    setUp(() => repo = _MockRepo());

    blocTest<UserCollectionsBloc, UserCollectionsState>(
      'loads the collections',
      setUp: () => when(
        () => repo.getCollections(),
      ).thenAnswer((_) async => [_collection()]),
      build: () => UserCollectionsBloc(repository: repo),
      act: (b) => b.add(const UserCollectionsLoadRequested()),
      expect: () => [
        isA<UserCollectionsState>().having((s) => s.isLoading, 'loading', true),
        isA<UserCollectionsState>().having(
          (s) => s.collections.length,
          'count',
          1,
        ),
      ],
    );

    blocTest<UserCollectionsBloc, UserCollectionsState>(
      'create puts the new collection first and adds the entry',
      setUp: () {
        when(
          () => repo.createCollection(
            name: any(named: 'name'),
            description: any(named: 'description'),
          ),
        ).thenAnswer((_) async => _collection('c-2', 'New'));
        when(
          () => repo.addEntry('c-2', 'e-1'),
        ).thenAnswer((_) async => _collection('c-2', 'New'));
      },
      build: () => UserCollectionsBloc(repository: repo),
      seed: () => UserCollectionsState(
        status: UserCollectionsStatus.success,
        collections: [_collection()],
      ),
      act: (b) => b.add(
        const UserCollectionCreateRequested(
          requestId: 7,
          name: '  New ',
          addEntryId: 'e-1',
        ),
      ),
      verify: (b) {
        expect(b.state.collections.map((c) => c.id), ['c-2', 'c-1']);
        expect(b.state.mutation?.requestId, 7);
        expect(b.state.mutation?.succeeded, isTrue);
        expect(b.state.pendingRequests, isEmpty);
        verify(() => repo.createCollection(name: 'New', description: null));
        verify(() => repo.addEntry('c-2', 'e-1'));
      },
    );

    blocTest<UserCollectionsBloc, UserCollectionsState>(
      'a duplicate name is reported on the mutation',
      setUp: () => when(
        () => repo.createCollection(
          name: any(named: 'name'),
          description: any(named: 'description'),
        ),
      ).thenThrow(_apiError(409, 'error.collection.duplicate_name')),
      build: () => UserCollectionsBloc(repository: repo),
      act: (b) =>
          b.add(const UserCollectionCreateRequested(requestId: 1, name: 'Dup')),
      verify: (b) {
        expect(
          b.state.mutation?.failure?.kind,
          CollectionErrorKind.duplicateName,
        );
        expect(b.state.collections, isEmpty);
      },
    );

    blocTest<UserCollectionsBloc, UserCollectionsState>(
      'the collection limit is reported on the mutation',
      setUp: () => when(
        () => repo.createCollection(
          name: any(named: 'name'),
          description: any(named: 'description'),
        ),
      ).thenThrow(_apiError(409, 'error.collection.limit_reached')),
      build: () => UserCollectionsBloc(repository: repo),
      act: (b) => b.add(
        const UserCollectionCreateRequested(requestId: 2, name: 'One more'),
      ),
      verify: (b) => expect(
        b.state.mutation?.failure?.kind,
        CollectionErrorKind.limitReached,
      ),
    );

    blocTest<UserCollectionsBloc, UserCollectionsState>(
      'update replaces the collection and delete removes it',
      setUp: () {
        when(
          () => repo.updateCollection(
            'c-1',
            name: any(named: 'name'),
            description: any(named: 'description'),
          ),
        ).thenAnswer((_) async => _collection('c-1', 'Renamed'));
        when(() => repo.deleteCollection('c-1')).thenAnswer((_) async {});
      },
      build: () => UserCollectionsBloc(repository: repo),
      seed: () => UserCollectionsState(
        status: UserCollectionsStatus.success,
        collections: [_collection(), _collection('c-9', 'Other')],
      ),
      act: (b) async {
        b.add(
          const UserCollectionUpdateRequested(
            requestId: 3,
            collectionId: 'c-1',
            name: 'Renamed',
          ),
        );
        await Future<void>.delayed(Duration.zero);
        expect(b.state.byId('c-1')?.name, 'Renamed');
        b.add(
          const UserCollectionDeleteRequested(
            requestId: 4,
            collectionId: 'c-1',
          ),
        );
      },
      verify: (b) {
        expect(b.state.collections.map((c) => c.id), ['c-9']);
        expect(b.state.mutation?.requestId, 4);
      },
    );

    blocTest<UserCollectionsBloc, UserCollectionsState>(
      'removing an entry refreshes the list',
      setUp: () {
        when(() => repo.removeEntry('c-1', 'e-1')).thenAnswer((_) async {});
        when(() => repo.getCollections()).thenAnswer(
          (_) async => [UserCollection.fromJson(collectionJson(count: 1))],
        );
      },
      build: () => UserCollectionsBloc(repository: repo),
      seed: () => UserCollectionsState(
        status: UserCollectionsStatus.success,
        collections: [_collection()],
      ),
      act: (b) => b.add(
        const UserCollectionEntryToggled(
          requestId: 5,
          collectionId: 'c-1',
          libraryEntryId: 'e-1',
          add: false,
        ),
      ),
      verify: (b) {
        expect(b.state.byId('c-1')?.gameCount, 1);
        expect(b.state.mutation?.succeeded, isTrue);
      },
    );

    blocTest<UserCollectionsBloc, UserCollectionsState>(
      'a full collection reports entriesLimitReached',
      setUp: () => when(
        () => repo.addEntry('c-1', 'e-1'),
      ).thenThrow(_apiError(409, 'error.collection.entries_limit_reached')),
      build: () => UserCollectionsBloc(repository: repo),
      act: (b) => b.add(
        const UserCollectionEntryToggled(
          requestId: 6,
          collectionId: 'c-1',
          libraryEntryId: 'e-1',
          add: true,
        ),
      ),
      verify: (b) => expect(
        b.state.mutation?.failure?.kind,
        CollectionErrorKind.entriesLimitReached,
      ),
    );
  });

  group('CollectionDetailCubit', () {
    late _MockRepo repo;
    setUp(() => repo = _MockRepo());

    blocTest<CollectionDetailCubit, CollectionDetailState>(
      'loads and removes entries locally',
      setUp: () => when(() => repo.getCollection('c-1')).thenAnswer(
        (_) async => UserCollectionDetail(
          collection: _collection(),
          entries: [
            entry(id: 'a'),
            entry(id: 'b'),
          ],
        ),
      ),
      build: () => CollectionDetailCubit(repository: repo, collectionId: 'c-1'),
      act: (c) async {
        await c.load();
        c.removeLocal('a');
      },
      verify: (c) {
        expect(c.state.entries.map((e) => e.id), ['b']);
        expect(c.state.detail?.collection.gameCount, 1);
      },
    );

    blocTest<CollectionDetailCubit, CollectionDetailState>(
      'a missing collection is notFound',
      setUp: () => when(
        () => repo.getCollection('c-1'),
      ).thenThrow(_apiError(404, 'error.collection.not_found')),
      build: () => CollectionDetailCubit(repository: repo, collectionId: 'c-1'),
      act: (c) => c.load(),
      verify: (c) {
        expect(c.state.status, CollectionDetailStatus.failure);
        expect(c.state.notFound, isTrue);
        expect(c.state.errorKind, AppErrorKind.notFound);
      },
    );
  });
}
