import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picklog/core/theme/app_theme.dart';
import 'package:picklog/l10n/app_localizations.dart';

/// Pumps [child] inside the real Picklog theme and localizations.
Future<void> pumpPicklog(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.dark,
  Locale locale = const Locale('en'),
  bool reducedMotion = false,
  bool wrapInScaffold = true,
}) async {
  if (reducedMotion) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: wrapInScaffold ? Scaffold(body: child) : child,
    ),
  );
}
