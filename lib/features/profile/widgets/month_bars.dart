import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:picklog/features/library/stats/library_stats_model.dart';

/// Twelve paired bars (added and finished per month) drawn on a canvas.
class MonthBarsChart extends StatelessWidget {
  const MonthBarsChart({
    required this.months,
    required this.addedColor,
    required this.finishedColor,
    required this.gridColor,
    required this.labelStyle,
    required this.monthLabels,
    this.height = 160,
    this.semanticLabel,
    super.key,
  });

  final List<StatsMonth> months;
  final Color addedColor;
  final Color finishedColor;
  final Color gridColor;
  final TextStyle labelStyle;

  /// One short label per month, January first.
  final List<String> monthLabels;
  final double height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      image: true,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: MonthBarsPainter(
            months: months,
            addedColor: addedColor,
            finishedColor: finishedColor,
            gridColor: gridColor,
            labelStyle: labelStyle,
            monthLabels: monthLabels,
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          ),
        ),
      ),
    );
  }
}

class MonthBarsPainter extends CustomPainter {
  MonthBarsPainter({
    required this.months,
    required this.addedColor,
    required this.finishedColor,
    required this.gridColor,
    required this.labelStyle,
    required this.monthLabels,
    required this.textDirection,
    this.textScaler = TextScaler.noScaling,
  });

  final List<StatsMonth> months;
  final Color addedColor;
  final Color finishedColor;
  final Color gridColor;
  final TextStyle labelStyle;
  final List<String> monthLabels;
  final TextDirection textDirection;
  final TextScaler textScaler;

  @override
  void paint(Canvas canvas, Size size) {
    if (months.isEmpty) return;
    final maxValue = months.fold<int>(
      1,
      (m, e) => math.max(m, math.max(e.added, e.finished)),
    );
    final labelHeight = textScaler.scale(labelStyle.fontSize ?? 10) + 6;
    final chartHeight = size.height - labelHeight;
    final slot = size.width / months.length;
    final barWidth = math.max(2.0, math.min(10.0, slot * 0.28));
    const gap = 2.0;

    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, chartHeight),
      Offset(size.width, chartHeight),
      grid,
    );
    canvas.drawLine(
      Offset(0, chartHeight / 2),
      Offset(size.width, chartHeight / 2),
      grid..color = gridColor.withValues(alpha: gridColor.a * 0.5),
    );

    final added = Paint()..color = addedColor;
    final finished = Paint()..color = finishedColor;

    for (var i = 0; i < months.length; i++) {
      final m = months[i];
      final center = slot * i + slot / 2;
      void bar(int value, double left, Paint paint) {
        if (value <= 0) return;
        final h = math.max(2.0, chartHeight * value / maxValue);
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(left, chartHeight - h, barWidth, h),
            topLeft: const Radius.circular(3),
            topRight: const Radius.circular(3),
          ),
          paint,
        );
      }

      bar(m.added, center - barWidth - gap / 2, added);
      bar(m.finished, center + gap / 2, finished);

      if (i < monthLabels.length) {
        final painter = TextPainter(
          text: TextSpan(text: monthLabels[i], style: labelStyle),
          textDirection: textDirection,
          textScaler: textScaler,
          maxLines: 1,
        )..layout(maxWidth: slot);
        painter.paint(
          canvas,
          Offset(center - painter.width / 2, chartHeight + 4),
        );
      }
    }
  }

  @override
  bool shouldRepaint(MonthBarsPainter old) =>
      old.months != months ||
      old.addedColor != addedColor ||
      old.finishedColor != finishedColor ||
      old.gridColor != gridColor ||
      old.labelStyle != labelStyle ||
      old.monthLabels != monthLabels ||
      old.textScaler != textScaler;
}
