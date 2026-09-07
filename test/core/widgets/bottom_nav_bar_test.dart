import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:picklog/core/widgets/bottom_nav_bar.dart';
import 'package:picklog/l10n/app_localizations.dart';

void main() {
  group('BottomNavBar', () {
    late GoRouter router;
    late GlobalKey<NavigatorState> rootNavigatorKey;

    setUp(() {
      rootNavigatorKey = GlobalKey<NavigatorState>();

      router = GoRouter(
        navigatorKey: rootNavigatorKey,
        initialLocation: '/home',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) {
              return BottomNavBar(navigationShell: navigationShell);
            },
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/home',
                    builder: (context, state) => const _TestScreen(
                      title: 'Home',
                      key: Key('home_screen'),
                    ),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/browse',
                    builder: (context, state) => const _TestScreen(
                      title: 'Browse',
                      key: Key('browse_screen'),
                    ),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/games',
                    builder: (context, state) => const _TestScreen(
                      title: 'Library',
                      key: Key('library_screen'),
                    ),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/profile',
                    builder: (context, state) => const _TestScreen(
                      title: 'Profile',
                      key: Key('profile_screen'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
    });

    Widget createBottomNavBar() {
      return MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      );
    }

    testWidgets('should display all four navigation destinations', (
      tester,
    ) async {
      // Act
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createBottomNavBar());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(NavigationBar), findsOneWidget);
      // Check that labels exist (they appear in multiple places in Material 3)
      expect(find.text('Home'), findsAtLeastNWidgets(1));
      expect(find.text('Browse'), findsAtLeastNWidgets(1));
      expect(find.text('Library'), findsAtLeastNWidgets(1));
      expect(find.text('Profile'), findsAtLeastNWidgets(1));
    });

    testWidgets('should display correct icons', (tester) async {
      // Act
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createBottomNavBar());
      await tester.pumpAndSettle();

      // Assert - Check for the destination icons (outlined or filled)
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Icon &&
              (widget.icon == Icons.home_outlined || widget.icon == Icons.home),
        ),
        findsWidgets,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Icon &&
              (widget.icon == Icons.explore_outlined ||
                  widget.icon == Icons.explore),
        ),
        findsWidgets,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Icon &&
              (widget.icon == Icons.sports_esports_outlined ||
                  widget.icon == Icons.sports_esports),
        ),
        findsWidgets,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Icon &&
              (widget.icon == Icons.person_outline ||
                  widget.icon == Icons.person),
        ),
        findsWidgets,
      );
    });

    testWidgets('should start on Home tab', (tester) async {
      // Act
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createBottomNavBar());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const Key('home_screen')), findsOneWidget);
      expect(find.text('Home Content'), findsOneWidget);
    });

    testWidgets('should navigate to Browse tab when tapped', (tester) async {
      // Arrange
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createBottomNavBar());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Browse'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const Key('browse_screen')), findsOneWidget);
      expect(find.text('Browse Content'), findsOneWidget);
    });

    testWidgets('should navigate to Library tab when tapped', (tester) async {
      // Arrange
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createBottomNavBar());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Library'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const Key('library_screen')), findsOneWidget);
      expect(find.text('Library Content'), findsOneWidget);
    });

    testWidgets('should navigate to Profile tab when tapped', (tester) async {
      // Arrange
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createBottomNavBar());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const Key('profile_screen')), findsOneWidget);
      expect(find.text('Profile Content'), findsOneWidget);
    });

    testWidgets('should maintain state when switching tabs', (tester) async {
      // Arrange
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createBottomNavBar());
      await tester.pumpAndSettle();

      // Start on Home
      expect(find.byKey(const Key('home_screen')), findsOneWidget);

      // Act - Switch to Library
      await tester.tap(find.text('Library'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('library_screen')), findsOneWidget);

      // Act - Switch back to Home
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      // Assert - Home screen should still exist (state preserved)
      expect(find.byKey(const Key('home_screen')), findsOneWidget);
      expect(find.text('Home Content'), findsOneWidget);
    });

    testWidgets('should highlight selected tab', (tester) async {
      // Arrange
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createBottomNavBar());
      await tester.pumpAndSettle();

      // Act - Navigate to Profile (index 3)
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Assert - Profile tab should be selected
      final navigationBar = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );
      expect(navigationBar.selectedIndex, equals(3));
    });

    testWidgets('should animate between tabs', (tester) async {
      // Arrange
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createBottomNavBar());
      await tester.pumpAndSettle();

      // Act - Switch tabs
      await tester.tap(find.text('Library'));

      // Pump once to start animation (don't settle yet)
      await tester.pump();

      // Assert - NavigationBar should have animation duration
      final navigationBar = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );
      expect(
        navigationBar.animationDuration,
        equals(const Duration(milliseconds: 400)),
      );

      // Complete animation
      await tester.pumpAndSettle();
    });

    testWidgets('should show labels always', (tester) async {
      // Act
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createBottomNavBar());
      await tester.pumpAndSettle();

      // Assert
      final navigationBar = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );
      expect(
        navigationBar.labelBehavior,
        equals(NavigationDestinationLabelBehavior.alwaysShow),
      );
    });

    testWidgets('should use a NavigationRail on wide screens', (tester) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createBottomNavBar());
      await tester.pumpAndSettle();

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });
  });
}

/// Test screen widget for navigation testing
class _TestScreen extends StatelessWidget {
  const _TestScreen({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title Content')),
    );
  }
}
