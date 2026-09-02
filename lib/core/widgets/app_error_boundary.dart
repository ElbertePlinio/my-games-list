import 'package:flutter/material.dart';
import 'package:picklog/core/theme/app_colors.dart';
import 'package:picklog/l10n/app_localizations.dart';

/// Fallback rendered by [ErrorWidget.builder] when a widget fails to build, so
/// users see a friendly message instead of a raw error screen. The build error
/// itself is still reported (see `FlutterError.onError` in `main`).
///
/// Kept self-contained — its own [Directionality], explicit colors/styles, no
/// `Theme`/`MaterialApp` dependency — so it renders even when the failure is
/// high in the widget tree. Localized text is best-effort with a safe default.
class AppErrorBoundary extends StatelessWidget {
  const AppErrorBoundary({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        color: AppColors.darkBackground,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white70, size: 48),
            const SizedBox(height: 16),
            Text(
              l10n?.errorTitle ?? 'Error',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n?.errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
