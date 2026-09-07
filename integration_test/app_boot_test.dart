// End-to-end boot integration test.
//
// Runs the real `MyGamesListApp` through the live service locator and GoRouter,
// exercising the splash -> auth-redirect path that unit widget tests stub out.
// Runnable on a device or browser via:
//   flutter test integration_test -d chrome   (headless web smoke)
//   flutter test integration_test -d <device>
// It is NOT part of the `flutter test` (test/) run that CI's "Analyze & Test"
// job executes, because integration_test needs a device/browser the current CI
// does not provision (see README in test/web/web_smoke_test.dart for the gap).
//
// Auth is driven entirely through persisted state (the same `current_user`
// SharedPreferences record the real sign-in flow writes), so the happy path is
// covered without a live backend or network. Once a test backend / session
// injection harness exists, the post-home library-add step can be appended
// here.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:picklog/core/utils/service_locator.dart';
import 'package:picklog/features/home/home_screen.dart';
import 'package:picklog/features/splash/splash_screen.dart';
import 'package:picklog/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visibility_detector/visibility_detector.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // The home dashboard lazy-loads rows via VisibilityDetector; collapse its
    // polling interval so the tree quiesces promptly under test.
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  tearDown(() async {
    await sl.reset();
  });

  Future<void> boot(WidgetTester tester, Map<String, Object> prefs) async {
    await sl.reset();
    SharedPreferences.setMockInitialValues(prefs);
    await setupServiceLocator();

    await tester.pumpWidget(const MyGamesListApp());
    // First frame: splash is on screen before the auth check resolves.
    await tester.pump();
    expect(find.byType(SplashScreen), findsOneWidget);
  }

  testWidgets('signed-out user boots splash -> sign-in', (tester) async {
    await boot(tester, {'onboarding_completed': true});

    // Sign-in is an idle screen, so it fully settles.
    await tester.pumpAndSettle();

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(TextFormField), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('authenticated user boots splash -> home', (tester) async {
    final user = jsonEncode({
      'id': 'u-1',
      'email': 'tester@example.com',
      'name': 'Tester',
      'username': 'tester',
    });

    await boot(tester, {
      'onboarding_completed': true,
      'is_logged_in': true,
      'current_user': user,
    });

    // The home dashboard hosts perpetually-animating widgets (auto-play
    // carousels), so pumpAndSettle would never return. Advance past the splash
    // min-display window and redirect with bounded pumps instead.
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump();
    await tester.pump();

    // Reached the authenticated shell: left splash, landed on home, and the
    // sign-in form is gone. Discovery carousels may surface empty/error states
    // because there is no backend, which is expected here.
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });
}
