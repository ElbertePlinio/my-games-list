import 'package:flutter/material.dart';
import 'package:picklog/core/widgets/skeleton_box.dart';

/// Skeleton mirroring [GameSearchCard] (Card 8/6 margin, 16px radius, 12px
/// padding, 90x120 cover + stacked info lines) so search results swap in
/// without shifting.
class SearchCardSkeleton extends StatelessWidget {
  const SearchCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 90, height: 120),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(height: 24, borderRadius: 6),
                  SizedBox(height: 12),
                  SkeletonBox(width: 140, height: 14, borderRadius: 6),
                  SizedBox(height: 8),
                  SkeletonBox(width: 110, height: 14, borderRadius: 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A list of [SearchCardSkeleton]s matching the search results list padding.
class SearchResultsSkeleton extends StatelessWidget {
  const SearchResultsSkeleton({this.itemCount = 6, super.key});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) => const SearchCardSkeleton(),
    );
  }
}
