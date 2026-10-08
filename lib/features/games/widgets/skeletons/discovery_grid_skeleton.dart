import 'package:flutter/material.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/widgets/game_card.dart';
import 'package:picklog/core/widgets/responsive_grid.dart';
import 'package:picklog/core/widgets/skeleton_box.dart';
import 'package:picklog/features/games/widgets/skeletons/discovery_tile_skeleton.dart';

/// Skeleton for the discovery grid screens. Mirrors the real responsive grid
/// (same column count, cell ratio, spacing and padding) so the first page of
/// cards drops in without shifting layout.
class DiscoveryGridSkeleton extends StatelessWidget {
  const DiscoveryGridSkeleton({this.itemCount = 6, super.key});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => GridView.builder(
        padding: const EdgeInsets.all(PfSpace.lg),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: ResponsiveGrid.coverDelegate(
          constraints.maxWidth - PfSpace.lg * 2,
          childAspectRatio: kGameCardGridAspectRatio,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) => const DiscoveryTileSkeleton(),
      ),
    );
  }
}

/// Skeleton for list views of [GameTile] rows (same padding, cover and gaps).
class DiscoveryListSkeleton extends StatelessWidget {
  const DiscoveryListSkeleton({this.itemCount = 8, super.key});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(PfSpace.lg),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: PfSpace.sm),
      itemBuilder: (context, index) => const GameTileSkeleton(),
    );
  }
}

/// One skeleton row matching [GameTile].
class GameTileSkeleton extends StatelessWidget {
  const GameTileSkeleton({this.coverWidth = 56, super.key});

  final double coverWidth;

  @override
  Widget build(BuildContext context) {
    final colors = context.pfColors;
    return Container(
      padding: const EdgeInsets.all(PfSpace.md),
      decoration: BoxDecoration(
        color: colors.surface1,
        borderRadius: PfRadius.cardAll,
        border: Border.all(color: colors.hairline),
      ),
      child: Row(
        children: [
          SkeletonBox(
            width: coverWidth,
            height: coverWidth / kCoverAspectRatio,
            borderRadius: PfRadius.sm + 2,
          ),
          const SizedBox(width: PfSpace.md),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(height: 14, borderRadius: PfRadius.sm),
                SizedBox(height: PfSpace.sm),
                SkeletonBox(width: 96, height: 18, borderRadius: PfRadius.pill),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
