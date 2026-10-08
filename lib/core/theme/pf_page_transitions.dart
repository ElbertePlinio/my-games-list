import 'package:flutter/material.dart';
import 'package:picklog/core/theme/pf_tokens.dart';

/// Fade-through route transition with a short shared-axis rise.
///
/// The incoming page fades in and rises 16px on [PfMotion.forge]. The page
/// underneath fades out behind it, so old chrome never shows through.
/// Under reduced motion the page switches without animation.
class PfPageTransitionsBuilder extends PageTransitionsBuilder {
  const PfPageTransitionsBuilder();

  static const double _rise = 16;

  @override
  Duration get transitionDuration => PfMotion.slow;

  @override
  Duration get reverseTransitionDuration => PfMotion.standard;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (PfMotion.reduced(context)) {
      return _InstantTransition(animation: animation, child: child);
    }

    final enter = CurvedAnimation(
      parent: animation,
      curve: PfMotion.forge,
      reverseCurve: PfMotion.out.flipped,
    );
    final exit = CurvedAnimation(
      parent: secondaryAnimation,
      // Starts late so the incoming page is nearly opaque first; nothing
      // dark ever shows through between the two pages.
      curve: const Interval(0.25, 1, curve: PfMotion.out),
    );

    return FadeTransition(
      opacity: ReverseAnimation(exit).drive(Tween(begin: 0.0, end: 1.0)),
      child: FadeTransition(
        opacity: enter,
        child: AnimatedBuilder(
          animation: enter,
          builder: (context, child) => Transform.translate(
            offset: Offset(0, _rise * (1 - enter.value)),
            child: child,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Shows the page fully while it enters or rests, hides it once popping.
class _InstantTransition extends StatelessWidget {
  const _InstantTransition({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final leaving =
            animation.status == AnimationStatus.reverse ||
            animation.status == AnimationStatus.dismissed;
        return Opacity(opacity: leaving ? 0 : 1, child: child);
      },
      child: child,
    );
  }
}
