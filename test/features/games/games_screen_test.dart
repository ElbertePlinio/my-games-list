import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/core/domain/models/app_failure.dart';
import 'package:picklog/core/theme/app_theme.dart';
import 'package:picklog/core/widgets/game_card.dart';
import 'package:picklog/features/games/bloc/filter_options_cubit.dart';
import 'package:picklog/features/games/games_screen.dart';
import 'package:picklog/features/games/i_games_repository.dart';
import 'package:picklog/features/games/widgets/skeletons/library_entry_skeleton.dart';
import 'package:picklog/features/library/bloc/library_bloc.dart';
import 'package:picklog/features/library/bloc/library_event.dart';
import 'package:picklog/features/library/bloc/library_state.dart';
import 'package:picklog/features/library/browse/library_browse_bloc.dart';
import 'package:picklog/features/library/browse/library_browse_event.dart';
import 'package:picklog/features/library/browse/library_browse_state.dart';
import 'package:picklog/features/library/collections/bloc/user_collections_bloc.dart';
import 'package:picklog/features/library/collections/bloc/user_collections_event.dart';
import 'package:picklog/features/library/collections/bloc/user_collections_state.dart';
import 'package:picklog/features/library/collections/user_collection_model.dart';
import 'package:picklog/features/library/collections/widgets/collections_view.dart';
import 'package:picklog/features/library/library_entry_model.dart';
import 'package:picklog/features/library/library_query.dart';
import 'package:picklog/features/library/stats/library_stats_model.dart';
import 'package:picklog/features/library/stats/stats_cubit.dart';
import 'package:picklog/features/library/widgets/library_entry_views.dart';
import 'package:picklog/features/library/widgets/library_stats_header.dart';
import 'package:picklog/features/library/widgets/library_status_pill.dart';
import 'package:picklog/l10n/app_localizations.dart';

import '../../mocks/mock_blocs.dart';
import '../library/library_fixtures.dart';

class _MockBrowse extends MockBloc<LibraryBrowseEvent, LibraryBrowseState>
    implements LibraryBrowseBloc {}

class _MockCollections
    extends MockBloc<UserCollectionsEvent, UserCollectionsState>
    implements UserCollectionsBloc {}

class _MockStats extends MockCubit<StatsState> implements StatsCubit {}

class _MockGamesRepository extends Mock implements IGamesRepository {}

class _FakeLibraryEvent extends Fake implements LibraryEvent {}

class _FakeBrowseEvent extends Fake implements LibraryBrowseEvent {}

class _FakeCollectionsEvent extends Fake implements UserCollectionsEvent {}

