import 'package:flutter/material.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/widgets/game_card.dart';
import 'package:picklog/core/widgets/staggered_reveal.dart';

/// Width of one card in a horizontal rail.
const double kRailCardWidth = 132;

/// Height of a rail of [kRailCardWidth] cards for the active text scale.
double railHeight(BuildContext context) =>
    gameCardRailHeight(kRailCardWidth, MediaQuery.textScalerOf(context));

/// Horizontal rail of game cards with staggered entry.
class GameRail extends StatelessWidget {
  const GameRail({
    required this.itemCount,
    required this.itemBuilder,
    super.key,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: railHeight(context),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: PfSpace.lg),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(width: PfSpace.md),
        itemBuilder: (context, index) => SizedBox(
          width: kRailCardWidth,
          child: StaggeredReveal(
            index: index,
            child: itemBuilder(context, index),
          ),
        ),
      ),
    );
  }
}
