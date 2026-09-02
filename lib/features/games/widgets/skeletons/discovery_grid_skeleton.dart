import 'package:flutter/material.dart';
import 'package:picklog/core/widgets/skeleton_box.dart';
import 'package:picklog/features/games/widgets/skeletons/discovery_tile_skeleton.dart';

/// Skeleton for the full discovery grid screen. Mirrors the real grid
/// (2 columns, `childAspectRatio: 0.65`, 12px spacing, 16px padding) so the
/// first page of tiles drops in without shifting layout.
class DiscoveryGridSkeleton extends StatelessWidget {
  const DiscoveryGridSkeleton({this.itemCount = 6, super.key});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => const DiscoveryTileSkeleton(),
    );
  }
}

/// Skeleton for the discovery list view. Mirrors [DiscoveryGameListTile]'s
/// Card (16/4 margin, 12px padding, 60x80 cover, two text lines).
class DiscoveryListSkeleton extends StatelessWidget {
  const DiscoveryListSkeleton({this.itemCount = 8, super.key});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) => const _ListTileSkeleton(),
    );
  }
}

class _ListTileSkeleton extends StatelessWidget {
  const _ListTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            SkeletonBox(width: 60, height: 80, borderRadius: 8),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SkeletonBox(height: 16, borderRadius: 6),
                  SizedBox(height: 8),
                  SkeletonBox(width: 80, height: 24, borderRadius: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
