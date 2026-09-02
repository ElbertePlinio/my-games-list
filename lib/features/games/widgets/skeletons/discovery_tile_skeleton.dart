import 'package:flutter/material.dart';
import 'package:picklog/core/widgets/skeleton_box.dart';

/// Skeleton placeholder mirroring [DiscoveryGameTile]'s rounded cover.
///
/// The tile itself only draws a 12px-radius cover that fills its parent, so the
/// skeleton is a single full-bleed [SkeletonBox]. Callers must wrap it in the
/// same sizing the real tile uses (an `AspectRatio(0.7)` inside a 200px row for
/// compact tiles, or the grid cell for the full tile) so there is no layout
/// jump when the real tile replaces it.
class DiscoveryTileSkeleton extends StatelessWidget {
  const DiscoveryTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonBox();
  }
}

/// A horizontally scrolling row of [DiscoveryTileSkeleton]s that matches the
/// real discovery row layout (200px tall, `AspectRatio(0.7)` tiles, 16px side
/// padding, 12px gaps). Used for the home discovery sections and
/// recommendations row while their first page loads.
class DiscoveryRowSkeleton extends StatelessWidget {
  const DiscoveryRowSkeleton({this.itemCount = 5, super.key});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(right: index < itemCount - 1 ? 12 : 0),
            child: const AspectRatio(
              aspectRatio: 0.7,
              child: DiscoveryTileSkeleton(),
            ),
          );
        },
      ),
    );
  }
}