const _stats = UserStats(
  totalGames: 42,
  favorites: 5,
  statusCounts: {
    GameStatus.planned: 10,
    GameStatus.playing: 3,
    GameStatus.finished: 20,
    GameStatus.dropped: 4,
    GameStatus.onHold: 5,
  },
  totalPlaytimeMinutes: 6000,
);

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeLibraryEvent());
    registerFallbackValue(_FakeBrowseEvent());
    registerFallbackValue(_FakeCollectionsEvent());
  });

  late MockLibraryBloc library;
  late _MockBrowse browse;
  late _MockCollections collections;
  late _MockStats stats;

  setUp(() {
    library = MockLibraryBloc();
    browse = _MockBrowse();
    collections = _MockCollections();
    stats = _MockStats();
    when(() => library.state).thenReturn(const LibraryState());
    when(() => browse.state).thenReturn(const LibraryBrowseState());
    when(() => collections.state).thenReturn(const UserCollectionsState());
    when(
      () => stats.state,
    ).thenReturn(const StatsState(status: StatsStatus.success, stats: _stats));
    when(() => stats.load(year: any(named: 'year'))).thenAnswer((_) async {});
  });

  LibraryBrowseState loaded(
    List<LibraryEntry> entries, {
    LibraryFilters filters = const LibraryFilters(),
    LibraryViewMode mode = LibraryViewMode.list,
  }) => LibraryBrowseState(
    status: LibraryBrowseStatus.success,
    userId: 'user-1',
    entries: entries,
    totalCount: entries.length,
    filters: filters,
    viewMode: mode,
  );

  Widget subject() => MaterialApp(
    theme: AppTheme.dark(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: MultiBlocProvider(
      providers: [
        BlocProvider<LibraryBloc>.value(value: library),
        BlocProvider<LibraryBrowseBloc>.value(value: browse),
        BlocProvider<UserCollectionsBloc>.value(value: collections),
        BlocProvider<StatsCubit>.value(value: stats),
        BlocProvider(
          create: (_) =>
              FilterOptionsCubit(gamesRepository: _MockGamesRepository()),
        ),
      ],
      child: const GamesScreen(),
    ),
  );

  List<T> fromBrowse<T>() =>
      verify(() => browse.add(captureAny())).captured.whereType<T>().toList();
  List<T> fromLibrary<T>() =>
      verify(() => library.add(captureAny())).captured.whereType<T>().toList();
  List<T> fromCollections<T>() => verify(
    () => collections.add(captureAny()),
  ).captured.whereType<T>().toList();

  group('GamesScreen', () {
    testWidgets('shows the title, segments and the stats header', (t) async {
      when(() => browse.state).thenReturn(loaded([entry()]));
      await t.pumpWidget(subject());

      expect(find.widgetWithText(AppBar, 'Library'), findsOneWidget);
      expect(find.text('Games'), findsOneWidget);
      expect(find.text('Collections'), findsOneWidget);
      expect(find.byType(LibraryStatsHeader), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
      expect(
        find.bySemanticsLabel('42 games, 3 playing, 20 finished, 100 hours'),
        findsOneWidget,
      );
    });

    testWidgets('the first load renders the list skeleton', (t) async {
      when(() => browse.state).thenReturn(
        const LibraryBrowseState(status: LibraryBrowseStatus.loading),
      );
      await t.pumpWidget(subject());
      expect(find.byType(LibraryListSkeleton), findsOneWidget);
    });

    testWidgets('a failed first page offers a retry', (t) async {
      when(() => browse.state).thenReturn(
        const LibraryBrowseState(
          status: LibraryBrowseStatus.failure,
          errorKind: AppErrorKind.server,
        ),
      );
      await t.pumpWidget(subject());
      expect(find.text('Failed to load library'), findsOneWidget);
      await t.tap(find.text('Try again'));
      expect(fromBrowse<LibraryBrowseRefreshRequested>(), hasLength(1));
    });

    testWidgets('an empty library shows the welcome view without the FAB', (
      t,
    ) async {
      when(() => browse.state).thenReturn(loaded(const []));
      await t.pumpWidget(subject());
      expect(find.text('Your library is empty'), findsOneWidget);
      expect(find.text('Add your first game'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('a filtered empty list offers to clear the filters', (t) async {
      when(() => browse.state).thenReturn(
        loaded(const [], filters: const LibraryFilters(query: 'zzz')),
      );
      await t.pumpWidget(subject());
      expect(find.text('No games match'), findsOneWidget);
      await t.tap(find.text('Clear filters'));
      final event = fromBrowse<LibraryBrowseFiltersChanged>().single;
      expect(event.filters, const LibraryFilters());
    });

    testWidgets('renders a row per entry with status and playtime', (t) async {
      when(() => browse.state).thenReturn(
        loaded([
          entry(id: 'a', name: 'Game A', playtime: 750),
          entry(id: 'b', name: 'Game B', status: GameStatus.playing),
        ]),
      );
      await t.pumpWidget(subject());
      expect(find.text('Game A'), findsOneWidget);
      expect(find.text('Game B'), findsOneWidget);
      expect(find.byType(LibraryEntryRow), findsNWidgets(2));
      expect(find.byType(LibraryStatusPill), findsNWidgets(2));
      expect(find.textContaining('12.5 h'), findsOneWidget);
    });

    testWidgets('quick chips toggle favorites and statuses server-side', (
      t,
    ) async {
      when(() => browse.state).thenReturn(loaded([entry()]));
      await t.pumpWidget(subject());

      expect(find.text('Favorites · 5'), findsOneWidget);
      await t.tap(find.byKey(const Key('library_filter_favorites')));
      await t.tap(find.byKey(const Key('library_filter_planned')));
      final events = fromBrowse<LibraryBrowseFiltersChanged>();
      expect(events.first.filters.favoritesOnly, isTrue);
      expect(events.last.filters.statuses, {GameStatus.planned});
    });

    testWidgets('advanced filters show removable chips and clear all', (
      t,
    ) async {
      when(() => browse.state).thenReturn(
        loaded(
          [entry()],
          filters: const LibraryFilters(
            minScore: 70,
            sort: LibrarySort.nameAsc,
          ),
        ),
      );
      await t.pumpWidget(subject());

      expect(find.text('Score 70+'), findsOneWidget);
      expect(find.text('1 match'), findsOneWidget);
      await t.tap(find.text('Clear all'));
      final event = fromBrowse<LibraryBrowseFiltersChanged>().single;
      expect(event.filters, const LibraryFilters(sort: LibrarySort.nameAsc));
    });

    testWidgets('typing searches and the sort menu changes the sort', (
      t,
    ) async {
      when(() => browse.state).thenReturn(loaded([entry()]));
      await t.pumpWidget(subject());

      await t.enterText(find.byKey(const Key('library_search_field')), 'zel');
      expect(fromBrowse<LibraryBrowseQueryChanged>().single.query, 'zel');

      await t.tap(find.byKey(const Key('library_sort_menu')));
      await t.pumpAndSettle();
      await t.tap(find.text('Your score').last);
      await t.pumpAndSettle();
      expect(
        fromBrowse<LibraryBrowseSortChanged>().single.sort,
        LibrarySort.scoreDesc,
      );
    });

    testWidgets('the view toggle switches to the grid', (t) async {
      when(() => browse.state).thenReturn(loaded([entry()]));
      await t.pumpWidget(subject());
      await t.tap(find.byKey(const Key('library_view_toggle')));
      expect(
        fromBrowse<LibraryBrowseViewModeChanged>().single.mode,
        LibraryViewMode.grid,
      );
    });

    testWidgets('grid mode renders cover cards', (t) async {
      when(
        () => browse.state,
      ).thenReturn(loaded([entry()], mode: LibraryViewMode.grid));
      await t.pumpWidget(subject());
      expect(find.byType(LibraryEntryGridCard), findsOneWidget);
      expect(find.byType(GameCard), findsOneWidget);
    });

    testWidgets('the heart toggles the favorite with an undo', (t) async {
      when(() => browse.state).thenReturn(loaded([entry(id: 'fav')]));
      await t.pumpWidget(subject());

      await t.tap(find.byTooltip('Add to favorites'));
      await t.pump();
      expect(find.text('Hollow Knight added to favorites'), findsOneWidget);
      await t.pumpAndSettle();
      await t.tap(find.text('Undo'));
      final toggles = fromLibrary<LibraryToggleFavoriteRequested>();
      expect(toggles.map((e) => e.entryId), ['fav', 'fav']);
    });

    testWidgets('swiping left changes the status with an undo', (t) async {
      final row = detailedEntry(id: 's1');
      when(() => browse.state).thenReturn(loaded([row]));
      await t.pumpWidget(subject());

      await t.drag(find.byType(LibraryEntryRow), const Offset(-500, 0));
      await t.pumpAndSettle();
      expect(find.text('Change status of Hollow Knight'), findsOneWidget);
      await t.tap(find.text('Playing').last);
      await t.pumpAndSettle();
      expect(find.text('Hollow Knight is now Playing'), findsOneWidget);
      await t.tap(find.text('Undo'));
      await t.pump();

      final updates = fromLibrary<LibraryUpdateEntryRequested>();
      expect(updates.map((e) => e.status), [
        GameStatus.playing,
        GameStatus.planned,
      ]);
      // Both updates carry the full entry and no details, so the repository
      // sends back its score, dates, difficulty and notes.
      for (final update in updates) {
        expect(update.entry, row);
        expect(update.details, isNull);
      }
      // The row stays in place after the swipe.
      expect(find.byType(LibraryEntryRow), findsOneWidget);
    });

    testWidgets('the row menu changes the status and keeps the details', (
      t,
    ) async {
      final row = detailedEntry(id: 'm1');
      when(() => browse.state).thenReturn(loaded([row]));
      await t.pumpWidget(subject());

      await t.tap(find.byTooltip('More actions'));
      await t.pumpAndSettle();
      await t.tap(find.text('Change status'));
      await t.pumpAndSettle();
      await t.tap(find.text('Finished').last);
      await t.pumpAndSettle();

      final update = fromLibrary<LibraryUpdateEntryRequested>().single;
      expect(update.status, GameStatus.finished);
      expect(update.entry, row);
      expect(update.details, isNull);
    });

    testWidgets('swiping right toggles the favorite', (t) async {
      when(() => browse.state).thenReturn(loaded([entry(id: 'r1')]));
      await t.pumpWidget(subject());
      await t.drag(find.byType(LibraryEntryRow), const Offset(500, 0));
      await t.pumpAndSettle();
      expect(
        fromLibrary<LibraryToggleFavoriteRequested>().single.entryId,
        'r1',
      );
    });

    testWidgets('shared library changes are forwarded to the list', (t) async {
      final entries = [entry(id: 'x')];
      whenListen(
        library,
        Stream<LibraryState>.fromIterable([
          LibraryState(status: LibraryStatus.success, entries: entries),
        ]),
        initialState: const LibraryState(),
      );
      when(() => browse.state).thenReturn(loaded(entries));
      await t.pumpWidget(subject());
      await t.pump();
      expect(fromBrowse<LibraryBrowseSourceChanged>().single.entries, entries);
    });

    testWidgets('a failed favorite toggle shows a localized snackbar', (
      t,
    ) async {
      whenListen(
        library,
        Stream<LibraryState>.fromIterable([
          const LibraryState(
            status: LibraryStatus.success,
            failure: LibraryFailure(
              LibraryAction.toggleFavorite,
              AppErrorKind.network,
            ),
          ),
        ]),
        initialState: const LibraryState(status: LibraryStatus.success),
      );
      when(() => browse.state).thenReturn(loaded([entry()]));
      await t.pumpWidget(subject());
      await t.pump();
      expect(
        find.text("Couldn't update the favorite. Try again."),
        findsOneWidget,
      );
    });

    testWidgets('the collections segment shows the mosaic grid', (t) async {
      when(() => browse.state).thenReturn(loaded([entry()]));
      when(() => collections.state).thenReturn(
        UserCollectionsState(
          status: UserCollectionsStatus.success,
          collections: [
            UserCollection.fromJson(collectionJson(count: 3)),
            UserCollection.fromJson(
              collectionJson(id: 'c-2', name: 'Comfort games', count: 0),
            ),
          ],
        ),
      );
      await t.pumpWidget(subject());
      await t.tap(find.text('Collections'));
      await t.pumpAndSettle();

      expect(find.byType(CollectionCard), findsNWidgets(2));
      expect(find.text('Couch co-op'), findsOneWidget);
      expect(find.text('3 games'), findsOneWidget);
      expect(find.text('No games'), findsOneWidget);
      expect(find.text('New collection'), findsOneWidget);
      expect(fromCollections<UserCollectionsLoadRequested>(), hasLength(1));
    });

    testWidgets('an empty collections segment invites creating one', (t) async {
      when(() => browse.state).thenReturn(loaded([entry()]));
      when(() => collections.state).thenReturn(
        const UserCollectionsState(status: UserCollectionsStatus.success),
      );
      await t.pumpWidget(subject());
      await t.tap(find.text('Collections'));
      await t.pumpAndSettle();
      expect(find.text('No collections yet'), findsOneWidget);

      await t.tap(find.byKey(const Key('library_new_collection_fab')));
      await t.pumpAndSettle();
      expect(find.text('Name'), findsOneWidget);
      await t.enterText(
        find.byKey(const Key('collection_name_field')),
        'Couch co-op',
      );
      await t.tap(find.byKey(const Key('collection_save_button')));
      await t.pump();
      final create = fromCollections<UserCollectionCreateRequested>();
      expect(create.single.name, 'Couch co-op');
    });
  });
}
