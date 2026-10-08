import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:picklog/core/domain/models/app_failure.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/pf_typography.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/utils/app_router.dart';
import 'package:picklog/core/utils/error_l10n.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/widgets/animated_state_switcher.dart';
import 'package:picklog/core/widgets/app_scaffold.dart';
import 'package:picklog/core/widgets/game_card.dart';
import 'package:picklog/core/widgets/responsive_grid.dart';
import 'package:picklog/core/widgets/staggered_reveal.dart';
import 'package:picklog/core/widgets/state_views.dart';
import 'package:picklog/features/games/bloc/filter_options_cubit.dart';
import 'package:picklog/features/games/widgets/catalog_filter_fields.dart';
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
import 'package:picklog/features/library/collections/widgets/collection_form_dialog.dart';
import 'package:picklog/features/library/collections/widgets/collections_view.dart';
import 'package:picklog/features/library/library_entry_model.dart';
import 'package:picklog/features/library/library_query.dart';
import 'package:picklog/features/library/roulette/backlog_roulette_sheet.dart';
import 'package:picklog/features/library/stats/stats_cubit.dart';
import 'package:picklog/features/library/widgets/library_entry_views.dart';
import 'package:picklog/features/library/widgets/library_failure_listener.dart';
import 'package:picklog/features/library/widgets/library_filters_sheet.dart';
import 'package:picklog/features/library/widgets/library_stats_header.dart';
import 'package:picklog/features/library/widgets/library_status_pill.dart';

/// Hero prefix for library covers (unique against the other shell tabs).
const String kLibraryHeroPrefix = 'library-';

/// The two parts of the Library tab.
enum LibrarySegment { games, collections }

