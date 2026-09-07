import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picklog/core/utils/app_router.dart';
import 'package:picklog/core/utils/service_locator.dart';
import 'package:picklog/features/auth/bloc/auth_bloc.dart';
import 'package:picklog/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AppRouter', () {
    setUp(() async {
      // Reset GetIt and setup mock data
      await sl.reset();
      SharedPreferences.setMockInitialValues({});
      await setupServiceLocator();
    });

    tearDown(() async {
      await sl.reset();
    });

    testWidgets('should create router with correct initial route', (
      tester,
    ) async {
      // Arrange
      final authBloc = sl<AuthBloc>();
      final router = AppRouter.createRouter();

      // Build the router in the widget tree so it initializes
      final app = BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );

      await tester.pumpWidget(app);
      await tester.pump();

      // Assert - Check that router is created successfully
      expect(router, isNotNull);
      expect(router.routerDelegate, isNotNull);
      // Initial location should be splash
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        equals('/splash'),
      );
      await tester.pumpAndSettle();

      // Cleanup
      authBloc.close();
    });

    testWidgets('should have all required routes configured', (tester) async {
      // Arrange
      final authBloc = sl<AuthBloc>();
      final router = AppRouter.createRouter();

      // Assert - Check that all routes are accessible
      expect(() => router.go(AppRouter.splashPath), returnsNormally);
      expect(() => router.go(AppRouter.signInPath), returnsNormally);
      expect(() => router.go(AppRouter.homePath), returnsNormally);
      expect(() => router.go(AppRouter.gamesPath), returnsNormally);
      expect(() => router.go(AppRouter.profilePath), returnsNormally);
      expect(() => router.go(AppRouter.settingsPath), returnsNormally);

      // Cleanup
      authBloc.close();
    });

    testWidgets('should handle named routes correctly', (tester) async {
      // Arrange
      final authBloc = sl<AuthBloc>();
      final router = AppRouter.createRouter();

      // Act & Assert - Check that named routes work
      expect(() => router.goNamed(AppRouter.splashName), returnsNormally);
      expect(() => router.goNamed(AppRouter.signInName), returnsNormally);
      expect(() => router.goNamed(AppRouter.homeName), returnsNormally);
      expect(() => router.goNamed(AppRouter.gamesName), returnsNormally);
      expect(() => router.goNamed(AppRouter.profileName), returnsNormally);
      expect(() => router.goNamed(AppRouter.settingsName), returnsNormally);

      // Cleanup
      authBloc.close();
    });

    test('should have correct route constants', () {
      // Assert
      expect(AppRouter.splashPath, equals('/splash'));
      expect(AppRouter.signInPath, equals('/signin'));
      expect(AppRouter.signUpPath, equals('/signup'));
      expect(AppRouter.homePath, equals('/home'));
      expect(AppRouter.gamesPath, equals('/games'));
      expect(AppRouter.profilePath, equals('/profile'));
      expect(AppRouter.settingsPath, equals('/settings'));

      expect(AppRouter.splashName, equals('splash'));
      expect(AppRouter.signInName, equals('signin'));
      expect(AppRouter.signUpName, equals('signup'));
      expect(AppRouter.homeName, equals('home'));
      expect(AppRouter.gamesName, equals('games'));
      expect(AppRouter.profileName, equals('profile'));
      expect(AppRouter.settingsName, equals('settings'));
    });
  });
}
