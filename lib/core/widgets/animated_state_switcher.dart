import 'package:flutter/material.dart';
import 'package:picklog/core/theme/pf_tokens.dart';

/// Cross-fades between loading, content and error views.
///
/// Give each state a distinct [stateKey] (for example the status enum). The
/// new view fades in on the forge curve. Under reduced motion it swaps
/// instantly.
class AnimatedStateSwitcher extends StatelessWidget {
  const AnimatedStateSwitcher({
    required this.stateKey,
    required this.child,
    this.duration = PfMotion.standard,
    this.alignment = Alignment.topCenter,
    super.key,
  });

  final Object stateKey;
  final Widget child;
  final Duration duration;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: PfMotion.of(context, duration),
      switchInCurve: PfMotion.forge,
      switchOutCurve: PfMotion.out,
      layoutBuilder: (current, previous) =>
          Stack(alignment: alignment, children: [...previous, ?current]),
      child: KeyedSubtree(key: ValueKey(stateKey), child: child),
    );
  }
}
