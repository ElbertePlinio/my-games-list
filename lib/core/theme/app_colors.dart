import 'package:flutter/material.dart';

/// Brand palette for Picklog.
///
/// The brand leans on an electric indigo/violet accent over deep charcoal
/// surfaces — a confident, modern look for a game-library tracker rather than
/// the default Material blue. The dark surface mirrors the web manifest's
/// `#12141C` so the splash, web shell and in-app dark theme stay consistent.
abstract final class AppColors {
  const AppColors._();

  /// Primary brand seed. Drives the Material 3 [ColorScheme] for both themes.
  ///
  /// As a FOREGROUND the raw seed is large-text-only on dark surfaces — it is
  /// sub-AA (~3.5:1 on [darkBackground]/[darkSurface]) for small text/icons,
  /// passing only for large/bold text. Prefer `colorScheme.primary` (the
  /// brightness-aware tone, lightened on dark) or `colorScheme.onSurface` for
  /// small foreground text/icons; reserve the raw seed for fills/gradients.
  static const Color brandSeed = Color(0xFF7C4DFF);

  /// Secondary accent used for highlights (ratings, "anticipated" badges).
  ///
  /// This bright teal is a FILL / dark-mode color — it passes contrast as a
  /// background behind dark text and as a foreground on dark surfaces, and it
  /// anchors the [brandSeed]→teal gradient in the brand logo. It is NOT a valid
  /// light-mode foreground (~1.5:1 on [lightBackground]); use [brandAccentDark]
  /// for the light theme's `secondary` role.
  static const Color brandAccent = Color(0xFF00E5C7);

  /// Darkened teal for the light theme's `secondary` role, where the accent is
  /// used as foreground text/icons. Clears AA (4.5:1) on [lightBackground].
  static const Color brandAccentDark = Color(0xFF00796B);

  /// Deep charcoal background for the dark theme and native splash. Matches
  /// `web/manifest.json` background/theme color.
  static const Color darkBackground = Color(0xFF12141C);

  /// Slightly raised surface for cards/sheets in the dark theme.
  static const Color darkSurface = Color(0xFF1B1E2A);

  /// Warm off-white background for the light theme — softer than pure white.
  static const Color lightBackground = Color(0xFFF7F6FB);
}
