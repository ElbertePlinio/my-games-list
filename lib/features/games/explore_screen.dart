import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picklog/core/domain/models/app_failure.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/pf_typography.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/utils/error_l10n.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/widgets/animated_state_switcher.dart';
import 'package:picklog/core/widgets/game_card.dart';
import 'package:picklog/core/widgets/pf_button.dart';
import 'package:picklog/core/widgets/responsive_grid.dart';
import 'package:picklog/core/widgets/section_header.dart';
import 'package:picklog/core/widgets/skeleton_box.dart';
import 'package:picklog/core/widgets/staggered_reveal.dart';
import 'package:picklog/core/widgets/state_views.dart';
import 'package:picklog/features/games/bloc/explore_bloc.dart';
import 'package:picklog/features/games/bloc/filter_options_cubit.dart';
import 'package:picklog/features/games/catalog_filters.dart';
import 'package:picklog/features/games/widgets/catalog_filter_fields.dart';
import 'package:picklog/features/games/widgets/discovery_game_tile.dart';

/// Hero prefix for Explore covers.
const String kExploreHeroPrefix = 'explore-';

/// Width of the filter side panel on wide screens.
const double kExplorePanelWidth = 340;

/// Catalog explorer: genre, platform, year and rating filters with a sort,
/// over an infinite grid. Phones edit filters in a bottom sheet; at 840 and
/// wider a side panel applies them live.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent * 0.85) {
      context.read<ExploreBloc>().add(const ExploreLoadMore());
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= PfBreakpoints.twoPane;
    final results = _ExploreResults(scrollController: _scrollController);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.exploreTitle)),
      body: SafeArea(
        top: false,
        child: wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(
                    width: kExplorePanelWidth,
                    child: _ExploreSidePanel(),
                  ),
                  VerticalDivider(width: 1, color: context.pfColors.hairline),
                  Expanded(child: results),
                ],
              )
            : Column(
                children: [
                  const _PhoneToolbar(),
                  Expanded(child: results),
                ],
              ),
      ),
    );
  }
}

/// Phone header: the filter button with a count badge and the active chips.
class _PhoneToolbar extends StatelessWidget {
  const _PhoneToolbar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExploreBloc, ExploreState>(
      buildWhen: (p, c) => p.filters != c.filters,
      builder: (context, state) {
        final count =
            state.filters.catalog.activeCount +
            (state.filters.sort == ExploreSort.popular ? 0 : 1);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PfSpace.lg,
                PfSpace.xs,
                PfSpace.lg,
                PfSpace.xs,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      state.filters.sort.localizedName(context),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Badge(
                    isLabelVisible: count > 0,
                    label: Text('$count'),
                    child: PfButton(
                      key: const Key('explore_filters_button'),
                      label: context.l10n.exploreFiltersButton,
                      icon: Icons.tune,
                      size: PfButtonSize.sm,
                      variant: PfButtonVariant.secondary,
                      onPressed: () => _openSheet(context, state.filters),
                    ),
                  ),
                ],
              ),
            ),
            _ActiveChips(filters: state.filters),
          ],
        );
      },
    );
  }

  Future<void> _openSheet(BuildContext context, ExploreFilters filters) async {
    final bloc = context.read<ExploreBloc>();
    final options = context.read<FilterOptionsCubit>();
    final result = await showModalBottomSheet<ExploreFilters>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      builder: (_) => BlocProvider.value(
        value: options,
        child: ExploreFiltersSheet(filters: filters),
      ),
    );
    if (result != null) bloc.add(ExploreFiltersChanged(result));
  }
}

class _ActiveChips extends StatelessWidget {
  const _ActiveChips({required this.filters});

  final ExploreFilters filters;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ExploreBloc>();
    final options = context.watch<FilterOptionsCubit>().state;
    final chips = catalogFilterChips(
      context,
      filters.catalog,
      options,
      (catalog) =>
          bloc.add(ExploreFiltersChanged(filters.copyWith(catalog: catalog))),
    );
    return ActiveFilterChipsRow(
      chips: chips,
      onClearAll: () => bloc.add(
        ExploreFiltersChanged(
          filters.copyWith(catalog: const CatalogFilters()),
        ),
      ),
    );
  }
}

