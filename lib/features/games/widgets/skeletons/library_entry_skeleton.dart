import 'package:flutter/material.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/features/games/widgets/skeletons/discovery_grid_skeleton.dart';

/// Skeleton mirroring one library row ([GameTile] with a 56px cover) so the
/// user's collection appears without a layout jump.
class LibraryEntrySkeleton extends StatelessWidget {
  const LibraryEntrySkeleton({super.key});

  @override
  Widget build(BuildContext context) => const GameTileSkeleton();
}

/// A list of [LibraryEntrySkeleton]s matching the library list padding.
class LibraryListSkeleton extends StatelessWidget {
  const LibraryListSkeleton({this.itemCount = 8, super.key});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        PfSpace.lg,
        PfSpace.sm,
        PfSpace.lg,
        PfSpace.lg,
      ),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: PfSpace.sm),
      itemBuilder: (context, index) => const LibraryEntrySkeleton(),
    );
  }
}
