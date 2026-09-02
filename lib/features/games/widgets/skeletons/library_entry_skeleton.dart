import 'package:flutter/material.dart';
import 'package:picklog/core/widgets/skeleton_box.dart';

/// Skeleton mirroring the library `_LibraryEntryCard` (Card 4px vertical
/// margin, 12px padding, 60x80 cover + name + status chip + meta line) so the
/// user's collection appears without a layout jump.
class LibraryEntrySkeleton extends StatelessWidget {
  const LibraryEntrySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 60, height: 80, borderRadius: 8),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(height: 16, borderRadius: 6),
                  SizedBox(height: 8),
                  SkeletonBox(width: 90, height: 18, borderRadius: 12),
                  SizedBox(height: 8),
                  SkeletonBox(width: 130, height: 12, borderRadius: 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A list of [LibraryEntrySkeleton]s matching the library list padding.
class LibraryListSkeleton extends StatelessWidget {
  const LibraryListSkeleton({this.itemCount = 8, super.key});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) => const LibraryEntrySkeleton(),
    );
  }
}
