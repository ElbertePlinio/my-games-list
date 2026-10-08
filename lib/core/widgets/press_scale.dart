import 'package:flutter/material.dart';
import 'package:picklog/core/theme/pf_tokens.dart';

/// Scales [child] down slightly while pressed and runs [onTap].
///
/// Gives cards a tactile press without a heavy ripple. Under reduced motion
/// the scale is skipped. Keyboard and screen-reader users get a normal
/// button through [Semantics] and [FocusableActionDetector].
class PressScale extends StatefulWidget {
  const PressScale({
    required this.child,
    required this.onTap,
    this.semanticLabel,
    this.scale = 0.97,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final double scale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;
  bool _hovered = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final reduced = PfMotion.reduced(context);
    final target = !reduced && _pressed
        ? widget.scale
        : (!reduced && _hovered ? 1.015 : 1.0);

    return Semantics(
      button: enabled,
      label: widget.semanticLabel,
      onTap: widget.onTap,
      child: FocusableActionDetector(
        enabled: enabled,
        mouseCursor: enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowHoverHighlight: (value) => setState(() => _hovered = value),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          onTapDown: enabled ? (_) => _setPressed(true) : null,
          onTapUp: enabled ? (_) => _setPressed(false) : null,
          onTapCancel: enabled ? () => _setPressed(false) : null,
          child: AnimatedScale(
            scale: target,
            duration: PfMotion.of(context, PfMotion.fast),
            curve: PfMotion.forge,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
