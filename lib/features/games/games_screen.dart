import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/pf_typography.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/utils/app_router.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/widgets/animated_state_switcher.dart';
import 'package:picklog/core/widgets/app_scaffold.dart';
import 'package:picklog/core/widgets/favorite_button.dart';
import 'package:picklog/core/widgets/game_card.dart';
import 'package:picklog/core/widgets/score_badge.dart';
import 'package:picklog/core/widgets/section_header.dart';
import 'package:picklog/core/widgets/staggered_reveal.dart';
import 'package:picklog/core/widgets/state_views.dart';
import 'package:picklog/features/games/widgets/discovery_game_tile.dart';
import 'package:picklog/features/games/widgets/skeletons/library_entry_skeleton.dart';
import 'package:picklog/features/library/bloc/library_bloc.dart';
import 'package:picklog/features/library/bloc/library_event.dart';
import 'package:picklog/features/library/bloc/library_state.dart';
import 'package:picklog/features/library/library_entry_model.dart';
import 'package:picklog/features/library/library_formatters.dart';
import 'package:picklog/features/library/widgets/library_failure_listener.dart';
import 'package:picklog/features/library/widgets/library_status_pill.dart';

/// Hero prefix for library covers (unique against the other shell tabs).
const String kLibraryHeroPrefix = 'library-';

/// Library screen: the user's games with favorite and status filters.
///
/// Layout is a header (eyebrow, title, count), a filter row and the entry
/// list. Filters, sort and collections can slot into the header and filter
/// row without changing the list.
class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LibraryFailureListener(
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.libraryTitle),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => context.pushNamed(AppRouter.searchName),
              tooltip: context.l10n.addGame,
            ),
            const SizedBox(width: PfSpace.xs),
          ],
        ),
        body: BlocBuilder<LibraryBloc, LibraryState>(
          builder: (context, state) {
            final Object view;
            final Widget child;
            if (state.isLoading && !state.hasEntries) {
              view = LibraryStatus.loading;
              child = const LibraryListSkeleton();
            } else if (state.status == LibraryStatus.failure &&
                !state.hasEntries) {
              view = LibraryStatus.failure;
              child = ErrorState(
                message: context.l10n.failedToLoadLibrary,
                onRetry: () {
                  if (state.userId != null) {
                    context.read<LibraryBloc>().add(
                      LibraryLoadRequested(userId: state.userId!),
                    );
                  }
                },
              );
            } else {
              view = LibraryStatus.success;
              child = _LibraryContent(state: state);
            }
            return AnimatedStateSwitcher(
              stateKey: view,
              child: MaxWidthBox(child: child),
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.pushNamed(AppRouter.searchName),
          icon: const Icon(Icons.add),
          label: Text(context.l10n.addGame),
        ),
      ),
    );
  }
}

class _LibraryContent extends StatelessWidget {
  const _LibraryContent({required this.state});

  final LibraryState state;