/// Library tab: the user's games with server-side search, filters, sort and
/// paging, plus their collections.
///
/// The list comes from [LibraryBrowseBloc]. The shared [LibraryBloc] keeps
/// the whole library for other screens; its changes are forwarded here so
/// swipes, favorites and edits show at once.
class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  LibrarySegment _segment = LibrarySegment.games;
  Timer? _statsDebounce;
  bool _librarySeen = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    final library = context.read<LibraryBloc>().state;
    if (library.status == LibraryStatus.success) {
      _librarySeen = true;
      context.read<LibraryBrowseBloc>().add(
        LibraryBrowseSourceChanged(library.entries),
      );
    }
    _searchController.text = context
        .read<LibraryBrowseBloc>()
        .state
        .filters
        .query;
  }

  @override
  void dispose() {
    _statsDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent * 0.85) {
      context.read<LibraryBrowseBloc>().add(const LibraryBrowseLoadMore());
    }
  }

  void _onLibraryChanged(BuildContext context, LibraryState state) {
    context.read<LibraryBrowseBloc>().add(
      LibraryBrowseSourceChanged(state.entries),
    );
    // The first load only seeds the list; the stats were loaded with the
    // route. Later changes (favorites, status, adds) refresh them.
    if (!_librarySeen) {
      _librarySeen = true;
      return;
    }
    _statsDebounce?.cancel();
    _statsDebounce = Timer(const Duration(milliseconds: 600), () {
      if (mounted) context.read<StatsCubit>().load();
    });
  }

  Future<void> _createCollection() async {
    final created = await showCollectionFormDialog(
      context,
      bloc: context.read<UserCollectionsBloc>(),
    );
    if (created != null && mounted) openCollection(context, created);
  }

  static bool _isFirstRun(LibraryBrowseState state) =>
      state.status == LibraryBrowseStatus.success &&
      !state.hasEntries &&
      !state.filters.hasActiveFilters;

  void _setSegment(LibrarySegment segment) {
    if (segment == _segment) return;
    setState(() => _segment = segment);
    if (segment == LibrarySegment.collections) {
      final bloc = context.read<UserCollectionsBloc>();
      if (bloc.state.status != UserCollectionsStatus.loading) {
        bloc.add(const UserCollectionsLoadRequested());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final collections = _segment == LibrarySegment.collections;

    return LibraryFailureListener(
      child: MultiBlocListener(
        listeners: [
          BlocListener<LibraryBloc, LibraryState>(
            listenWhen: (p, c) =>
                c.status == LibraryStatus.success && p.entries != c.entries,
            listener: _onLibraryChanged,
          ),
          // Clearing every filter also clears the search text.
          BlocListener<LibraryBrowseBloc, LibraryBrowseState>(
            listenWhen: (p, c) =>
                p.filters.query != c.filters.query && c.filters.query.isEmpty,
            listener: (context, state) {
              if (_searchController.text.isNotEmpty) _searchController.clear();
            },
          ),
        ],
        child: Scaffold(
          appBar: AppBar(
            title: Text(l10n.libraryTitle),
            actions: [
              IconButton(
                key: const Key('library_roulette_button'),
                icon: const Icon(Icons.casino_outlined),
                tooltip: l10n.rouletteTitle,
                onPressed: () => BacklogRouletteSheet.show(context),
              ),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => context.pushNamed(AppRouter.searchName),
                tooltip: l10n.addGame,
              ),
              const SizedBox(width: PfSpace.xs),
            ],
          ),
          body: MaxWidthBox(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    PfSpace.lg,
                    PfSpace.xs,
                    PfSpace.lg,
                    PfSpace.sm,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<LibrarySegment>(
                      key: const Key('library_segment'),
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                          value: LibrarySegment.games,
                          icon: const Icon(Icons.sports_esports_outlined),
                          label: Text(l10n.librarySegmentGames),
                        ),
                        ButtonSegment(
                          value: LibrarySegment.collections,
                          icon: const Icon(Icons.collections_bookmark_outlined),
                          label: Text(l10n.librarySegmentCollections),
                        ),
                      ],
                      selected: {_segment},
                      onSelectionChanged: (s) => _setSegment(s.first),
                    ),
                  ),
                ),
                Expanded(
                  child: AnimatedStateSwitcher(
                    stateKey: _segment,
                    child: collections
                        ? CollectionsView(onCreate: _createCollection)
                        : _LibraryGamesView(
                            scrollController: _scrollController,
                            searchController: _searchController,
                          ),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: collections
              ? FloatingActionButton.extended(
                  key: const Key('library_new_collection_fab'),
                  onPressed: _createCollection,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.collectionNewTitle),
                )
              : BlocBuilder<LibraryBrowseBloc, LibraryBrowseState>(
                  buildWhen: (p, c) => _isFirstRun(p) != _isFirstRun(c),
                  // The empty library has its own call to action.
                  builder: (context, state) => _isFirstRun(state)
                      ? const SizedBox.shrink()
                      : FloatingActionButton.extended(
                          onPressed: () =>
                              context.pushNamed(AppRouter.searchName),
                          icon: const Icon(Icons.add),
                          label: Text(l10n.addGame),
                        ),
                ),
        ),
      ),
    );
  }
}

class _LibraryGamesView extends StatelessWidget {
  const _LibraryGamesView({
    required this.scrollController,
    required this.searchController,
  });

  final ScrollController scrollController;
  final TextEditingController searchController;

