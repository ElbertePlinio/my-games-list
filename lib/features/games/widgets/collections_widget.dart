import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/widgets/section_header.dart';
import 'package:picklog/core/widgets/state_views.dart';
import 'package:picklog/features/games/bloc/collections_bloc.dart';
import 'package:picklog/features/games/bloc/collections_event.dart';
import 'package:picklog/features/games/bloc/collections_state.dart';
import 'package:picklog/features/games/collection_model.dart';
import 'package:picklog/features/games/widgets/discovery_game_tile.dart';
import 'package:picklog/features/games/widgets/game_rail.dart';
import 'package:picklog/features/games/widgets/skeletons/discovery_tile_skeleton.dart';

const int _maxTiles = 20;
// Default per-surface cap on how many collection rows render, so editorial
// content doesn't push the primary discovery rows off-screen. The Home surface
// uses this default; Browse opts into more (see [CollectionsWidget.unbounded]).
const int _defaultMaxCollections = 3;

/// Curated collections rows on the home (GET /home/collections). Collections
/// are editorial content: the block hides when there is nothing curated and
/// shows an inline retry when loading fails.
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
          // Shimmer a rail while the first load is in flight, show an inline
          // retry on failure, and hide when there is simply nothing curated.
          if (state.isLoading) {
            return const Padding(
              padding: EdgeInsets.only(top: PfSpace.xl),
              child: DiscoveryRowSkeleton(),
            );
          }
          if (state.status == CollectionsStatus.failure) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeader(title: context.l10n.collectionsSectionTitle),
                ErrorState(
                  compact: true,
                  message: context.l10n.failedToLoadGames,
                  onRetry: () => context.read<CollectionsBloc>().add(
                    const CollectionsLoadRequested(),
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
    final count = collection.games.length > _maxTiles
        ? _maxTiles
        : collection.games.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: collection.title,
          subtitle: collection.description,
        ),
        GameRail(
          itemCount: count,
          // Per-collection Hero prefix so the same game across
          // collections/rows doesn't collide.
          itemBuilder: (context, index) => DiscoveryGameTile(
            game: collection.games[index],
            isCompact: true,
            heroTagPrefix: '${heroTagPrefix}col-${collection.id}-',
          ),
        ),
      ],
    );
  }
}
