import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picklog/features/games/bloc/collections_bloc.dart';
import 'package:picklog/features/games/bloc/collections_state.dart';
import 'package:picklog/features/games/collection_model.dart';
import 'package:picklog/features/games/widgets/discovery_game_tile.dart';
import 'package:picklog/features/games/widgets/skeletons/discovery_tile_skeleton.dart';

const double _rowHeight = 200;
const double _tileAspectRatio = 0.7;
const int _maxTiles = 20;
// Default per-surface cap on how many collection rows render, so editorial
// content doesn't push the primary discovery rows off-screen. The Home surface
// uses this default; Browse opts into more (see [CollectionsWidget.unbounded]).
const int _defaultMaxCollections = 3;

/// Curated collections rows on the home (GET /home/collections). Collections
/// are editorial/optional content, so the whole block hides when there is
/// nothing to show (loading/empty/error) rather than flashing an empty skeleton.
class CollectionsWidget extends StatelessWidget {
  const CollectionsWidget({
    this.heroTagPrefix = '',
    this.maxCollections = _defaultMaxCollections,
    super.key,
  });

  /// Sentinel for [maxCollections] meaning "show every collection" — used by
  /// Browse, whose whole purpose is to explore more than the Home surface caps.
  static const int unbounded = -1;

  /// Prefixed onto each collection's per-collection Hero namespace so the same
  /// game shown in another simultaneously-alive surface (e.g. the Home tab)
  /// doesn't collide with the Browse tab's collection rows.
  final String heroTagPrefix;

  /// Per-surface cap on how many collection rows to render. Home keeps the
  /// default tight bound; Browse passes [unbounded] to show all of them.
  final int maxCollections;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CollectionsBloc, CollectionsState>(
      builder: (context, state) {
        // Drop empty collections before capping so they don't consume a slot.
        final nonEmpty = state.collections.where((c) => c.games.isNotEmpty);
        final visible =
            (maxCollections == unbounded
                    ? nonEmpty
                    : nonEmpty.take(maxCollections))
                .toList();
        if (visible.isEmpty) {
          // Match Trending/Recommendations: shimmer a row while the first load
          // is in flight, then hide entirely on empty/error so editorial
          // content never flashes a placeholder it can't fill.
          if (state.isLoading) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: DiscoveryRowSkeleton(),
            );
          }
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final collection in visible)
              _CollectionSection(
                collection: collection,
                heroTagPrefix: heroTagPrefix,
              ),
          ],
        );
      },
    );
  }
}

class _CollectionSection extends StatelessWidget {
  const _CollectionSection({required this.collection, this.heroTagPrefix = ''});

  final GameCollection collection;
  final String heroTagPrefix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = collection.games.length > _maxTiles
        ? _maxTiles
        : collection.games.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Icon(
                  Icons.collections_bookmark_outlined,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        collection.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (collection.description != null &&
                        collection.description!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        collection.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: _rowHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: count,
            itemBuilder: (context, index) {
              final game = collection.games[index];
              return Padding(
                padding: EdgeInsets.only(right: index < count - 1 ? 12 : 0),
                child: AspectRatio(
                  aspectRatio: _tileAspectRatio,
                  // Per-collection Hero prefix so the same game across
                  // collections/rows doesn't collide.
                  child: DiscoveryGameTile(
                    game: game,
                    isCompact: true,
                    heroTagPrefix: '${heroTagPrefix}col-${collection.id}-',
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
