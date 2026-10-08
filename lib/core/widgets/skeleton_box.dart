import 'package:flutter/material.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/widgets/shimmer_loading.dart';

/// A shimmering rounded rectangle in the surface tokens, used to build
/// skeleton placeholders. Size it through the parent's constraints (for
/// example an [AspectRatio] or [SizedBox]) so the skeleton occupies exactly the
/// space of the real content and nothing jumps on load.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    this.width,
    this.height,
    this.borderRadius = PfRadius.md,
    super.key,
  });

  final double? width;
  final double? height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: context.pfColors.surface2,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
