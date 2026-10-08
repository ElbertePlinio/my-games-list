import 'package:flutter/material.dart';
import 'package:picklog/core/theme/pf_typography.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';

/// Colour variants of the Picklog mark.
enum BrandMarkVariant {
  /// Dark frame, off-white brackets, ember dot. Canonical.
  dark,

  /// Cream frame, ink brackets, deeper ember dot.
  light,

  /// Dark frame with an off-white dot (single colour contexts).
  mono,
}

/// The Picklog mark, drawn to match `assets/branding/picklog-mark.svg`.
///
/// Pickforge family: a 128 frame with radius 24, three L brackets, the
/// top-right corner replaced by one ember dot, faint dashed connectors. A
/// small log glyph (two lines and a check) sits in the centre.
///
/// With no [variant] it follows the theme brightness.
class BrandMark extends StatelessWidget {
  const BrandMark({
    this.size = 48,
    this.variant,
    this.semanticLabel,
    super.key,
  });

  final double size;
  final BrandMarkVariant? variant;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final resolved =
        variant ??
        (Theme.of(context).brightness == Brightness.light
            ? BrandMarkVariant.light
            : BrandMarkVariant.dark);
    final mark = SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: BrandMarkPainter(resolved)),
    );
    if (semanticLabel == null) return ExcludeSemantics(child: mark);
    return Semantics(image: true, label: semanticLabel, child: mark);
  }
}

/// Paints the mark in a 128x128 design space scaled to the canvas.
class BrandMarkPainter extends CustomPainter {
  const BrandMarkPainter(this.variant);

  final BrandMarkVariant variant;

  @override
  void paint(Canvas canvas, Size size) {
    final light = variant == BrandMarkVariant.light;
    final frame = light ? const Color(0xFFFAFAF7) : const Color(0xFF0A0A0B);
    final ink = light ? const Color(0xFF17171A) : const Color(0xFFF2F2F3);
    final dot = switch (variant) {
      BrandMarkVariant.dark => const Color(0xFFFF7A1A),
      BrandMarkVariant.light => const Color(0xFFE5610A),
      BrandMarkVariant.mono => const Color(0xFFF2F2F3),
    };

    canvas.save();
    canvas.scale(size.width / 128, size.height / 128);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 128, 128),
        const Radius.circular(24),
      ),
      Paint()..color = frame,
    );
    // Hairline edge so the frame still reads on a matching surface.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0.5, 0.5, 127, 127),
        const Radius.circular(23.5),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = light ? const Color(0x1A000000) : const Color(0x24FFFFFF),
    );

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter
      ..color = ink;

    // Brackets: top-left, bottom-left, bottom-right.
    canvas.drawPath(
      Path()
        ..moveTo(30, 48)
        ..lineTo(30, 32)
        ..lineTo(46, 32),
      stroke,
    );
    canvas.drawPath(
      Path()
        ..moveTo(30, 80)
        ..lineTo(30, 96)
        ..lineTo(46, 96),
      stroke,
    );
    canvas.drawPath(
      Path()
        ..moveTo(82, 96)
        ..lineTo(98, 96)
        ..lineTo(98, 80),
      stroke,
    );

    // The ember dot replaces the top-right bracket.
    canvas.drawCircle(const Offset(90, 40), 7, Paint()..color = dot);

    // Faint dashed connectors.
    final dash = Paint()
      ..strokeWidth = 1
      ..color = ink.withValues(alpha: light ? 0.12 : 0.35);
    void dashed(Offset a, Offset b) {
      final total = (b - a).distance;
      final dir = (b - a) / total;
      for (double t = 0; t < total; t += 5) {
        final end = (t + 2).clamp(0, total).toDouble();
        canvas.drawLine(a + dir * t, a + dir * end, dash);
      }
    }

    dashed(const Offset(30, 48), const Offset(30, 80));
    dashed(const Offset(46, 32), const Offset(82, 32));
    dashed(const Offset(46, 96), const Offset(82, 96));
    dashed(const Offset(98, 48), const Offset(98, 80));

    // Log glyph: two entry lines and a check.
    canvas.drawLine(const Offset(47, 51), const Offset(79, 51), stroke);
    canvas.drawLine(const Offset(47, 61), const Offset(71, 61), stroke);
    canvas.drawPath(
      Path()
        ..moveTo(48, 73)
        ..lineTo(55, 80)
        ..lineTo(69, 66),
      stroke,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(BrandMarkPainter oldDelegate) =>
      oldDelegate.variant != variant;
}

/// Mark plus the "Picklog" word in Geist Bold.
class Wordmark extends StatelessWidget {
  const Wordmark({this.markSize = 28, this.fontSize, this.variant, super.key});

  final double markSize;
  final double? fontSize;
  final BrandMarkVariant? variant;

  @override
  Widget build(BuildContext context) {
    final colors = context.pfColors;
    final size = fontSize ?? markSize * 0.68;
    final textColor = variant == BrandMarkVariant.light
        ? PicklogColors.light.textHi
        : (variant == null ? colors.textHi : PicklogColors.dark.textHi);
    return Semantics(
      label: context.l10n.appTitle,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BrandMark(size: markSize, variant: variant),
          SizedBox(width: markSize * 0.36),
          Text(
            context.l10n.appTitle,
            style: TextStyle(
              fontFamily: PfTypography.sans,
              fontWeight: FontWeight.w700,
              fontSize: size,
              letterSpacing: size * -0.02,
              height: 1,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
