import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/utils/service_locator.dart';
import 'package:picklog/features/settings/bloc/settings_bloc.dart';
import 'package:picklog/features/settings/bloc/settings_event.dart';
import 'package:picklog/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('PicklogApp', () {
    setUp(() async {
      // Reset GetIt and setup mock data. Mark onboarding completed so the app
      // routes straight to the auth flow — these tests assert returning-user
      // navigation, not the first-run onboarding screen.
      await sl.reset();
      SharedPreferences.setMockInitialValues({'onboarding_completed': true});
      await setupServiceLocator();
    });

    tearDown(() async {
      await sl.reset();
    });

    testWidgets('should initialize and display app correctly', (tester) async {
      // Act
      await tester.pumpWidget(const PicklogApp());
      await tester.pumpAndSettle();

      // Assert - App should be created and MaterialApp should be present
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('should have correct app title', (tester) async {
      // Arrange
      await tester.pumpWidget(const PicklogApp());
      await tester.pumpAndSettle();

      // Assert
      // Since we use onGenerateTitle with localization, we check the Title widget
      expect(find.byType(Title), findsOneWidget);
      final titleWidget = tester.widget<Title>(find.byType(Title));
      expect(titleWidget.title, equals('Picklog'));
    });

    testWidgets('should not show debug banner', (tester) async {
      // Arrange
      await tester.pumpWidget(const PicklogApp());
      await tester.pumpAndSettle();

      // Assert
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.debugShowCheckedModeBanner, isFalse);
    });

    testWidgets('should use Material 3 design', (tester) async {
      // Arrange
      await tester.pumpWidget(const PicklogApp());
      await tester.pumpAndSettle();

      // Assert
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme?.useMaterial3, isTrue);
    });

    testWidgets('should react to theme changes', (tester) async {
      // This test will be expanded once we have SettingsBloc fully integrated
      // For now, just ensure the app can be built
      await tester.pumpWidget(const PicklogApp());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('should not reset navigation when theme changes', (
      tester,
    ) async {
      // Arrange - Start the app
      await tester.pumpWidget(const PicklogApp());
      await tester.pumpAndSettle();

      // The email form starts collapsed. Open it before checking that theme
      // changes preserve both the sign-in route and its local form state.
      expect(find.byType(TextFormField), findsNothing);
      final signInContext = tester.element(find.byType(Scaffold));
      await tester.tap(find.text(signInContext.l10n.signInWithEmail));
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNWidgets(2));

      // Get the Scaffold to verify we're on sign-in screen
      expect(find.byType(Scaffold), findsOneWidget);

      // Act - Toggle dark mode via SettingsBloc
      final context = tester.element(find.byType(MaterialApp));
      final settingsBloc = context.read<SettingsBloc>();

      // Toggle to dark mode
      settingsBloc.add(const SettingsDarkModeSet(true));
      await tester.pumpAndSettle();

      // Assert - Should still have TextFormFields (still on sign-in page, not reset)
      expect(find.byType(TextFormField), findsWidgets);
      expect(find.byType(Scaffold), findsOneWidget);

      // Toggle back to light mode
      settingsBloc.add(const SettingsDarkModeSet(false));
      await tester.pumpAndSettle();

      // Assert - Should still be on sign-in page
      expect(find.byType(TextFormField), findsWidgets);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should apply dark theme when dark mode is enabled', (
      tester,
    ) async {
      // Arrange
      await tester.pumpWidget(const PicklogApp());
      await tester.pumpAndSettle();

      // Initially light: themeMode follows the (light) setting, and the static
      // light/dark themes carry the correct brightnesses.
      var materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.themeMode, equals(ThemeMode.light));
      expect(
        materialApp.theme?.colorScheme.brightness,
        equals(Brightness.light),
      );
      expect(
        materialApp.darkTheme?.colorScheme.brightness,
        equals(Brightness.dark),
      );

      // Act - Enable dark mode
      final context = tester.element(find.byType(MaterialApp));
      final settingsBloc = context.read<SettingsBloc>();
      settingsBloc.add(const SettingsDarkModeSet(true));
      await tester.pumpAndSettle();

      // Assert - themeMode switches to dark (the themes themselves are reused).
      materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.themeMode, equals(ThemeMode.dark));
    });
  });
}
