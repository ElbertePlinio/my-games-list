import 'package:flutter/material.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/widgets/game_card.dart';
import 'package:picklog/core/widgets/skeleton_box.dart';

/// Full-screen skeleton for game details. Mirrors the real layout: the
/// pinned screenshot header (so the back button never shifts) and either the
/// phone header (cover beside the title) or the two-pane layout from 840.
class GameDetailsSkeleton extends StatelessWidget {
  const GameDetailsSkeleton({super.key});

  /// Matches `kDetailsHeaderHeight` on the details screen.
  static const double headerHeight = 280;

  @override
  Widget build(BuildContext context) {
    final twoPane = MediaQuery.sizeOf(context).width >= PfBreakpoints.twoPane;
    return Scaffold(
      body: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          const SliverAppBar(
            expandedHeight: headerHeight,
            pinned: true,
            leading: BackButton(),
            flexibleSpace: FlexibleSpaceBar(
              background: SkeletonBox(borderRadius: 0),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: PfBreakpoints.content,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    PfSpace.lg,
                    PfSpace.xl,
                    PfSpace.lg,
                    PfSpace.lg,
                  ),
                  child: twoPane ? const _TwoPane() : const _Compact(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Compact extends StatelessWidget {
  const _Compact();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 112, height: 112 / kCoverAspectRatio),
            SizedBox(width: PfSpace.lg),
            Expanded(child: _TitleLines()),
          ],
        ),
        SizedBox(height: PfSpace.xl),
        SkeletonBox(height: 56, borderRadius: PfRadius.pill),
        SizedBox(height: PfSpace.xl),
        _BodyLines(),
      ],
    );
  }
}

class _TwoPane extends StatelessWidget {
  const _TwoPane();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 320,
          child: Column(
            children: [
              AspectRatio(aspectRatio: kCoverAspectRatio, child: SkeletonBox()),
              SizedBox(height: PfSpace.xl),
              SkeletonBox(height: 56, borderRadius: PfRadius.pill),
            ],
          ),
        ),
        SizedBox(width: PfSpace.xxl),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TitleLines(),
              SizedBox(height: PfSpace.xl),
              _BodyLines(),
            ],
          ),
        ),
      ],
    );
  }
}

class _TitleLines extends StatelessWidget {
  const _TitleLines();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonBox(width: 90, height: 10, borderRadius: PfRadius.sm),
        SizedBox(height: PfSpace.md),
        // Constrain the title so it reads as a loading title rather than a
        // full-width filled banner.
        FractionallySizedBox(
          widthFactor: 0.75,
          child: SkeletonBox(height: 24, borderRadius: PfRadius.sm),
        ),
        SizedBox(height: PfSpace.lg),
        SkeletonBox(width: 120, height: 14, borderRadius: PfRadius.sm),
        SizedBox(height: PfSpace.sm),
        SkeletonBox(width: 80, height: 14, borderRadius: PfRadius.sm),
      ],
    );
  }
}

class _BodyLines extends StatelessWidget {
  const _BodyLines();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonBox(width: 220, height: 28, borderRadius: PfRadius.pill),
        SizedBox(height: PfSpace.xl),
        SkeletonBox(height: 14, borderRadius: PfRadius.sm),
        SizedBox(height: PfSpace.sm),
        SkeletonBox(height: 14, borderRadius: PfRadius.sm),
        SizedBox(height: PfSpace.sm),
        SkeletonBox(width: 200, height: 14, borderRadius: PfRadius.sm),
      ],
    );
  }
}
