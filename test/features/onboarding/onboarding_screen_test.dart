import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picklog/features/onboarding/onboarding_screen.dart';
import 'package:picklog/features/onboarding/onboarding_service.dart';
import 'package:picklog/l10n/app_localizations.dart';

import '../../mocks/mock_services.dart';

void main() {
  group('OnboardingScreen', () {
    late MockLocalStorageService storage;
    late OnboardingService service;
    late int completedCount;

    setUp(() {
      storage = MockLocalStorageService();
      service = OnboardingService(storage);
      completedCount = 0;
    });

    Widget buildSubject() {
      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: OnboardingScreen(
          onboardingService: service,
          onCompleted: () => completedCount++,
        ),
      );
    }

    testWidgets('shows the first intro page with a skip and next action', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('Track every game you play'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      // First page never shows the final CTA yet.
      expect(find.text('Get started'), findsNothing);
    });

    testWidgets('advances through pages and reveals the Get started CTA', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());

      // Page 1 -> 2
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Discover what to play next'), findsOneWidget);

      // Page 2 -> 3 (last): the button label becomes the final CTA.
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Make it yours'), findsOneWidget);
      expect(find.text('Get started'), findsOneWidget);
      expect(find.text('Next'), findsNothing);
    });

    testWidgets('Get started persists the flag and reports completion', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Get started'));
      await tester.pumpAndSettle();

      expect(await service.isCompleted(), isTrue);
      expect(completedCount, 1);
    });

    testWidgets('Skip persists the flag and reports completion immediately', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(await service.isCompleted(), isTrue);
      expect(completedCount, 1);
    });
  });
}
