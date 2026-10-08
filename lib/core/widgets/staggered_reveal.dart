import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:picklog/core/theme/pf_tokens.dart';

/// Fades and lifts [child] in on first build, delayed by its [index].
///
/// Use it for list and grid items so they cascade in. The delay is capped so
/// long lists never wait. The delay is part of the animation itself (no
/// timers), so disposing mid-way is always safe. Under reduced motion the
/// child shows at once.
class StaggeredReveal extends StatefulWidget {
  const StaggeredReveal({
    required this.child,
    this.index = 0,
    this.step = const Duration(milliseconds: 40),
    this.maxDelay = const Duration(milliseconds: 360),
    this.offset = 12,
    super.key,
  });

  final Widget child;
  final int index;
  final Duration step;
  final Duration maxDelay;

  /// Starting vertical offset in logical pixels.
  final double offset;

  @override
  State<StaggeredReveal> createState() => _StaggeredRevealState();
}

class _StaggeredRevealState extends State<StaggeredReveal>
    with SingleTickerProviderStateMixin {
  late final int _delayMs = math.min(
    widget.step.inMilliseconds * math.max(widget.index, 0),
    widget.maxDelay.inMilliseconds,
  );
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _delayMs + PfMotion.slow.inMilliseconds),
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Interval(
      _delayMs / (_delayMs + PfMotion.slow.inMilliseconds),
      1,
      curve: PfMotion.forge,
    ),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (PfMotion.reduced(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) => Opacity(
        opacity: _curve.value,
        child: Transform.translate(
          offset: Offset(0, widget.offset * (1 - _curve.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
