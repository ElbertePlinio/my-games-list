import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picklog/core/domain/models/app_failure.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/utils/error_l10n.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/widgets/app_scaffold.dart';
import 'package:picklog/core/widgets/staggered_reveal.dart';
import 'package:picklog/core/widgets/state_views.dart';
import 'package:picklog/features/games/bloc/game_search_bloc.dart';
import 'package:picklog/features/games/bloc/game_search_event.dart';
import 'package:picklog/features/games/bloc/game_search_filters.dart';
import 'package:picklog/features/games/bloc/game_search_state.dart';
import 'package:picklog/features/games/search_game_model.dart';
import 'package:picklog/features/games/widgets/game_search_card.dart';
import 'package:picklog/features/games/widgets/search_filters_sheet.dart';
import 'package:picklog/features/games/widgets/skeletons/search_card_skeleton.dart';

class GameSearchScreen extends StatefulWidget {
  const GameSearchScreen({super.key});

  @override
  State<GameSearchScreen> createState() => _GameSearchScreenState();
}

class _GameSearchScreenState extends State<GameSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<GameSearchBloc>().add(const GameSearchLoadMore());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.searchGamesTitle)),
      body: SafeArea(
        top: false,
        child: MaxWidthBox(
          maxWidth: PfBreakpoints.content,
          child: Column(
            children: [
              _SearchBar(controller: _searchController),
              BlocBuilder<GameSearchBloc, GameSearchState>(
                buildWhen: (previous, current) =>
                    previous.games != current.games ||
                    previous.filters != current.filters,
                builder: (context, state) {
                  if (state.games.isEmpty) return const SizedBox.shrink();
                  return _ActiveFiltersRow(state: state);
                },
              ),
              Expanded(
                child: BlocBuilder<GameSearchBloc, GameSearchState>(
                  builder: (context, state) {
                    if (state.status == GameSearchStatus.initial) {
                      return _InitialState();
                    }

                    if (state.isLoading) {
                      return _LoadingState();
                    }

                    if (state.status == GameSearchStatus.failure) {
                      return ErrorState(
                        message: (state.errorKind ?? AppErrorKind.unknown)
                            .message(context),
                        onRetry: () => context.read<GameSearchBloc>().add(
                          const GameSearchRetryRequested(),
                        ),
                      );
                    }

                    if (state.isEmptyByFilters) {
                      return _FilteredEmptyState(
                        canLoadMore: state.canLoadMore,
                      );
                    }

                    if (state.isEmpty) {
                      return _EmptyState(query: state.query);
                    }

                    return _SearchResults(
                      games: state.visibleGames,
                      hasMore: state.canLoadMore,
                      isLoadingMore: state.isLoadingMore,
                      offsetLimitReached: state.offsetLimitReached,
                      loadMoreFailed: state.loadMoreFailed,
                      scrollController: _scrollController,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens the filter/sort sheet seeded with the current state and dispatches
/// the edited filters back to the bloc.
Future<void> _openFilters(BuildContext context, GameSearchState state) async {
  final bloc = context.read<GameSearchBloc>();
  final result = await SearchFiltersSheet.show(
    context: context,
    filters: state.filters,
    genres: state.availableGenres,
    platforms: state.availablePlatforms,
    years: state.availableYears,
  );
  if (result != null) {
    bloc.add(GameSearchFiltersChanged(result));
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PfSpace.lg,
        PfSpace.sm,
        PfSpace.lg,
        PfSpace.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: context.l10n.searchGamesHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: context.l10n.clearSearch,
                  onPressed: () {
                    controller.clear();
                    context.read<GameSearchBloc>().add(const GameSearchClear());
                  },
                ),
                border: const OutlineInputBorder(
                  borderRadius: PfRadius.pillAll,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: PfRadius.pillAll,
                  borderSide: BorderSide(color: context.pfColors.hairline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: PfRadius.pillAll,
                  borderSide: BorderSide(
                    color: context.pfColors.ember,
                    width: 1.5,
                  ),
                ),
              ),
              onChanged: (query) {
                context.read<GameSearchBloc>().add(
                  GameSearchQueryChanged(query),
                );
              },
            ),
          ),
          BlocBuilder<GameSearchBloc, GameSearchState>(
            buildWhen: (previous, current) =>
                previous.games != current.games ||
                previous.filters != current.filters,
            builder: (context, state) {
              if (state.games.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _FilterButton(state: state),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Filter/sort entry point with a badge showing the active filter count.
class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.state});

  final GameSearchState state;

  @override
  Widget build(BuildContext context) {
    final count = state.filters.activeFilterCount;
    return Badge(
      isLabelVisible: count > 0,
      label: Text('$count'),
      child: IconButton.outlined(
        icon: const Icon(Icons.tune),
        tooltip: context.l10n.searchFiltersTooltip,
        onPressed: () => _openFilters(context, state),
      ),
    );
  }
}

/// Horizontally scrolling row of removable chips for the active sort and
/// filters, with a quick "clear all" affordance.
class _ActiveFiltersRow extends StatelessWidget {
  const _ActiveFiltersRow({required this.state});

  final GameSearchState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<GameSearchBloc>();
    final filters = state.filters;

    final chips = <Widget>[];

    if (filters.sort != GameSearchSort.relevance) {
      chips.add(
        _ActiveFilterChip(
          label: context.l10n.searchFilterChipSort(
            sortLabel(context, filters.sort),
          ),
          onRemoved: () => bloc.add(
            GameSearchFiltersChanged(
              filters.copyWith(sort: GameSearchSort.relevance),
            ),
          ),
        ),
      );
    }

    for (final genre in state.availableGenres) {
      if (!filters.genreIds.contains(genre.id)) continue;
      chips.add(
        _ActiveFilterChip(
          label: genre.name,
          onRemoved: () => bloc.add(
            GameSearchFiltersChanged(
              filters.copyWith(
                genreIds: {...filters.genreIds}..remove(genre.id),
              ),
            ),
          ),
        ),
      );
    }

    for (final platform in state.availablePlatforms) {
      if (!filters.platformIds.contains(platform.id)) continue;
      chips.add(
        _ActiveFilterChip(
          label: platform.name,
          onRemoved: () => bloc.add(
            GameSearchFiltersChanged(
              filters.copyWith(
                platformIds: {...filters.platformIds}..remove(platform.id),
              ),
            ),
          ),
        ),
      );
    }

    if (filters.year != null) {
      chips.add(
        _ActiveFilterChip(
          label: context.l10n.searchFilterChipYear(filters.year!),
          onRemoved: () => bloc.add(
            GameSearchFiltersChanged(filters.copyWith(clearYear: true)),
          ),
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: chips.length + 1,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == chips.length) {
                return Center(
                  child: TextButton(
                    onPressed: () => bloc.add(const GameSearchFiltersCleared()),
                    child: Text(context.l10n.searchFiltersClearAll),
                  ),
                );
              }
              return Center(child: chips[index]);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            context.l10n.searchFiltersLoadedScopeCaption,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({required this.label, required this.onRemoved});

  final String label;
  final VoidCallback onRemoved;

  @override
  Widget build(BuildContext context) {
    return InputChip(label: Text(label), onDeleted: onRemoved);
  }
}

class _SearchResults extends StatefulWidget {
  const _SearchResults({
    required this.games,
    required this.hasMore,
    required this.isLoadingMore,
    required this.offsetLimitReached,
    required this.scrollController,
    this.loadMoreFailed = false,
  });

  final List<SearchGame> games;
  final bool hasMore;
  final bool isLoadingMore;
  final bool offsetLimitReached;
  final bool loadMoreFailed;
  final ScrollController scrollController;

  @override
  State<_SearchResults> createState() => _SearchResultsState();
}

class _SearchResultsState extends State<_SearchResults> {
  @override
  void initState() {
    super.initState();
    _maybeAutoLoadMore();
  }

  @override
  void didUpdateWidget(covariant _SearchResults oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeAutoLoadMore();
  }

  /// Filtering can shrink the visible list below the viewport, so the
  /// scroll-driven load-more never fires and paging stalls. When the list
  /// can't scroll but more pages exist, auto-fetch the next page so filtering
  /// never strands pagination.
  void _maybeAutoLoadMore() {
    if (!widget.hasMore || widget.isLoadingMore) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controller = widget.scrollController;
      if (!controller.hasClients) return;
      final position = controller.position;
      // The content does not overflow the viewport, so the user can never
      // scroll to the bottom to trigger load-more — fetch the next page.
      if (position.maxScrollExtent <= 0 &&
          widget.hasMore &&
          !widget.isLoadingMore) {
        context.read<GameSearchBloc>().add(const GameSearchLoadMore());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final games = widget.games;
    final showFooter =
        widget.hasMore ||
        widget.isLoadingMore ||
        widget.offsetLimitReached ||
        widget.loadMoreFailed;
    final wide = MediaQuery.sizeOf(context).width >= PfBreakpoints.twoPane;

    Widget item(BuildContext context, int index) => StaggeredReveal(
      index: index % 20,
      child: GameSearchCard(game: games[index]),
    );

    return CustomScrollView(
      controller: widget.scrollController,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            PfSpace.lg,
            PfSpace.xs,
            PfSpace.lg,
            PfSpace.lg,
          ),
          sliver: wide
              ? SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 560,
                    mainAxisExtent: 124,
                    crossAxisSpacing: PfSpace.md,
                    mainAxisSpacing: PfSpace.sm,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    item,
                    childCount: games.length,
                  ),
                )
              : SliverList.separated(
                  itemCount: games.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: PfSpace.sm),
                  itemBuilder: item,
                ),
        ),
        if (showFooter)
          SliverToBoxAdapter(
            child: widget.offsetLimitReached
                ? _OffsetLimitReachedMessage()
                : widget.loadMoreFailed && !widget.isLoadingMore
                ? Padding(
                    padding: const EdgeInsets.only(bottom: PfSpace.xl),
                    child: ErrorState(
                      compact: true,
                      message: context.l10n.searchLoadMoreFailed,
                      onRetry: () => context.read<GameSearchBloc>().add(
                        const GameSearchRetryRequested(),
                      ),
                    ),
                  )
                : _LoadingMoreIndicator(),
          ),
      ],
    );
  }
}

class _InitialState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _SearchMessageView(
      icon: Icons.search,
      title: context.l10n.searchGamesInitialTitle,
      hint: context.l10n.searchGamesInitialHint,
    );
  }
}

class _LoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.loadingLabel,
      liveRegion: true,
      child: const SearchResultsSkeleton(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return _SearchMessageView(
      icon: Icons.search_off,
      title: context.l10n.searchGamesNoResultsTitle,
      hint: context.l10n.searchGamesNoResults(query),
    );
  }
}

/// Shown when the active filters hide every loaded result. It keeps the
/// "no matches / clear filters" guidance visible, but when more catalog pages
/// exist it auto-fetches them: filtering must never halt paging, otherwise a
/// later page holding matching games would never be loaded.
class _FilteredEmptyState extends StatefulWidget {
  const _FilteredEmptyState({required this.canLoadMore});

  final bool canLoadMore;

  @override
  State<_FilteredEmptyState> createState() => _FilteredEmptyStateState();
}

class _FilteredEmptyStateState extends State<_FilteredEmptyState> {
  @override
  void initState() {
    super.initState();
    _maybeLoadMore();
  }

  @override
  void didUpdateWidget(covariant _FilteredEmptyState oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeLoadMore();
  }

  /// The filtered-empty view never overflows the viewport, so the scroll-driven
  /// load-more can't fire. While more pages exist, fetch the next one so paging
  /// continues until a matching game shows up or the catalog is exhausted.
  void _maybeLoadMore() {
    if (!widget.canLoadMore) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.canLoadMore) return;
      context.read<GameSearchBloc>().add(const GameSearchLoadMore());
    });
  }

  @override
  Widget build(BuildContext context) {
    return _SearchMessageView(
      icon: Icons.filter_alt_off,
      title: context.l10n.searchNoResultsForFiltersTitle,
      hint: context.l10n.searchNoResultsForFiltersHint,
      action: OutlinedButton.icon(
        onPressed: () => context.read<GameSearchBloc>().add(
          const GameSearchFiltersCleared(),
        ),
        icon: const Icon(Icons.filter_alt_off),
        label: Text(context.l10n.searchClearFilters),
      ),
    );
  }
}

/// Shared friendly placeholder for the search screen's initial and no-results
/// states, built on the app-wide [EmptyState].
class _SearchMessageView extends StatelessWidget {
  const _SearchMessageView({
    required this.icon,
    required this.title,
    required this.hint,
    this.action,
  });

  final IconData icon;
  final String title;
  final String hint;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return EmptyState(icon: icon, title: title, message: hint, action: action);
  }
}

class _LoadingMoreIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(PfSpace.xl),
      child: Center(
        child: SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }
}

class _OffsetLimitReachedMessage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Text(
          context.l10n.searchGamesOffsetLimitReached,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: context.pfColors.warningFg),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
