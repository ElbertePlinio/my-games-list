import 'package:flutter/material.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/features/games/widgets/skeletons/discovery_grid_skeleton.dart';

/// Skeleton mirroring [GameSearchCard] (a [GameTile] with a 64px cover) so
/// search results swap in without shifting.
class SearchCardSkeleton extends StatelessWidget {
  const SearchCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const GameTileSkeleton(coverWidth: 64);
}

/// A list of [SearchCardSkeleton]s matching the search results padding.
class SearchResultsSkeleton extends StatelessWidget {
  const SearchResultsSkeleton({this.itemCount = 6, super.key});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(PfSpace.lg),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: PfSpace.sm),
      itemBuilder: (context, index) => const SearchCardSkeleton(),
    );
  }
}