  Future<void> _refresh(BuildContext context) async {
    final browse = context.read<LibraryBrowseBloc>()
      ..add(const LibraryBrowseRefreshRequested());
    final library = context.read<LibraryBloc>();
    final userId = library.state.userId ?? browse.state.userId;
    if (userId != null) library.add(LibraryRefreshRequested(userId: userId));
    unawaited(context.read<StatsCubit>().load());
    await browse.stream
        .firstWhere((s) => !s.isLoading)
        .timeout(const Duration(seconds: 12), onTimeout: () => browse.state);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryBrowseBloc, LibraryBrowseState>(
      builder: (context, state) {
        final slivers = <Widget>[
          SliverToBoxAdapter(
            child: BlocBuilder<StatsCubit, StatsState>(
              builder: (context, stats) => LibraryStatsHeader(
                stats: stats.stats,
                loading: stats.isLoading || stats.status == StatsStatus.initial,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _LibraryToolbar(state: state, controller: searchController),
          ),
          SliverToBoxAdapter(child: _QuickFilters(state: state)),
          SliverToBoxAdapter(child: _AdvancedChips(state: state)),
          ..._content(context, state),
        ];

        return RefreshIndicator(
          onRefresh: () => _refresh(context),
          child: CustomScrollView(
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: slivers,
          ),
        );
      },
    );
  }

  List<Widget> _content(BuildContext context, LibraryBrowseState state) {
    final l10n = context.l10n;
    final firstLoad =
        (state.isLoading || state.status == LibraryBrowseStatus.initial) &&
        !state.hasEntries;
    if (firstLoad) {
      return const [
        SliverFillRemaining(hasScrollBody: true, child: LibraryListSkeleton()),
      ];
    }
    if (state.status == LibraryBrowseStatus.failure) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: ErrorState(
            message: l10n.failedToLoadLibrary,
            onRetry: () => context.read<LibraryBrowseBloc>().add(
              const LibraryBrowseRefreshRequested(),
            ),
          ),
        ),
      ];
    }
    if (!state.hasEntries) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyLibraryView(filters: state.filters),
        ),
      ];
    }

    final entries = state.entries;
    final grid = state.viewMode == LibraryViewMode.grid;
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          PfSpace.lg,
          PfSpace.sm,
          PfSpace.lg,
          PfSpace.md,
        ),
        sliver: grid
            ? SliverResponsiveGrid(
                itemCount: entries.length,
                childAspectRatio: kGameCardGridAspectRatio,
                itemBuilder: (context, index) => StaggeredReveal(
                  index: index % LibraryBrowseBloc.pageSize,
                  child: LibraryEntryGridCard(
                    key: ValueKey('grid-${entries[index].id}'),
                    entry: entries[index],
                    heroPrefix: kLibraryHeroPrefix,
                  ),
                ),
              )
            : SliverLayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.crossAxisExtent >= PfBreakpoints.twoPane) {
                    return SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 560,
                            mainAxisExtent: 100,
                            crossAxisSpacing: PfSpace.md,
                            mainAxisSpacing: PfSpace.sm,
                          ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => StaggeredReveal(
                          index: index % LibraryBrowseBloc.pageSize,
                          child: LibraryEntryRow(
                            key: ValueKey('row-${entries[index].id}'),
                            entry: entries[index],
                            heroPrefix: kLibraryHeroPrefix,
                          ),
                        ),
                        childCount: entries.length,
                      ),
                    );
                  }
                  return SliverList.separated(
                    itemCount: entries.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: PfSpace.sm),
                    itemBuilder: (context, index) => StaggeredReveal(
                      index: index % LibraryBrowseBloc.pageSize,
                      child: LibraryEntryRow(
                        key: ValueKey('row-${entries[index].id}'),
                        entry: entries[index],
                        heroPrefix: kLibraryHeroPrefix,
                      ),
                    ),
                  );
                },
              ),
      ),
      SliverToBoxAdapter(child: _ListFooter(state: state)),
    ];
  }
}

/// Search field, sort menu, filter button and the list or grid toggle.
class _LibraryToolbar extends StatelessWidget {
  const _LibraryToolbar({required this.state, required this.controller});

  final LibraryBrowseState state;
  final TextEditingController controller;

