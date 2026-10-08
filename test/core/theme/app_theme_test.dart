import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picklog/core/theme/app_theme.dart';
import 'package:picklog/core/theme/pf_page_transitions.dart';
import 'package:picklog/core/theme/pf_typography.dart';
import 'package:picklog/core/theme/picklog_colors.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// Composites a translucent [top] over an opaque [bottom].
Color _over(Color top, Color bottom) => Color.alphaBlend(top, bottom);

void main() {
  group('AppTheme', () {
    test('dark theme maps the canonical Pickforge tokens', () {
      final theme = AppTheme.dark();
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, const Color(0xFF0A0A0B));
      expect(theme.colorScheme.primary, const Color(0xFFFF7A1A));
      expect(theme.colorScheme.onSurface, const Color(0xFFF2F2F3));
      expect(theme.cardTheme.color, const Color(0xFF0F0F11));
      expect(theme.extension<PicklogColors>(), PicklogColors.dark);
    });

    test('light theme uses the cream scaffold, never pure white', () {
      final theme = AppTheme.light();
      expect(theme.brightness, Brightness.light);
      expect(theme.scaffoldBackgroundColor, const Color(0xFFFAFAF7));
      expect(theme.scaffoldBackgroundColor, isNot(const Color(0xFFFFFFFF)));
      expect(theme.colorScheme.primary, const Color(0xFFE5610A));
      expect(theme.extension<PicklogColors>(), PicklogColors.light);
    });

    test('the color scheme is built from tokens, not a Material seed', () {
      final seeded = ColorScheme.fromSeed(
        seedColor: const Color(0xFFFF7A1A),
        brightness: Brightness.dark,
      );
      final scheme = AppTheme.dark().colorScheme;
      expect(scheme.surface, isNot(seeded.surface));
      expect(scheme.surface, PicklogColors.dark.surface);
    });

    test('text uses Geist with the Pickforge scale', () {
      final text = AppTheme.dark().textTheme;
      expect(text.bodyLarge!.fontFamily, PfTypography.sans);
      expect(text.displayLarge!.fontSize, 42);
      expect(text.headlineLarge!.fontSize, 25);
      expect(text.titleLarge!.fontSize, 16);
      expect(text.bodyMedium!.fontSize, 13);
      expect(text.labelSmall!.fontSize, 11);
      // Display tracking is -0.02em.
      expect(text.displayLarge!.letterSpacing, closeTo(-0.84, 0.001));
      final eyebrow = PfTypography.eyebrow(Colors.black);
      expect(eyebrow.fontFamily, PfTypography.mono);
      expect(eyebrow.fontSize, 10);
      expect(eyebrow.letterSpacing, 1.8);
    });

    test('buttons are pills and pages use the forge transition', () {
      final theme = AppTheme.dark();
      final filledShape = theme.filledButtonTheme.style!.shape!.resolve({});
      expect(filledShape, isA<StadiumBorder>());
      expect(
        theme.pageTransitionsTheme.builders[TargetPlatform.android],
        isA<PfPageTransitionsBuilder>(),
      );
    });
  });

  group('token contrast (WCAG AA 4.5:1)', () {
    for (final palette in [PicklogColors.dark, PicklogColors.light]) {
      final name = palette.isDark ? 'dark' : 'light';
      final surfaces = {
        'surface': palette.surface,
        'surface-1': palette.surface1,
        'surface-2': palette.surface2,
      };

      for (final entry in surfaces.entries) {
        test('$name text-hi and text-med on ${entry.key}', () {
          expect(
            _contrast(palette.textHi, entry.value),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            _contrast(palette.textMed, entry.value),
            greaterThanOrEqualTo(4.5),
          );
        });
      }

      test('$name ember button text', () {
        expect(
          _contrast(palette.onEmber, palette.ember),
          greaterThanOrEqualTo(4.5),
        );
        // Hovered/pressed buttons switch to ember-soft.
        expect(
          _contrast(palette.onEmber, palette.emberSoft),
          greaterThanOrEqualTo(4.5),
        );
      });

      test('$name status pill text on its tinted background', () {
        for (final tone in PfTone.values) {
          final background = _over(
            palette.toneBackground(tone),
            palette.surface1,
          );
          expect(
            _contrast(palette.toneForeground(tone), background),
            greaterThanOrEqualTo(4.5),
            reason: '$tone',
          );
        }
      });
    }
  });
}
