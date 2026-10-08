import 'package:flutter/material.dart';
import 'package:picklog/core/theme/pf_tokens.dart';

/// Counts from zero up to [value] in 1600ms with a cubic ease-out.
/// Reduced motion shows the final value at once.
class CountUpText extends StatefulWidget {
  const CountUpText({
    required this.value,
    required this.style,
    this.format,
    this.duration = defaultDuration,
    super.key,
  });

  static const Duration defaultDuration = Duration(milliseconds: 1600);

  final int value;
  final TextStyle style;

  /// Formats the shown number. Defaults to [int.toString].
  final String Function(int value)? format;
  final Duration duration;

  @override
  State<CountUpText> createState() => _CountUpTextState();
}

class _CountUpTextState extends State<CountUpText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
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
  void didUpdateWidget(covariant CountUpText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      if (PfMotion.reduced(context)) {
        _controller.value = 1;
      } else {
        _controller.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final format = widget.format ?? (int v) => '$v';
    return Semantics(
      label: format(widget.value),
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _curve,
        builder: (context, _) => Text(
          format((widget.value * _curve.value).round()),
          style: widget.style,
        ),
      ),
    );
  }
}
