import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:picklog/core/utils/app_router.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/widgets/visibility_hero.dart';
import 'package:picklog/features/games/widgets/skeletons/library_entry_skeleton.dart';
import 'package:picklog/features/library/bloc/library_bloc.dart';
import 'package:picklog/features/library/bloc/library_event.dart';
import 'package:picklog/features/library/bloc/library_state.dart';
import 'package:picklog/features/library/library_entry_model.dart';

/// Games screen - displays user's game library with filtering and management.
///
/// Features:
/// - View all games in library
/// - Filter by favorites only
/// - Filter by status (playing, finished, etc.)
/// - Add new games via search
/// - Toggle favorites with optimistic UI
class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.libraryTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.pushNamed(AppRouter.searchName),
            tooltip: context.l10n.addGame,
          ),
        ],
      ),
      body: BlocBuilder<LibraryBloc, LibraryState>(
        builder: (context, state) {
          if (state.isLoading && !state.hasEntries) {
            return const LibraryListSkeleton();
          }

          if (state.status == LibraryStatus.failure && !state.hasEntries) {
            return _ErrorView(
              message: context.l10n.failedToLoadLibrary,
              onRetry: () {
                if (state.userId != null) {
                  context.read<LibraryBloc>().add(
                    LibraryLoadRequested(userId: state.userId!),
                  );
                }
              },
            );
          }

          return Column(
            children: [
              // Filter chips
              _FilterChips(state: state),
              // Library entries list
              Expanded(
                child: state.filteredEntries.isEmpty
                    ? _EmptyLibraryView(
                        showFavoritesOnly: state.showFavoritesOnly,
                        statusFilter: state.statusFilter,
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          if (state.userId != null) {
                            context.read<LibraryBloc>().add(
                              LibraryRefreshRequested(userId: state.userId!),
                            );
                          }
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: state.filteredEntries.length,
                          itemBuilder: (context, index) {
                            final entry = state.filteredEntries[index];
                            return _LibraryEntryCard(entry: entry);
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(AppRouter.searchName),
        icon: const Icon(Icons.add),
        label: Text(context.l10n.addGame),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.state});

  final LibraryState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Favorites filter
            FilterChip(
              selected: state.showFavoritesOnly,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    state.showFavoritesOnly
                        ? Icons.favorite
                        : Icons.favorite_border,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(context.l10n.favoritesWithCount(state.favoritesCount)),
                ],
              ),
              onSelected: (selected) {
                context.read<LibraryBloc>().add(
                  LibraryFilterToggled(showFavoritesOnly: selected),
                );
              },
            ),
            const SizedBox(width: 8),
            // Status filters
            ...GameStatus.values.map((status) {
              final count = state.statusCounts[status] ?? 0;
              final isSelected = state.statusFilter == status;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: isSelected,
                  label: Text('${status.localizedName(context)} ($count)'),
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

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Semantics(
        label: context.l10n.libraryEntryLabel(
          entry.game.name,
          entry.status.localizedName(context),
        ),
        button: true,
        onTap: () => context.pushNamed(
          AppRouter.gameDetailsName,
          pathParameters: {'id': entry.game.igdbId.toString()},
        ),
        child: InkWell(
          onTap: () => context.pushNamed(
            AppRouter.gameDetailsName,
            pathParameters: {'id': entry.game.igdbId.toString()},
          ),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Game cover
                VisibilityHero(
                  tag: 'game-cover-${entry.game.igdbId}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: entry.game.coverUrl != null
                        ? Image.network(
                            entry.game.coverUrl!,
                            width: 60,
                            height: 80,
                            fit: BoxFit.cover,
                            semanticLabel: context.l10n.gameCoverLabel(
                              entry.game.name,
                            ),
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  width: 60,
                                  height: 80,
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                  child: const Icon(Icons.videogame_asset),
                                ),
                          )
                        : Container(
                            width: 60,
                            height: 80,
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.videogame_asset),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                // Game info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.game.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Status chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(entry.status, theme),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          entry.status.localizedName(context),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Platform and playtime
                      Row(
                        children: [
                          if (entry.platform != null) ...[
                            Text(
                              entry.platform!.displayName,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const Text(' • '),
                          ],
                          Text(
                            entry.playtimeFormatted,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (entry.score != null) ...[
                            const Text(' • '),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 14,
                                  color: Colors.amber.shade600,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${entry.score}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Favorite button
                IconButton(
                  tooltip: entry.isFavorite
                      ? context.l10n.favorited
                      : context.l10n.addToFavorites,
                  icon: Icon(
                    entry.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: entry.isFavorite ? Colors.red : null,
                    semanticLabel: entry.isFavorite
                        ? context.l10n.favorited
                        : context.l10n.addToFavorites,
                  ),
                  onPressed: () {
                    context.read<LibraryBloc>().add(
                      LibraryToggleFavoriteRequested(entryId: entry.id),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(GameStatus status, ThemeData theme) {
    switch (status) {
      case GameStatus.playing:
        return Colors.green;
      case GameStatus.finished:
        return Colors.blue;
      case GameStatus.planned:
        return Colors.orange;
      case GameStatus.onHold:
        return Colors.purple;
      case GameStatus.dropped:
        return Colors.red;
    }
  }
}

class _EmptyLibraryView extends StatelessWidget {
  const _EmptyLibraryView({required this.showFavoritesOnly, this.statusFilter});

  final bool showFavoritesOnly;
  final GameStatus? statusFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // The default (unfiltered) empty library is the user's first impression,
    // so it gets a warm headline + hint. Filtered views keep their concise,
    // self-explanatory single message.
    final bool isDefaultEmpty = !showFavoritesOnly && statusFilter == null;
    final String title;
    final String? hint;
    if (showFavoritesOnly) {
      title = context.l10n.emptyFavorites;
      hint = null;
    } else if (statusFilter != null) {
      title = context.l10n.emptyStatusGames;
      hint = null;
    } else {
      title = context.l10n.emptyLibraryTitle;
      hint = context.l10n.emptyLibraryHint;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_esports_outlined,
              size: 80,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: isDefaultEmpty
                  ? theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    )
                  : theme.textTheme.bodyLarge,
            ),
            if (hint != null) ...[
              const SizedBox(height: 8),
              Text(
                hint,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.pushNamed(AppRouter.searchName),
              icon: const Icon(Icons.add),
              label: Text(context.l10n.addFirstGame),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(context.l10n.browseRetry),
            ),
          ],
        ),
      ),
    );
  }
}