  Future<void> _openFilters(BuildContext context) async {
    final bloc = context.read<LibraryBrowseBloc>();
    final collections = context.read<UserCollectionsBloc>();
    if (collections.state.status == UserCollectionsStatus.initial) {
      collections.add(const UserCollectionsLoadRequested());
    }
    final result = await LibraryFiltersSheet.show(
      context,
      filters: bloc.state.filters,
      options: context.read<FilterOptionsCubit>(),
      collections: collections,
    );
    if (result != null) bloc.add(LibraryBrowseFiltersChanged(result));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.pfColors;
    final bloc = context.read<LibraryBrowseBloc>();
    final count = state.filters.activeChipCount;
    final grid = state.viewMode == LibraryViewMode.grid;

    return Padding(
      padding: const EdgeInsets.fromLTRB(PfSpace.lg, 0, PfSpace.sm, PfSpace.xs),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 44,
              child: TextField(
                key: const Key('library_search_field'),
                controller: controller,
                textInputAction: TextInputAction.search,
                onChanged: (q) => bloc.add(LibraryBrowseQueryChanged(q)),
                decoration: InputDecoration(
                  hintText: l10n.librarySearchHint,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  suffixIcon: ValueListenableBuilder(
                    valueListenable: controller,
                    builder: (context, value, _) => value.text.isEmpty
                        ? const SizedBox.shrink()
                        : IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            tooltip: l10n.clearSearch,
                            onPressed: () {
                              controller.clear();
                              bloc.add(const LibraryBrowseQueryChanged(''));
                            },
                          ),
                  ),
                  border: const OutlineInputBorder(
                    borderRadius: PfRadius.pillAll,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: PfRadius.pillAll,
                    borderSide: BorderSide(color: colors.hairline),
                  ),
                ),
              ),
            ),
          ),
          PopupMenuButton<LibrarySort>(
            key: const Key('library_sort_menu'),
            tooltip: l10n.librarySortTooltip,
            icon: const Icon(Icons.sort),
            initialValue: state.filters.sort,
            onSelected: (sort) => bloc.add(LibraryBrowseSortChanged(sort)),
            itemBuilder: (context) => [
              for (final sort in LibrarySort.values)
                CheckedPopupMenuItem(
                  value: sort,
                  checked: sort == state.filters.sort,
                  child: Text(sort.localizedName(context)),
                ),
            ],
          ),
          Badge(
            isLabelVisible: count > 0,
            label: Text('$count'),
            offset: const Offset(-4, 4),
            child: IconButton(
              key: const Key('library_filters_button'),
              icon: const Icon(Icons.tune),
              tooltip: l10n.libraryFiltersTitle,
              onPressed: () => _openFilters(context),
            ),
          ),
          IconButton(
            key: const Key('library_view_toggle'),
            icon: Icon(grid ? Icons.view_list_outlined : Icons.grid_view),
            tooltip: grid ? l10n.libraryViewList : l10n.libraryViewGrid,
            onPressed: () => bloc.add(
              LibraryBrowseViewModeChanged(
                grid ? LibraryViewMode.list : LibraryViewMode.grid,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One-tap favorites and status chips with counts from the stats.
class _QuickFilters extends StatelessWidget {
  const _QuickFilters({required this.state});

  final LibraryBrowseState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<LibraryBrowseBloc>();
    final stats = context.watch<StatsCubit>().state.stats;
    final filters = state.filters;

    String withCount(String label, int? count) =>
        count == null ? label : '$label · $count';

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: PfSpace.lg),
        children: [
          Center(
            child: FilterChip(
              key: const Key('library_filter_favorites'),
              selected: filters.favoritesOnly,
              avatar: Icon(
                filters.favoritesOnly ? Icons.favorite : Icons.favorite_border,
                size: 16,
              ),
              label: Text(
                withCount(l10n.libraryFavoritesFilter, stats?.favorites),
              ),
              onSelected: (selected) => bloc.add(
                LibraryBrowseFiltersChanged(
                  filters.copyWith(favoritesOnly: selected),
                ),
              ),
            ),
          ),
          for (final status in GameStatus.values)
            Padding(
              padding: const EdgeInsets.only(left: PfSpace.sm),
              child: Center(
                child: FilterChip(
                  key: Key('library_filter_${status.toApiString()}'),
                  selected: filters.statuses.contains(status),
                  avatar: Icon(status.icon, size: 16),
                  label: Text(
                    withCount(
                      status.localizedName(context),
                      stats?.countFor(status),
                    ),
                  ),
                  onSelected: (selected) {
                    final next = {...filters.statuses};
                    selected ? next.add(status) : next.remove(status);
                    bloc.add(
                      LibraryBrowseFiltersChanged(
                        filters.copyWith(statuses: next),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Removable chips for the sheet-only filters, plus clear all and the count.
class _AdvancedChips extends StatelessWidget {
  const _AdvancedChips({required this.state});

  final LibraryBrowseState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<LibraryBrowseBloc>();
    final filters = state.filters;
    final colors = context.pfColors;
    final l10n = context.l10n;
    final advanced = LibraryFilters(
      genreIds: filters.genreIds,
      platformIds: filters.platformIds,
      minScore: filters.minScore,
      collectionId: filters.collectionId,
    );
    final chips = libraryFilterChips(
      context,
      filters: advanced,
      options: context.watch<FilterOptionsCubit>().state,
      collections: context.watch<UserCollectionsBloc>().state,
      onChanged: (changed) => bloc.add(
        LibraryBrowseFiltersChanged(
          filters.copyWith(
            genreIds: changed.genreIds,
            platformIds: changed.platformIds,
            minScore: changed.minScore,
            clearMinScore: changed.minScore == null,
            collectionId: changed.collectionId,
            clearCollection: changed.collectionId == null,
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActiveFilterChipsRow(
          chips: chips,
          onClearAll: () {
            bloc.add(LibraryBrowseFiltersChanged(filters.cleared()));
          },
        ),
        if (filters.hasActiveFilters &&
            state.status == LibraryBrowseStatus.success)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PfSpace.lg,
              PfSpace.xs,
              PfSpace.lg,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.libraryMatchCount(state.totalCount),
                    style: PfTypography.monoStyle(colors.textMed),
                  ),
                ),
                if (chips.isEmpty)
                  TextButton(
                    key: const Key('library_clear_filters'),
                    onPressed: () => bloc.add(
                      LibraryBrowseFiltersChanged(filters.cleared()),
                    ),
                    child: Text(l10n.searchFiltersClearAll),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ListFooter extends StatelessWidget {
  const _ListFooter({required this.state});

  final LibraryBrowseState state;

  @override
  Widget build(BuildContext context) {
    final Widget child;
    if (state.loadMoreFailed && !state.isLoadingMore) {
      child = ErrorState(
        compact: true,
        message: (state.errorKind ?? AppErrorKind.unknown).message(context),
        onRetry: () => context.read<LibraryBrowseBloc>().add(
          state.hasMore
              ? const LibraryBrowseLoadMore()
              : const LibraryBrowseRefreshRequested(),
        ),
      );
    } else if (state.isLoadingMore || state.hasMore) {
      child = const Center(
        child: SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    } else {
      child = const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: PfSpace.sm, bottom: 96),
      child: child,
    );
  }
}

class _EmptyLibraryView extends StatelessWidget {
  const _EmptyLibraryView({required this.filters});

  final LibraryFilters filters;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // The default (unfiltered) empty library is the user's first impression,
    // so it gets a headline, hint and a call to action. Filtered views offer
    // to clear the filters.
    if (filters.hasActiveFilters) {
      final onlyFavorites =
          filters.favoritesOnly &&
          filters.activeChipCount == 1 &&
          filters.query.trim().isEmpty;
      final onlyStatus =
          filters.statuses.length == 1 &&
          filters.activeChipCount == 1 &&
          filters.query.trim().isEmpty;
      return EmptyState(
        icon: onlyFavorites
            ? Icons.favorite_border
            : onlyStatus
            ? filters.statuses.first.icon
            : Icons.filter_alt_off,
        title: onlyFavorites
            ? l10n.emptyFavorites
            : onlyStatus
            ? l10n.emptyStatusGames
            : l10n.libraryNoMatchesTitle,
        message: onlyFavorites || onlyStatus ? null : l10n.libraryNoMatchesHint,
        action: OutlinedButton.icon(
          onPressed: () => context.read<LibraryBrowseBloc>().add(
            LibraryBrowseFiltersChanged(filters.cleared()),
          ),
          icon: const Icon(Icons.filter_alt_off),
          label: Text(l10n.searchClearFilters),
        ),
      );
    }
    return EmptyState(
      icon: Icons.sports_esports_outlined,
      title: l10n.emptyLibraryTitle,
      message: l10n.emptyLibraryHint,
      action: FilledButton.icon(
        onPressed: () => context.pushNamed(AppRouter.searchName),
        icon: const Icon(Icons.add),
        label: Text(l10n.addFirstGame),
      ),
    );
  }
}