/// Wide layout: filters applied live from a scrolling side panel.
class _ExploreSidePanel extends StatelessWidget {
  const _ExploreSidePanel();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExploreBloc, ExploreState>(
      buildWhen: (p, c) => p.filters != c.filters,
      builder: (context, state) {
        final bloc = context.read<ExploreBloc>();
        return ListView(
          padding: const EdgeInsets.all(PfSpace.lg),
          children: [
            Row(
              children: [
                Expanded(child: Eyebrow(context.l10n.exploreFiltersTitle)),
                TextButton(
                  onPressed: state.filters.isDefault
                      ? null
                      : () => bloc.add(
                          const ExploreFiltersChanged(ExploreFilters()),
                        ),
                  child: Text(context.l10n.searchFiltersReset),
                ),
              ],
            ),
            const SizedBox(height: PfSpace.sm),
            ExploreFilterPanel(
              filters: state.filters,
              showSort: false,
              onChanged: (filters) => bloc.add(ExploreFiltersChanged(filters)),
            ),
          ],
        );
      },
    );
  }
}

/// Sort control and catalog fields for [ExploreFilters].
class ExploreFilterPanel extends StatelessWidget {
  const ExploreFilterPanel({
    required this.filters,
    required this.onChanged,
    this.showSort = true,
    super.key,
  });

  final ExploreFilters filters;
  final ValueChanged<ExploreFilters> onChanged;

  /// The wide layout shows the sort above the results instead.
  final bool showSort;

  @override
  Widget build(BuildContext context) {
    final options = context.watch<FilterOptionsCubit>().state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showSort) ...[
          FilterSectionCard(
            title: context.l10n.searchSortLabel,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ExploreSortControl(
                sort: filters.sort,
                onChanged: (sort) => onChanged(filters.copyWith(sort: sort)),
              ),
            ),
          ),
          const SizedBox(height: PfSpace.md),
        ],
        CatalogFilterFields(
          value: filters.catalog,
          options: options,
          onRetryOptions: () => context.read<FilterOptionsCubit>().load(),
          onChanged: (catalog) => onChanged(filters.copyWith(catalog: catalog)),
        ),
      ],
    );
  }
}

/// Segmented control for the five explore sort keys.
class ExploreSortControl extends StatelessWidget {
  const ExploreSortControl({
    required this.sort,
    required this.onChanged,
    super.key,
  });

  final ExploreSort sort;
  final ValueChanged<ExploreSort> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ExploreSort>(
      key: const Key('explore_sort_control'),
      showSelectedIcon: false,
      segments: [
        for (final s in ExploreSort.values)
          ButtonSegment(value: s, label: Text(s.localizedName(context))),
      ],
      selected: {sort},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}

/// Phone bottom sheet that edits a draft of the filters.
class ExploreFiltersSheet extends StatefulWidget {
  const ExploreFiltersSheet({required this.filters, super.key});

  final ExploreFilters filters;

  @override
  State<ExploreFiltersSheet> createState() => _ExploreFiltersSheetState();
}

class _ExploreFiltersSheetState extends State<ExploreFiltersSheet> {
  late ExploreFilters _draft = widget.filters;

