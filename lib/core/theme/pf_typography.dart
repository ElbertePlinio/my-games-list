import 'package:flutter/material.dart';
import 'package:picklog/core/theme/picklog_colors.dart';

/// Geist type scale for Picklog.
///
/// Fonts are bundled under `assets/fonts` (SIL OFL). Display and headline
/// styles track at -0.02em, body and titles at -0.01em.
abstract final class PfTypography {
  static const String sans = 'Geist';
  static const String mono = 'GeistMono';

  static TextStyle _style(
    double size,
    FontWeight weight,
    double tracking,
    double height,
    Color color,
  ) => TextStyle(
    fontFamily: sans,
    fontSize: size,
    fontWeight: weight,
    letterSpacing: size * tracking,
    height: height,
    color: color,
  );

  /// Material [TextTheme] mapped to the Pickforge scale.
  static TextTheme textTheme(PicklogColors c) {
    const display = -0.02;
    const body = -0.01;
    return TextTheme(
      displayLarge: _style(42, FontWeight.w700, display, 1.1, c.textHi),
      displayMedium: _style(34, FontWeight.w700, display, 1.12, c.textHi),
      displaySmall: _style(28, FontWeight.w700, display, 1.15, c.textHi),
      headlineLarge: _style(25, FontWeight.w600, display, 1.2, c.textHi),
      headlineMedium: _style(21, FontWeight.w600, display, 1.25, c.textHi),
      headlineSmall: _style(18, FontWeight.w600, display, 1.3, c.textHi),
      titleLarge: _style(16, FontWeight.w600, body, 1.35, c.textHi),
      titleMedium: _style(14, FontWeight.w600, body, 1.4, c.textHi),
      titleSmall: _style(13, FontWeight.w600, body, 1.4, c.textHi),
      bodyLarge: _style(15, FontWeight.w400, body, 1.5, c.textHi),
      bodyMedium: _style(13, FontWeight.w400, body, 1.5, c.textHi),
      bodySmall: _style(12, FontWeight.w400, body, 1.45, c.textMed),
      labelLarge: _style(13, FontWeight.w500, body, 1.3, c.textHi),
      labelMedium: _style(12, FontWeight.w500, body, 1.3, c.textHi),
      labelSmall: _style(11, FontWeight.w500, 0, 1.3, c.textMed),
    );
  }

  /// Mono uppercase eyebrow (10px, tracking 1.8). Uppercase the text itself.
  static TextStyle eyebrow(Color color) => TextStyle(
    fontFamily: mono,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.8,
    height: 1.4,
    color: color,
  );

  /// Mono text for numbers, ids and counters.
  static TextStyle monoStyle(
    Color color, {
    double size = 12,
    FontWeight weight = FontWeight.w500,
  }) => TextStyle(
    fontFamily: mono,
    fontSize: size,
    fontWeight: weight,
    height: 1.3,
    color: color,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}
