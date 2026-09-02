import 'package:flutter/material.dart';
import 'package:picklog/core/widgets/shimmer_loading.dart';

/// A theme-aware, shimmering rounded rectangle used as the building block for
/// skeleton placeholders. Give it a size via the parent's constraints (e.g.
/// inside an [AspectRatio] or [SizedBox]) so the skeleton occupies exactly the
/// space the real content will, preventing layout jump on load.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    this.width,
    this.height,
    this.borderRadius = 12,
    super.key,
  });

  final double? width;
  final double? height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ShimmerLoading(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
