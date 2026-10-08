import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/picklog_colors.dart';

/// Pickforge glass card: blurred translucent surface with a hairline border.
///
/// Use it on top of imagery or atmosphere. [strong] adds more opacity and
/// blur for overlays that need extra lift.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    required this.child,
    this.strong = false,
    this.borderRadius = PfRadius.cardAll,
    this.padding,
    super.key,
  });

  final Widget child;
  final bool strong;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.pfColors;
    final sigma = strong ? 20.0 : 12.0;
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface1.withValues(alpha: strong ? 0.85 : 0.7),
            borderRadius: borderRadius,
            border: Border.all(
              color: strong ? colors.hairlineStrong : colors.hairline,
            ),
          ),
          child: padding == null
              ? child
              : Padding(padding: padding!, child: child),
        ),
      ),
    );
  }
}
