import 'package:flutter/material.dart';
import 'package:picklog/core/widgets/google_logo.dart';

/// A Google-branding-compliant sign-in button: the four-color "G" mark, a
/// neutral surface (white in light mode, Google's dark `#131314` in dark mode)
/// and a left-aligned label. The label text is passed in so it stays
/// localized via `context.l10n`.
///
/// Follows Google's "Sign in with Google" button guidelines (logo, contrast,
/// rounded shape) while staying composable and theme-aware.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  // Google-specified neutral surfaces and foregrounds.
  static const _lightSurface = Colors.white;
  static const _darkSurface = Color(0xFF131314);
  static const _lightForeground = Color(0xFF1F1F1F);
  static const _darkForeground = Color(0xFFE3E3E3);
  static const _lightBorder = Color(0xFFDADCE0);
  static const _darkBorder = Color(0xFF8E918F);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? _darkSurface : _lightSurface;
    final foreground = isDark ? _darkForeground : _lightForeground;
    final border = isDark ? _darkBorder : _lightBorder;

    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const GoogleLogo(size: 20),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: surface,
          foregroundColor: foreground,
          disabledBackgroundColor: surface.withValues(alpha: 0.6),
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
