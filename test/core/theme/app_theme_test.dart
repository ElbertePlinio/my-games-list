import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picklog/core/theme/app_colors.dart';
import 'package:picklog/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('light theme uses Material 3 with the light brand scheme', () {
      final theme = AppTheme.light();

      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.secondary, AppColors.brandAccentDark);
      expect(theme.scaffoldBackgroundColor, AppColors.lightBackground);
    });

    test('dark theme uses the deep charcoal brand surfaces', () {
      final theme = AppTheme.dark();

      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.secondary, AppColors.brandAccent);
      expect(theme.scaffoldBackgroundColor, AppColors.darkBackground);
      expect(theme.colorScheme.surface, AppColors.darkSurface);
    });

    test('is not the default Material blue', () {
      final blue = ColorScheme.fromSeed(seedColor: Colors.blue).primary;
      expect(AppTheme.light().colorScheme.primary, isNot(blue));
    });
  });
}
