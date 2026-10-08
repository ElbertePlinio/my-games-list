import 'package:flutter/material.dart';

/// Content for a single onboarding intro page.
///
/// Holds the icon plus selectors for the localized eyebrow, title and
/// subtitle. Text is resolved through these selectors at build time so the
/// model stays free of any [BuildContext], keeping it a pure value object that
/// is easy to list and test.
@immutable
class OnboardingPageData {
  const OnboardingPageData({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String Function(BuildContext context) eyebrow;
  final String Function(BuildContext context) title;
  final String Function(BuildContext context) subtitle;
}