  Future<void> _refresh(BuildContext context) async {
    final userId = state.userId;
    if (userId == null) return;
    final bloc = context.read<LibraryBloc>()
      ..add(LibraryRefreshRequested(userId: userId));
    await bloc.stream.first.timeout(
      const Duration(seconds: 12),
      onTimeout: () => bloc.state,
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = state.filteredEntries;
    final width = MediaQuery.sizeOf(context).width;
    final twoColumns = width >= PfBreakpoints.twoPane;

    return RefreshIndicator(
      onRefresh: () => _refresh(context),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _LibraryHeader(count: state.entries.length),
          ),
          SliverToBoxAdapter(child: _FilterChips(state: state)),
          if (entries.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyLibraryView(
                showFavoritesOnly: state.showFavoritesOnly,
                statusFilter: state.statusFilter,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                PfSpace.lg,
                PfSpace.sm,
                PfSpace.lg,
                96,
              ),
              sliver: twoColumns
                  ? SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 560,
                            mainAxisExtent: 100,
                            crossAxisSpacing: PfSpace.md,
                            mainAxisSpacing: PfSpace.sm,
                          ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => StaggeredReveal(
                          index: index,
                          child: _LibraryEntryCard(entry: entries[index]),
                        ),
                        childCount: entries.length,
                      ),
                    )
                  : SliverList.separated(
                      itemCount: entries.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: PfSpace.sm),
                      itemBuilder: (context, index) => StaggeredReveal(
                        index: index,
                        child: _LibraryEntryCard(entry: entries[index]),
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}

class _LibraryHeader extends StatelessWidget {
  const _LibraryHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.pfColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PfSpace.lg,
        PfSpace.xs,
        PfSpace.lg,
        PfSpace.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: Eyebrow(context.l10n.libraryEyebrow)),
          Text(
            context.l10n.libraryGameCount(count),
            style: PfTypography.monoStyle(colors.textMed),
          ),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.state});

  final LibraryState state;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: PfSpace.lg),
      child: Row(
        children: [
          FilterChip(
            selected: state.showFavoritesOnly,
            avatar: Icon(
              state.showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
              size: 16,
            ),
            label: Text(context.l10n.favoritesWithCount(state.favoritesCount)),
            onSelected: (selected) {
              context.read<LibraryBloc>().add(
                LibraryFilterToggled(showFavoritesOnly: selected),
              );
            },
          ),
          const SizedBox(width: PfSpace.sm),
          ...GameStatus.values.map((status) {
            final count = state.statusCounts[status] ?? 0;
            return Padding(
              padding: const EdgeInsets.only(right: PfSpace.sm),
              child: FilterChip(
                selected: state.statusFilter == status,
                avatar: Icon(status.icon, size: 16),
                label: Text('${status.localizedName(context)} · $count'),
                onSelected: (selected) {
                  context.read<LibraryBloc>().add(
                    LibraryStatusFilterChanged(
                      status: selected ? status : null,
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _LibraryEntryCard extends StatelessWidget {
  const _LibraryEntryCard({required this.entry});

  final LibraryEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final meta = <Widget>[
      LibraryStatusPill(status: entry.status, dense: true),
      if (entry.score != null) ScoreBadge(score: entry.score),
      Text(
        [
          if (entry.platform != null) entry.platform!.displayName,
          formatPlaytime(context, entry.playtimeMinutes),
        ].join(' · '),
        style: theme.textTheme.bodySmall,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ];

    return GameTile(
      title: entry.game.name,
      coverUrl: entry.game.coverUrl,
      heroTag: gameCoverHeroTag(kLibraryHeroPrefix, entry.game.igdbId),
      semanticLabel: l10n.libraryEntryLabel(
        entry.game.name,
        entry.status.localizedName(context),
      ),
      meta: meta,
      onTap: () => openGameDetails(
        context,
        entry.game.igdbId,
        heroPrefix: kLibraryHeroPrefix,
      ),
      trailing: FavoriteButton(
        isFavorite: entry.isFavorite,
        addLabel: l10n.addToFavorites,
        removeLabel: l10n.favorited,
        onPressed: () => context.read<LibraryBloc>().add(
          LibraryToggleFavoriteRequested(entryId: entry.id),
        ),
      ),
    );
  }
}

class _EmptyLibraryView extends StatelessWidget {
  const _EmptyLibraryView({required this.showFavoritesOnly, this.statusFilter});

  final bool showFavoritesOnly;
  final GameStatus? statusFilter;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // The default (unfiltered) empty library is the user's first impression,
    // so it gets a headline, hint and a call to action. Filtered views keep a
    // concise message.
    if (showFavoritesOnly) {
      return EmptyState(
        icon: Icons.favorite_border,
        title: l10n.emptyFavorites,
      );
    }
    if (statusFilter != null) {
      return EmptyState(icon: statusFilter!.icon, title: l10n.emptyStatusGames);
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
