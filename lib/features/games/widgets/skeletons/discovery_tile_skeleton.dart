import 'package:flutter/material.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/widgets/game_card.dart';
import 'package:picklog/core/widgets/skeleton_box.dart';
import 'package:picklog/features/games/widgets/game_rail.dart';

/// Skeleton placeholder mirroring [GameCard]: a rounded cover that fills the
/// cell plus a title line in the caption area. Callers size it like the real
/// card (a rail slot or a grid cell) so nothing jumps on load.
class DiscoveryTileSkeleton extends StatelessWidget {
  const DiscoveryTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Expanded(child: SkeletonBox()),
        SizedBox(
          height: GameCard.captionHeightFor(MediaQuery.textScalerOf(context)),
          child: const Padding(
            padding: EdgeInsets.only(top: PfSpace.sm, right: PfSpace.xl),
            child: Align(
              alignment: Alignment.topLeft,
              child: SkeletonBox(height: 12, borderRadius: PfRadius.sm),
            ),
          ),
        ),
      ],
    );
  }
}

/// A horizontally scrolling row of [DiscoveryTileSkeleton]s that matches
/// [GameRail] (same card width, height, padding and gaps).
class DiscoveryRowSkeleton extends StatelessWidget {
  const DiscoveryRowSkeleton({this.itemCount = 5, super.key});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: railHeight(context),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: PfSpace.lg),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(width: PfSpace.md),
        itemBuilder: (context, index) => const SizedBox(
          width: kRailCardWidth,
          child: DiscoveryTileSkeleton(),
        ),
      ),
    );
  }
}
