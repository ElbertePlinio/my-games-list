import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/features/games/game_detail_model.dart';
import 'package:picklog/features/library/bloc/library_bloc.dart';
import 'package:picklog/features/library/bloc/library_event.dart';
import 'package:picklog/features/library/bloc/library_state.dart';
import 'package:picklog/features/library/collections/bloc/collection_detail_cubit.dart';
import 'package:picklog/features/library/collections/bloc/user_collections_bloc.dart';
import 'package:picklog/features/library/collections/bloc/user_collections_event.dart';
import 'package:picklog/features/library/collections/bloc/user_collections_state.dart';
import 'package:picklog/features/library/collections/collection_detail_screen.dart';
import 'package:picklog/features/library/collections/collection_failure.dart';
import 'package:picklog/features/library/collections/user_collection_model.dart';
import 'package:picklog/features/library/collections/widgets/collection_picker_sheet.dart';
import 'package:picklog/features/library/widgets/add_to_library_bottom_sheet.dart';
import 'package:picklog/core/domain/models/app_failure.dart';

import '../../../helpers/pump_app.dart';
import '../../../mocks/mock_blocs.dart';
import '../library_fixtures.dart';

class _MockCollections
    extends MockBloc<UserCollectionsEvent, UserCollectionsState>
    implements UserCollectionsBloc {}

class _MockDetail extends MockCubit<CollectionDetailState>
    implements CollectionDetailCubit {}

class _FakeCollectionsEvent extends Fake implements UserCollectionsEvent {}

class _FakeLibraryEvent extends Fake implements LibraryEvent {}

