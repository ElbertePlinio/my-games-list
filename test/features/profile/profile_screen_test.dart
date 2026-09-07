import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:picklog/core/utils/app_router.dart';
import 'package:picklog/features/auth/bloc/auth_bloc.dart';
import 'package:picklog/features/auth/bloc/auth_state.dart';
import 'package:picklog/features/auth/user_model.dart';
import 'package:picklog/features/profile/profile_screen.dart';
import 'package:picklog/l10n/app_localizations.dart';

import '../../mocks/mock_blocs.dart';

void main() {
  group('ProfileScreen', () {
    late MockAuthBloc mockAuthBloc;
    const testUser = User(
      id: '123',
      email: 'test@example.com',
      name: 'Test User',
    );

    setUp(() {
      mockAuthBloc = MockAuthBloc();
    });

    tearDown(() {
      mockAuthBloc.close();
    });

    Widget createProfileScreen() {
      return BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: ProfileScreen(),
        ),
      );
    }

    testWidgets('should display profile title in app bar', (tester) async {
      // Arrange
      whenListen(
        mockAuthBloc,
        const Stream<AuthState>.empty(),
        initialState: const AuthAuthenticated(testUser),
      );

      // Act
      await tester.pumpWidget(createProfileScreen());

      // Assert
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('should display settings icon in app bar', (tester) async {
      // Arrange
      whenListen(
        mockAuthBloc,
        const Stream<AuthState>.empty(),
        initialState: const AuthAuthenticated(testUser),
      );

      // Act
      await tester.pumpWidget(createProfileScreen());

      // Assert
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('should display user avatar', (tester) async {
      // Arrange
      whenListen(
        mockAuthBloc,
        const Stream<AuthState>.empty(),
        initialState: const AuthAuthenticated(testUser),
      );

      // Act
      await tester.pumpWidget(createProfileScreen());

      // Assert
      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('should display username from AuthBloc', (tester) async {
      // Arrange
      whenListen(
        mockAuthBloc,
        const Stream<AuthState>.empty(),
        initialState: const AuthAuthenticated(testUser),
      );

      // Act
      await tester.pumpWidget(createProfileScreen());

      // Assert
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Test User'), findsOneWidget);
    });

    testWidgets('should display email from AuthBloc', (tester) async {
      // Arrange
      whenListen(
        mockAuthBloc,
        const Stream<AuthState>.empty(),
        initialState: const AuthAuthenticated(testUser),
      );

      // Act
      await tester.pumpWidget(createProfileScreen());

      // Assert
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('should display user info in a card', (tester) async {
      // Arrange
      whenListen(
        mockAuthBloc,
        const Stream<AuthState>.empty(),
        initialState: const AuthAuthenticated(testUser),
      );

      // Act
      await tester.pumpWidget(createProfileScreen());

      // Assert
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('should display email and username icons', (tester) async {
      // Arrange
      whenListen(
        mockAuthBloc,
        const Stream<AuthState>.empty(),
        initialState: const AuthAuthenticated(testUser),
      );

      // Act
      await tester.pumpWidget(createProfileScreen());

      // Assert
      expect(find.byIcon(Icons.account_circle), findsOneWidget);
      expect(find.byIcon(Icons.email), findsOneWidget);
    });

    testWidgets('should navigate to settings when gear icon tapped', (
      tester,
    ) async {
      // Arrange
      whenListen(
        mockAuthBloc,
        const Stream<AuthState>.empty(),
        initialState: const AuthAuthenticated(testUser),
      );

      late String navigatedPath;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: AppRouter.settingsPath,
            builder: (context, state) {
              navigatedPath = AppRouter.settingsPath;
              return const Scaffold(body: Text('Settings'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: mockAuthBloc,
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
        ),
      );

      // Act
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Assert
      expect(navigatedPath, equals(AppRouter.settingsPath));
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('should show fallback text when not authenticated', (
      tester,
    ) async {
      // Arrange
      whenListen(
        mockAuthBloc,
        const Stream<AuthState>.empty(),
        initialState: const AuthUnauthenticated(),
      );

      // Act
      await tester.pumpWidget(createProfileScreen());

      // Assert
      expect(find.text('No user information available'), findsOneWidget);
    });

    testWidgets('should update when auth state changes', (tester) async {
      // Arrange
      const updatedUser = User(
        id: '456',
        email: 'updated@example.com',
        name: 'Updated User',
      );

      whenListen(
        mockAuthBloc,
        Stream<AuthState>.fromIterable([
          const AuthAuthenticated(testUser),
          const AuthAuthenticated(updatedUser),
        ]),
        initialState: const AuthAuthenticated(testUser),
      );

      // Act
      await tester.pumpWidget(createProfileScreen());
      expect(find.text('Test User'), findsOneWidget);

      // Pump to process state change
      await tester.pump();

      // Assert - Should show updated user
      expect(find.text('Updated User'), findsOneWidget);
      expect(find.text('updated@example.com'), findsOneWidget);
    });

    testWidgets('should have settings tooltip', (tester) async {
      // Arrange
      whenListen(
        mockAuthBloc,
        const Stream<AuthState>.empty(),
        initialState: const AuthAuthenticated(testUser),
      );

      // Act
      await tester.pumpWidget(createProfileScreen());

      // Assert
      final settingsButtonFinder = find.byKey(
        const Key('profile_settings_button'),
      );
      expect(settingsButtonFinder, findsOneWidget);

      final tooltip = tester.widget<IconButton>(settingsButtonFinder).tooltip;
      expect(tooltip, equals('Settings'));
    });
  });
}
