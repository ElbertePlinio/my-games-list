// Web smoke coverage.
//
// A true headless web smoke test would drive the release web build with
// chromedriver via `flutter drive --target=integration_test/...`. That harness
// is not wired into CI here (the Build Web job only compiles; there is no
// chromedriver service in the workflow), and adding it would require a browser
// runner the current CI does not provision. Until that lands, this test gives
// the closest practical coverage: it boots the full app widget tree the way
// `main()` does and asserts the core shell renders without throwing. The
// release web build itself is still verified by the dedicated Build Web CI job
// (`flutter build web --release`).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picklog/core/utils/service_locator.dart';
import 'package:picklog/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('web smoke', () {
    setUp(() async {
      await sl.reset();
      // Returning user: skip first-run onboarding so boot lands on the auth
      // flow, mirroring the steady-state web entry point.
      SharedPreferences.setMockInitialValues({'onboarding_completed': true});
      await setupServiceLocator();
    });

    tearDown(() async {
      await sl.reset();
    });

    testWidgets('app boots and renders the core shell without throwing', (
      tester,
    ) async {
      await tester.pumpWidget(const MyGamesListApp());
      await tester.pumpAndSettle();

      // No build/layout/navigation exception escaped during boot.
      expect(tester.takeException(), isNull);

      // Core shells are present: a routed MaterialApp with an active GoRouter
      // and a rendered Scaffold (the app reached a real screen, not a blank
      // frame).
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Router<Object>), findsWidgets);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('boot settles on the sign-in screen for a signed-out user', (
      tester,
    ) async {
      await tester.pumpWidget(const MyGamesListApp());
      await tester.pumpAndSettle();

      // Unauthenticated boot redirects splash -> sign-in, which exposes the
      // credential form fields.
      expect(find.byType(TextFormField), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
