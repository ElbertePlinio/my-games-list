import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/features/games/bloc/explore_bloc.dart';
import 'package:picklog/features/games/bloc/filter_options_cubit.dart';
import 'package:picklog/features/games/catalog_filters.dart';
import 'package:picklog/features/games/discovery_game_model.dart';
import 'package:picklog/features/games/explore_screen.dart';
import 'package:picklog/features/games/game_detail_model.dart';
import 'package:picklog/features/games/widgets/discovery_game_tile.dart';

import '../../helpers/pump_app.dart';

class _MockExplore extends MockBloc<ExploreEvent, ExploreState>
    implements ExploreBloc {}

class _MockOptions extends MockCubit<FilterOptionsState>
    implements FilterOptionsCubit {}

class _FakeEvent extends Fake implements ExploreEvent {}

const _options = FilterOptionsState(
  status: FilterOptionsStatus.success,
  genres: [
    Genre(id: 12, name: 'RPG'),
    Genre(id: 31, name: 'Adventure'),
  ],
  platforms: [
    PlatformOption(id: 6, name: 'PC (Microsoft Windows)', abbreviation: 'PC'),
    PlatformOption(id: 167, name: 'PlayStation 5', abbreviation: 'PS5'),
  ],
);

void main() {
  setUpAll(() => registerFallbackValue(_FakeEvent()));

  late _MockExplore bloc;
  late _MockOptions options;

  setUp(() {
    bloc = _MockExplore();
    options = _MockOptions();
    when(() => options.state).thenReturn(_options);
    when(() => options.load()).thenAnswer((_) async {});
    when(() => bloc.state).thenReturn(
      ExploreState(
        status: ExploreStatus.success,
        games: [
          for (var i = 0; i < 6; i++) DiscoveryGame(id: i, name: 'Game $i'),
        ],
        hasMore: true,
        nextOffset: 30,
      ),
    );
  });

  Future<void> pump(WidgetTester t, Size size) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await pumpPicklog(
      t,
      MultiBlocProvider(
        providers: [
          BlocProvider<ExploreBloc>.value(value: bloc),
          BlocProvider<FilterOptionsCubit>.value(value: options),
        ],
        child: const ExploreScreen(),
      ),
      reducedMotion: true,
      wrapInScaffold: false,
    );
    await t.pump();
  }

  Future<void> settle(WidgetTester t) async {
    await t.pump();
    await t.pump(const Duration(seconds: 1));
  }

  List<ExploreFiltersChanged> changes() => verify(
    () => bloc.add(captureAny()),
  ).captured.whereType<ExploreFiltersChanged>().toList();

  testWidgets('phone: results grid and a filter sheet that applies a draft', (
    t,
  ) async {
    await pump(t, const Size(390, 844));
    expect(find.byType(DiscoveryGameTile), findsWidgets);
    expect(find.text('Explore'), findsOneWidget);

    await t.tap(find.byKey(const Key('explore_filters_button')));
    await settle(t);
    expect(find.byKey(const Key('explore_sort_control')), findsOneWidget);
    await t.tap(find.text('RPG'));
    await t.ensureVisible(find.text('Newest'));
    await t.pump();
    await t.tap(find.text('Newest'));
    await t.pump();
    // Nothing is sent until Apply.
    verifyNever(() => bloc.add(any()));

    await t.tap(find.byKey(const Key('explore_apply_button')));
    await settle(t);

    final change = changes().single;
    expect(change.filters.catalog.genreIds, {12});
    expect(change.filters.sort, ExploreSort.newest);
  });

  testWidgets('phone: active filters show as removable chips', (t) async {
    when(() => bloc.state).thenReturn(
      const ExploreState(
        status: ExploreStatus.success,
        games: [DiscoveryGame(id: 1, name: 'Game')],
        filters: ExploreFilters(
          catalog: CatalogFilters(platformIds: {167}, minRating: 80),
        ),
      ),
    );
    await pump(t, const Size(390, 844));
    expect(find.text('PS5'), findsOneWidget);
    expect(find.text('Rating 80+'), findsOneWidget);
    await t.tap(find.byTooltip('Remove PS5'));
    expect(changes().single.filters.catalog.platformIds, isEmpty);
  });

  testWidgets('wide: a side panel applies filters live and sort sits above '
      'the grid', (t) async {
    await pump(t, const Size(1280, 800));
    expect(find.byKey(const Key('explore_filters_button')), findsNothing);
    expect(find.byKey(const Key('explore_sort_control')), findsOneWidget);
    await t.tap(find.text('Adventure'));
    expect(changes().single.filters.catalog.genreIds, {31});

    await t.tap(find.text('Top rated'));
    expect(changes().last.filters.sort, ExploreSort.rating);
  });

  testWidgets('scrolling near the end loads more', (t) async {
    when(() => bloc.state).thenReturn(
      ExploreState(
        status: ExploreStatus.success,
        games: [
          for (var i = 0; i < 30; i++) DiscoveryGame(id: i, name: 'Game $i'),
        ],
        hasMore: true,
        nextOffset: 30,
      ),
    );
    await pump(t, const Size(390, 844));
    await t.drag(find.byType(CustomScrollView), const Offset(0, -6000));
    await t.pump();
    verify(() => bloc.add(const ExploreLoadMore())).called(greaterThan(0));
  });

  testWidgets('an empty result offers to clear the filters', (t) async {
    when(() => bloc.state).thenReturn(
      const ExploreState(
        status: ExploreStatus.success,
        filters: ExploreFilters(catalog: CatalogFilters(genreIds: {12})),
      ),
    );
    await pump(t, const Size(390, 844));
    expect(find.text('No games match'), findsOneWidget);
    await t.tap(find.text('Clear filters'));
    expect(changes().single.filters, const ExploreFilters());
  });
}
