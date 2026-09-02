import 'package:flutter/material.dart';
import 'package:picklog/core/widgets/skeleton_box.dart';

/// Full-screen skeleton for the game details screen. Mirrors the real layout's
/// pinned 300px [SliverAppBar] header (so the back affordance stays visible and
/// no app-bar chrome shifts in when the game loads) and the info row
/// (100x140 cover + title/meta lines).
class GameDetailsSkeleton extends StatelessWidget {
  const GameDetailsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: CustomScrollView(
        physics: NeverScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            leading: BackButton(),
            flexibleSpace: FlexibleSpaceBar(
              background: SkeletonBox(borderRadius: 0),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRowSkeleton(),
                  SizedBox(height: 24),
                  // Tags / chips row.
                  SkeletonBox(width: 220, height: 28, borderRadius: 14),
                  SizedBox(height: 24),
                  // Description block.
                  SkeletonBox(height: 14, borderRadius: 6),
                  SizedBox(height: 8),
                  SkeletonBox(height: 14, borderRadius: 6),
                  SizedBox(height: 8),
                  SkeletonBox(width: 200, height: 14, borderRadius: 6),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRowSkeleton extends StatelessWidget {
  const _InfoRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonBox(width: 100, height: 140, borderRadius: 8),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Constrain the title so it reads as a loading title rather than
              // a full-width filled banner.
              FractionallySizedBox(
                widthFactor: 0.7,
                child: SkeletonBox(height: 22, borderRadius: 6),
              ),
              SizedBox(height: 12),
              SkeletonBox(width: 120, height: 14, borderRadius: 6),
              SizedBox(height: 12),
              SkeletonBox(width: 80, height: 14, borderRadius: 6),
            ],
          ),
        ),
      ],
    );
  }
}
