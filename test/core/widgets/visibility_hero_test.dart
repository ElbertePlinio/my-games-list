import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picklog/core/widgets/visibility_hero.dart';

HeroMode _heroModeFor(WidgetTester tester, Key childKey) {
  return tester.widget<HeroMode>(
    find.ancestor(
      // skipOffstage:false so a scrolled-out (offstage but built) row is found.
      of: find.byKey(childKey, skipOffstage: false),
      matching: find.byType(HeroMode, skipOffstage: false),
    ),
  );
}

void main() {
  group('VisibilityHero', () {
    testWidgets('keeps the hero enabled while the item is on screen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(600, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const childKey = Key('hero-child');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VisibilityHero(
              tag: 'tag',
              child: SizedBox(key: childKey, width: 50, height: 50),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(_heroModeFor(tester, childKey).enabled, isTrue);
    });

    testWidgets('disables the hero when scrolled off screen and re-enables it '
        'when scrolled back into view', (tester) async {
      tester.view.physicalSize = const Size(600, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const childKey = Key('hero-child');
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              controller: controller,
              // Keep the off-screen hero in the tree so HeroMode.enabled can be
              // asserted (without this, ListView recycles the scrolled-out row).
              cacheExtent: 5000,
              children: const [
                VisibilityHero(
                  tag: 'tag',
                  child: SizedBox(key: childKey, width: 50, height: 50),
                ),
                // Tall filler so the hero can be scrolled fully out of view.
                SizedBox(height: 4000),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_heroModeFor(tester, childKey).enabled, isTrue);

      controller.jumpTo(2000);
      await tester.pumpAndSettle();
      expect(_heroModeFor(tester, childKey).enabled, isFalse);

      controller.jumpTo(0);
      await tester.pumpAndSettle();
      expect(_heroModeFor(tester, childKey).enabled, isTrue);
    });

    testWidgets('re-evaluates visibility on a viewport resize without scroll', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(600, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const childKey = Key('hero-child');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              physics: NeverScrollableScrollPhysics(),
              child: Column(
                children: [
                  SizedBox(height: 1200),
                  VisibilityHero(
                    tag: 'tag',
                    child: SizedBox(key: childKey, width: 50, height: 50),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // The item sits at y=1200, inside the 2000-tall viewport.
      expect(_heroModeFor(tester, childKey).enabled, isTrue);

      // Shrink the viewport so the item falls below the fold. No scroll occurs;
      // only didChangeMetrics drives the re-check.
      tester.view.physicalSize = const Size(600, 800);
      await tester.pumpAndSettle();
      expect(_heroModeFor(tester, childKey).enabled, isFalse);
    });
  });
}