final _c1 = UserCollection.fromJson(collectionJson());
final _c2 = UserCollection.fromJson(
  collectionJson(id: 'c-2', name: 'Comfort games', count: 0),
);

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeCollectionsEvent());
    registerFallbackValue(_FakeLibraryEvent());
  });

  late _MockCollections collections;
  late MockLibraryBloc library;

  setUp(() {
    collections = _MockCollections();
    library = MockLibraryBloc();
    when(() => library.state).thenReturn(const LibraryState());
  });

  List<T> sent<T>() => verify(
    () => collections.add(captureAny()),
  ).captured.whereType<T>().toList();

  group('CollectionPickerSheet', () {
    testWidgets('toggles membership and updates the shared library', (t) async {
      final states = StreamController<UserCollectionsState>();
      addTearDown(states.close);
      whenListen(
        collections,
        states.stream,
        initialState: UserCollectionsState(
          status: UserCollectionsStatus.success,
          collections: [_c1, _c2],
        ),
      );
      await pumpPicklog(
        t,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => CollectionPickerSheet.show(
              context,
              entry: entry(collectionIds: ['c-1']),
              collectionsBloc: collections,
              libraryBloc: library,
            ),
            child: const Text('open'),
          ),
        ),
        reducedMotion: true,
      );
      await t.tap(find.text('open'));
      await t.pumpAndSettle();

      final c1 = t.widget<CheckboxListTile>(
        find.byKey(const ValueKey('collection_picker_c-1')),
      );
      expect(c1.value, isTrue);

      await t.tap(find.text('Comfort games'));
      await t.pump();
      final toggle = sent<UserCollectionEntryToggled>().single;
      expect(toggle.collectionId, 'c-2');
      expect(toggle.add, isTrue);

      states.add(
        UserCollectionsState(
          status: UserCollectionsStatus.success,
          collections: [_c1, _c2],
          mutation: CollectionMutation(
            requestId: toggle.requestId,
            action: CollectionAction.addEntry,
          ),
        ),
      );
      await t.pump();
      final changed =
          verify(() => library.add(captureAny())).captured.single
              as LibraryEntryCollectionsChanged;
      expect(changed.collectionIds.toSet(), {'c-1', 'c-2'});
    });

    testWidgets('a failed toggle reverts and shows the localized error', (
      t,
    ) async {
      final states = StreamController<UserCollectionsState>();
      addTearDown(states.close);
      whenListen(
        collections,
        states.stream,
        initialState: UserCollectionsState(
          status: UserCollectionsStatus.success,
          collections: [_c1],
        ),
      );
      await pumpPicklog(
        t,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => CollectionPickerSheet.show(
              context,
              entry: entry(),
              collectionsBloc: collections,
              libraryBloc: library,
            ),
            child: const Text('open'),
          ),
        ),
        reducedMotion: true,
      );
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      await t.tap(find.text('Couch co-op'));
      await t.pump();
      final toggle = sent<UserCollectionEntryToggled>().single;
      states.add(
        UserCollectionsState(
          status: UserCollectionsStatus.success,
          collections: [_c1],
          mutation: CollectionMutation(
            requestId: toggle.requestId,
            action: CollectionAction.addEntry,
            failure: const CollectionFailure.of(
              CollectionAction.addEntry,
              CollectionErrorKind.entriesLimitReached,
              AppErrorKind.unknown,
            ),
          ),
        ),
      );
      await t.pump();
      expect(find.text('This collection is full (500 games).'), findsOneWidget);
      final tile = t.widget<CheckboxListTile>(
        find.byKey(const ValueKey('collection_picker_c-1')),
      );
      expect(tile.value, isFalse);
      verifyNever(() => library.add(any()));
    });
  });

  group('Collection form', () {
    testWidgets('a duplicate name keeps the dialog open with the message', (
      t,
    ) async {
      final states = StreamController<UserCollectionsState>();
      addTearDown(states.close);
      whenListen(
        collections,
        states.stream,
        initialState: const UserCollectionsState(
          status: UserCollectionsStatus.success,
        ),
      );
      await pumpPicklog(
        t,
        BlocProvider<LibraryBloc>.value(
          value: library,
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () => CollectionPickerSheet.show(
                context,
                entry: entry(),
                collectionsBloc: collections,
                libraryBloc: library,
              ),
              child: const Text('open'),
            ),
          ),
        ),
        reducedMotion: true,
      );
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      expect(
        find.text('No collections yet. Create one to group games your way.'),
        findsOneWidget,
      );
      await t.tap(find.byKey(const Key('collection_picker_new')));
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const Key('collection_name_field')), 'Dup');
      await t.tap(find.byKey(const Key('collection_save_button')));
      await t.pump();
      final create = sent<UserCollectionCreateRequested>().single;
      expect(create.addEntryId, 'entry-1');

      states.add(
        UserCollectionsState(
          status: UserCollectionsStatus.success,
          mutation: CollectionMutation(
            requestId: create.requestId,
            action: CollectionAction.create,
            failure: const CollectionFailure.of(
              CollectionAction.create,
              CollectionErrorKind.duplicateName,
              AppErrorKind.unknown,
            ),
          ),
        ),
      );
      await t.pump();
      expect(
        find.text('You already have a collection with this name.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('collection_name_field')), findsOneWidget);
    });

    testWidgets('an empty name is rejected locally', (t) async {
      when(() => collections.state).thenReturn(
        const UserCollectionsState(status: UserCollectionsStatus.success),
      );
      await pumpPicklog(
        t,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => CollectionPickerSheet.show(
              context,
              entry: entry(),
              collectionsBloc: collections,
              libraryBloc: library,
            ),
            child: const Text('open'),
          ),
        ),
        reducedMotion: true,
      );
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('collection_picker_new')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('collection_save_button')));
      await t.pump();
      expect(find.text('Use 1 to 60 characters for the name.'), findsOneWidget);
      verifyNever(() => collections.add(any()));
    });
  });

  group('CollectionDetailScreen', () {
    late _MockDetail detail;
    setUp(() => detail = _MockDetail());

    Future<void> pumpDetail(WidgetTester t) => pumpPicklog(
      t,
      MultiBlocProvider(
        providers: [
          BlocProvider<UserCollectionsBloc>.value(value: collections),
          BlocProvider<LibraryBloc>.value(value: library),
          BlocProvider<CollectionDetailCubit>.value(value: detail),
        ],
        child: const CollectionDetailScreen(collectionId: 'c-1'),
      ),
      reducedMotion: true,
      wrapInScaffold: false,
    );

    testWidgets('shows the header, description and games', (t) async {
      when(() => collections.state).thenReturn(
        UserCollectionsState(
          status: UserCollectionsStatus.success,
          collections: [
            UserCollection.fromJson(collectionJson(description: 'Sofa games')),
          ],
        ),
      );
      when(() => detail.state).thenReturn(
        CollectionDetailState(
          status: CollectionDetailStatus.success,
          detail: UserCollectionDetail(
            collection: _c1,
            entries: [
              entry(id: 'a', name: 'Alpha'),
              entry(id: 'b', name: 'Beta'),
            ],
          ),
        ),
      );
      await pumpDetail(t);
      await t.pump();
      expect(find.text('Couch co-op'), findsWidgets);
      expect(find.text('Sofa games'), findsOneWidget);
      expect(find.text('2 games'), findsOneWidget);
      expect(find.text('Alpha'), findsOneWidget);

      await t.tap(find.byKey(const ValueKey('collection_remove_a')));
      final toggle = sent<UserCollectionEntryToggled>().single;
      expect(toggle.add, isFalse);
      expect(toggle.libraryEntryId, 'a');
    });

    testWidgets('a missing collection shows the not found state', (t) async {
      when(() => collections.state).thenReturn(const UserCollectionsState());
      when(() => detail.state).thenReturn(
        const CollectionDetailState(
          status: CollectionDetailStatus.failure,
          notFound: true,
          errorKind: AppErrorKind.notFound,
        ),
      );
      await pumpDetail(t);
      await t.pump();
      expect(find.text('This collection no longer exists.'), findsOneWidget);
    });
  });

  group('AddToLibraryBottomSheet collections', () {
    testWidgets('chosen collections are saved with the entry', (t) async {
      when(() => collections.state).thenReturn(
        UserCollectionsState(
          status: UserCollectionsStatus.success,
          collections: [_c1, _c2],
        ),
      );
      final existing = entry(collectionIds: ['c-1']);
      final states = StreamController<LibraryState>();
      addTearDown(states.close);
      whenListen(
        library,
        states.stream,
        initialState: LibraryState(
          status: LibraryStatus.success,
          entries: [existing],
        ),
      );
      t.view.physicalSize = const Size(390, 1400);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await pumpPicklog(
        t,
        BlocProvider<LibraryBloc>.value(
          value: library,
          child: AddToLibraryBottomSheet(
            gameId: 42,
            gameName: 'Hollow Knight',
            platforms: const [Platform(id: 6, name: 'PC')],
            existingEntry: existing,
            collectionsBloc: collections,
          ),
        ),
        reducedMotion: true,
      );
      expect(find.text('COLLECTIONS'), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('sheet_collection_c-1')));
      await t.pump();
      await t.tap(find.byKey(const ValueKey('sheet_collection_c-2')));
      await t.pump();
      verifyNever(() => collections.add(any()));

      await t.tap(find.text('Save'));
      states.add(
        LibraryState(
          status: LibraryStatus.success,
          entries: [existing],
          gameAddedOrUpdated: true,
        ),
      );
      await t.pump();
      final toggles = sent<UserCollectionEntryToggled>();
      expect(
        {for (final e in toggles) e.collectionId: e.add},
        {'c-2': true, 'c-1': false},
      );
    });

    testWidgets('only confirmed memberships reach the shared library', (
      t,
    ) async {
      final collectionStates = StreamController<UserCollectionsState>();
      addTearDown(collectionStates.close);
      final ready = UserCollectionsState(
        status: UserCollectionsStatus.success,
        collections: [_c1, _c2],
      );
      whenListen(collections, collectionStates.stream, initialState: ready);
      final existing = entry(collectionIds: ['c-1']);
      final states = StreamController<LibraryState>();
      addTearDown(states.close);
      whenListen(
        library,
        states.stream,
        initialState: LibraryState(
          status: LibraryStatus.success,
          entries: [existing],
        ),
      );
      t.view.physicalSize = const Size(390, 1400);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await pumpPicklog(
        t,
        BlocProvider<LibraryBloc>.value(
          value: library,
          child: AddToLibraryBottomSheet(
            gameId: 42,
            gameName: 'Hollow Knight',
            platforms: const [Platform(id: 6, name: 'PC')],
            existingEntry: existing,
            collectionsBloc: collections,
          ),
        ),
        reducedMotion: true,
      );
      await t.tap(find.byKey(const ValueKey('sheet_collection_c-1')));
      await t.pump();
      await t.tap(find.byKey(const ValueKey('sheet_collection_c-2')));
      await t.pump();

      await t.tap(find.text('Save'));
      states.add(
        LibraryState(
          status: LibraryStatus.success,
          entries: [existing],
          gameAddedOrUpdated: true,
        ),
      );
      await t.pump();
      final toggles = {
        for (final e in sent<UserCollectionEntryToggled>()) e.collectionId: e,
      };
      // Nothing is published before the collections API answers.
      verifyNever(
        () => library.add(any(that: isA<LibraryEntryCollectionsChanged>())),
      );

      collectionStates.add(
        ready.copyWith(
          mutation: CollectionMutation(
            requestId: toggles['c-1']!.requestId,
            action: CollectionAction.removeEntry,
          ),
        ),
      );
      await t.pump();
      collectionStates.add(
        ready.copyWith(
          mutation: CollectionMutation(
            requestId: toggles['c-2']!.requestId,
            action: CollectionAction.addEntry,
            failure: const CollectionFailure.of(
              CollectionAction.addEntry,
              CollectionErrorKind.entriesLimitReached,
              AppErrorKind.unknown,
            ),
          ),
        ),
      );
      await t.pump();
      await t.pump();

      final published = verify(
        () => library.add(captureAny()),
      ).captured.whereType<LibraryEntryCollectionsChanged>().single;
      // c-1 was removed; the full c-2 rejected the entry.
      expect(published.collectionIds, isEmpty);
      expect(find.text('This collection is full (500 games).'), findsOneWidget);
    });
  });
}