  @override
  Widget build(BuildContext context) {
    final colors = context.pfColors;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: PfSpace.md, bottom: PfSpace.sm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.hairlineStrong,
              borderRadius: PfRadius.pillAll,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: PfSpace.sm),
            child: Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(context.l10n.cancel),
                ),
                Expanded(
                  child: Text(
                    context.l10n.exploreFiltersTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton(
                  onPressed: _draft.isDefault
                      ? null
                      : () => setState(() => _draft = const ExploreFilters()),
                  child: Text(context.l10n.searchFiltersReset),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.hairline),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(PfSpace.lg),
              children: [
                ExploreFilterPanel(
                  filters: _draft,
                  onChanged: (f) => setState(() => _draft = f),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                PfSpace.lg,
                PfSpace.sm,
                PfSpace.lg,
                PfSpace.lg,
              ),
              child: PfButton(
                key: const Key('explore_apply_button'),
                label: context.l10n.searchFiltersApply,
                expand: true,
                onPressed: () => Navigator.of(context).pop(_draft),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExploreResults extends StatelessWidget {
  const _ExploreResults({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExploreBloc, ExploreState>(
      builder: (context, state) {
        final Object key;
        final Widget child;
        if ((state.isLoading || state.status == ExploreStatus.initial) &&
            !state.hasGames) {
          key = ExploreStatus.loading;
          child = const _ExploreGridSkeleton();
        } else if (state.status == ExploreStatus.failure) {
          key = ExploreStatus.failure;
          child = ErrorState(
            message: (state.errorKind ?? AppErrorKind.unknown).message(context),
            onRetry: () =>
                context.read<ExploreBloc>().add(const ExploreLoadRequested()),
          );
        } else if (!state.hasGames) {
          key = 'empty';
          child = EmptyState(
            icon: Icons.travel_explore,
            title: context.l10n.exploreEmptyTitle,
            message: context.l10n.exploreEmptyHint,
            action: OutlinedButton.icon(
              onPressed: () => context.read<ExploreBloc>().add(
                const ExploreFiltersChanged(ExploreFilters()),
              ),
              icon: const Icon(Icons.filter_alt_off),
              label: Text(context.l10n.searchClearFilters),
            ),
          );
        } else {
          key = ExploreStatus.success;
          child = _ExploreGrid(state: state, controller: scrollController);
        }
        return AnimatedStateSwitcher(stateKey: key, child: child);
      },
    );
  }
}

class _ExploreGrid extends StatelessWidget {
  const _ExploreGrid({required this.state, required this.controller});

  final ExploreState state;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final games = state.games;
    final colors = context.pfColors;
    final wide = MediaQuery.sizeOf(context).width >= PfBreakpoints.twoPane;
    return CustomScrollView(
      controller: controller,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            PfSpace.lg,
            PfSpace.sm,
            PfSpace.lg,
            PfSpace.md,
          ),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.exploreResultCount(games.length),
                    style: PfTypography.monoStyle(colors.textMed),
                  ),
                ),
                if (wide)
                  ExploreSortControl(
                    sort: state.filters.sort,
                    onChanged: (sort) => context.read<ExploreBloc>().add(
                      ExploreFiltersChanged(state.filters.copyWith(sort: sort)),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: PfSpace.lg),
          sliver: SliverResponsiveGrid(
            itemCount: games.length,
            childAspectRatio: kGameCardGridAspectRatio,
            itemBuilder: (context, index) => StaggeredReveal(
              index: index % ExploreBloc.pageSize,
              child: DiscoveryGameTile(
                game: games[index],
                heroTagPrefix: kExploreHeroPrefix,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: PfSpace.xl),
            child: state.loadMoreFailed && !state.isLoadingMore
                ? ErrorState(
                    compact: true,
                    message: context.l10n.searchLoadMoreFailed,
                    onRetry: () => context.read<ExploreBloc>().add(
                      const ExploreLoadMore(),
                    ),
                  )
                : state.isLoadingMore || state.hasMore
                ? const Center(
                    child: SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  )
                : Center(
                    child: Text(
                      context.l10n.exploreEndOfResults,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _ExploreGridSkeleton extends StatelessWidget {
  const _ExploreGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: PfSpace.xxl)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: PfSpace.lg),
          sliver: SliverResponsiveGrid(
            itemCount: 12,
            childAspectRatio: kGameCardGridAspectRatio,
            itemBuilder: (context, index) => const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: SkeletonBox()),
                SizedBox(height: PfSpace.sm),
                SkeletonBox(height: 12, width: 90),
                SizedBox(height: GameCard.captionHeight - PfSpace.sm - 12),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
