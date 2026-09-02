import 'package:flutter/material.dart';
import 'package:picklog/core/theme/app_colors.dart';

/// The Picklog brand mark: a game-controller glyph inside a rounded
/// gradient badge. Reused on the splash and auth screens so the brand reads
/// consistently. Theme-aware via the brand seed colors.
///
/// NOTE: This is the placeholder brand mark and matches the placeholder
/// launcher/splash artwork under `assets/branding/`. Replace both with final
/// brand art before release (see `assets/branding/README.md`).
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 96});

  /// Outer badge dimension in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brandSeed, AppColors.brandAccent],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandSeed.withValues(alpha: 0.35),
            blurRadius: size * 0.25,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: Icon(Icons.games, size: size * 0.56, color: Colors.white),
    );
  }
}
