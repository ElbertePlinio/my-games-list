import 'package:flutter/material.dart';
import 'package:picklog/core/theme/pf_tokens.dart';

/// Column counts by available width: 2 / 3 / 4 / 6.
abstract final class ResponsiveGrid {
  static int columnsFor(double width) {
    if (width >= PfBreakpoints.expanded) return 6;
    if (width >= 900) return 4;
    if (width >= PfBreakpoints.compact) return 3;
    return 2;
  }

  /// Grid delegate for cover cards (portrait 3:4 covers plus a title line).
  static SliverGridDelegate coverDelegate(
    double width, {
    double childAspectRatio = 0.68,
    double spacing = PfSpace.md,
  }) => SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: columnsFor(width),
    childAspectRatio: childAspectRatio,
    crossAxisSpacing: spacing,
    mainAxisSpacing: spacing,
  );
}

/// Sliver grid that picks its column count from the sliver's own width.
class SliverResponsiveGrid extends StatelessWidget {
  const SliverResponsiveGrid({
    required this.itemCount,
    required this.itemBuilder,
    this.childAspectRatio = 0.68,
    this.spacing = PfSpace.md,
    super.key,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double childAspectRatio;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) => SliverGrid(
        gridDelegate: ResponsiveGrid.coverDelegate(
          constraints.crossAxisExtent,
          childAspectRatio: childAspectRatio,
          spacing: spacing,
        ),
        delegate: SliverChildBuilderDelegate(
          itemBuilder,
          childCount: itemCount,
        ),
      ),
    );
  }
}
