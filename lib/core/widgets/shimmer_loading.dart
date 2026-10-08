import 'package:flutter/material.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/picklog_colors.dart';

/// Animates a soft light sweep across [child] to indicate loading. Wrap a
/// solid placeholder shape (a "skeleton") to give it a shimmer.
///
/// Colours come from the surface tokens. Under reduced motion the sweep stops
/// and the skeleton stays static.
class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({super.key, required this.child});

  final Widget child;

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (PfMotion.reduced(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pfColors;
    final base = colors.surface2;
    final highlight = colors.surface3;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final dx = (_controller.value * 2 - 1) * bounds.width;
            return LinearGradient(
              colors: [base, highlight, base],
              stops: const [0.3, 0.5, 0.7],
            ).createShader(Rect.fromLTWH(dx, 0, bounds.width, bounds.height));
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
