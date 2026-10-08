import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/pf_typography.dart';
import 'package:picklog/core/theme/picklog_colors.dart';

/// Tone for a 0-100 score: 75+ connected, 50-74 warning, below 50 error.
PfTone scoreTone(int score) {
  if (score >= 75) return PfTone.connected;
  if (score >= 50) return PfTone.warning;
  return PfTone.error;
}

/// Rounds any rating to the app-wide integer 0-100 format.
int? normalizeScore(num? value) => value?.round().clamp(0, 100).toInt();

/// The one score format used app-wide: an integer 0-100 in a small pill.
///
/// Use it for IGDB ratings and user scores alike. A null score renders
/// nothing. Set [onImage] when the badge sits on a cover or screenshot so it
/// gets a dark glass background in both themes.
class ScoreBadge extends StatelessWidget {
  const ScoreBadge({
    required this.score,
    this.onImage = false,
    this.large = false,
    this.semanticLabel,
    super.key,
  });

  /// Score 0-100, or null to hide the badge.
  final int? score;
  final bool onImage;
  final bool large;

  /// Spoken label, for example "Rating 87". Defaults to the number.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final value = score;
    if (value == null) return const SizedBox.shrink();

    final colors = onImage ? PicklogColors.dark : context.pfColors;
    final tone = scoreTone(value);
    final foreground = colors.toneForeground(tone);
    final background = onImage
        ? PicklogColors.imageScrim.withValues(alpha: 0.78)
        : colors.toneBackground(tone);

    return Semantics(
      label: semanticLabel ?? '$value',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: large ? 10 : 7,
          vertical: large ? 4 : 2,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: PfRadius.pillAll,
          border: Border.all(
            color: colors.toneFill(tone).withValues(alpha: 0.35),
          ),
        ),
        child: Text(
          '$value',
          style: PfTypography.monoStyle(
            foreground,
            size: large ? 14 : 11,
            weight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Circular score ring with the number in the middle.
///
/// Same tones as [ScoreBadge]. Used where the score is a headline, such as
/// game details and the add-to-library preview.
class ScoreRing extends StatelessWidget {
  const ScoreRing({
    required this.score,
    this.size = 56,
    this.semanticLabel,
    super.key,
  });

  final int? score;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.pfColors;
    final value = score;
    final tone = value == null ? PfTone.neutral : scoreTone(value);
    final stroke = math.max(3.0, size / 14);

    return Semantics(
      label: semanticLabel ?? (value == null ? '-' : '$value'),
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _RingPainter(
            progress: (value ?? 0) / 100,
            track: colors.surface3,
            fill: colors.toneFill(tone),
            stroke: stroke,
          ),
          child: Padding(
            padding: EdgeInsets.all(stroke * 2),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value == null ? '-' : '$value',
                  style: PfTypography.monoStyle(
                    value == null ? colors.textLow : colors.textHi,
                    size: size * 0.3,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.track,
    required this.fill,
    required this.stroke,
  });

  final double progress;
  final Color track;
  final Color fill;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawArc(arcRect, 0, math.pi * 2, false, base);
    if (progress <= 0) return;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = fill;
    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0, 1),
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.track != track ||
      old.fill != fill ||
      old.stroke != stroke;
}
