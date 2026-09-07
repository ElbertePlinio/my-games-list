import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/core/data/services/storage/local_storage_service.dart';
import 'package:picklog/core/utils/app_router.dart';
import 'package:picklog/core/utils/service_locator.dart';
import 'package:picklog/core/widgets/brand_logo.dart';
import 'package:picklog/features/auth/auth_repository.dart';
import 'package:picklog/features/auth/bloc/auth_bloc.dart';
import 'package:picklog/features/auth/bloc/auth_event.dart';
import 'package:picklog/features/auth/bloc/auth_state.dart';
import 'package:picklog/features/auth/user_model.dart';
import 'package:picklog/features/onboarding/onboarding_screen.dart';
import 'package:picklog/features/splash/splash_screen.dart';
import 'package:picklog/l10n/app_localizations.dart';

import '../../mocks/mock_blocs.dart';
import '../../mocks/mock_services.dart';

// Fake classes for registerFallbackValue
class FakeAuthEvent extends Fake implements AuthEvent {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeAuthEvent());
  });

  group('SplashScreen', () {
    late MockAuthBloc mockAuthBloc;
    late MockLocalStorageService mockStorage;

    setUp(() {
      mockAuthBloc = MockAuthBloc();
      mockStorage = MockLocalStorageService();

      sl.registerLazySingleton<AuthRepository>(() => MockAuthRepository());
      sl.registerLazySingleton<LocalStorageService>(() => mockStorage);
      sl.registerLazySingleton<AuthBloc>(
        () => AuthBloc(sl<LocalStorageService>(), FakeSessionResetService()),
      );
    });

    tearDown(() async {
      mockAuthBloc.close();
      await sl.reset();
    });

    Widget createSplashScreen() {
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
          home: SplashScreen(),
        ),
      );
    }

    testWidgets('should display brand logo and name', (tester) async {
      // Arrange
      whenListen(
        mockAuthBloc,
        const Stream<AuthState>.empty(),
        initialState: const AuthInitial(),
      );

      // Act
      await tester.pumpWidget(createSplashScreen());

      // Assert
      expect(find.byType(BrandLogo), findsOneWidget);
      expect(find.byIcon(Icons.games), findsOneWidget);
      expect(find.text('Picklog'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should dispatch AuthStateLoaded event on init', (
      tester,
    ) async {
      // Arrange
      final events = <AuthEvent>[];
      whenListen(
        mockAuthBloc,
        const Stream<AuthState>.empty(),
        initialState: const AuthInitial(),
      );

      // Override the add method to capture events
      when(() => mockAuthBloc.add(any())).thenAnswer((invocation) {
        events.add(invocation.positionalArguments[0] as AuthEvent);
      });

      // Act
      await tester.pumpWidget(createSplashScreen());

      // Assert
      expect(events, contains(isA<AuthStateLoaded>()));
    });

    testWidgets('should wait minimum 800ms before navigation', (tester) async {
      // Arrange
      await mockStorage.setBool('onboarding_completed', true);
      const testUser = User(
        id: '123',
        email: 'test@example.com',
        name: 'Test User',
      );

      // Immediately emit authenticated state
      whenListen(
        mockAuthBloc,
        Stream<AuthState>.fromIterable([const AuthAuthenticated(testUser)]),
        initialState: const AuthInitial(),
      );

      // Act
      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: mockAuthBloc,
          child: MaterialApp.router(
            routerConfig: AppRouter.createRouter(),
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

      // Wait less than 800ms
      await tester.pump(const Duration(milliseconds: 400));

      // Assert - Should still be on splash screen
      expect(find.byType(SplashScreen), findsOneWidget);

      // Wait for minimum display duration to complete
      await tester.pumpAndSettle();

      // Should have navigated away from splash
      expect(find.byType(SplashScreen), findsNothing);
    });

    testWidgets(
      'should navigate to home when authenticated after min duration',
      (tester) async {
        // Arrange
        await mockStorage.setBool('onboarding_completed', true);
        const testUser = User(
          id: '123',
          email: 'test@example.com',
          name: 'Test User',
        );

        final controller = StreamController<AuthState>();
        whenListen(
          mockAuthBloc,
          controller.stream,
          initialState: const AuthInitial(),
        );

        // Act
        await tester.pumpWidget(
          BlocProvider<AuthBloc>.value(
            value: mockAuthBloc,
            child: MaterialApp.router(
              routerConfig: AppRouter.createRouter(),
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

        // Emit authenticated state
        controller.add(const AuthAuthenticated(testUser));

        // Wait for navigation
        await tester.pumpAndSettle();

        // Assert - Should be on home screen (no longer on splash)
        expect(find.byType(SplashScreen), findsNothing);

        // Cleanup
        await controller.close();
      },
    );

    testWidgets(
      'should navigate to signin when unauthenticated after min duration',
      (tester) async {
        // Arrange
        await mockStorage.setBool('onboarding_completed', true);
        final controller = StreamController<AuthState>();
        whenListen(
          mockAuthBloc,
          controller.stream,
          initialState: const AuthInitial(),
        );

        // Act
        await tester.pumpWidget(
          BlocProvider<AuthBloc>.value(
            value: mockAuthBloc,
            child: MaterialApp.router(
              routerConfig: AppRouter.createRouter(),
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

        // Emit unauthenticated state
        controller.add(const AuthUnauthenticated());

        // Wait for navigation
        await tester.pumpAndSettle();

        // Assert - Should be on signin screen (no longer on splash)
        expect(find.byType(SplashScreen), findsNothing);

        // Cleanup
        await controller.close();
      },
    );

    testWidgets('should navigate to signin on auth error', (tester) async {
      // Arrange
      await mockStorage.setBool('onboarding_completed', true);
      final controller = StreamController<AuthState>();
      whenListen(
        mockAuthBloc,
        controller.stream,
        initialState: const AuthInitial(),
      );

      // Act
      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: mockAuthBloc,
          child: MaterialApp.router(
            routerConfig: AppRouter.createRouter(),
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

      // Emit error state
      controller.add(const AuthError('Auth failed'));

      // Wait for navigation
      await tester.pumpAndSettle();

      // Assert - Should be on signin screen (no longer on splash)
      expect(find.byType(SplashScreen), findsNothing);

      // Cleanup
      await controller.close();
    });

    testWidgets(
      'should navigate to onboarding on first launch (flag not set)',
      (tester) async {
        // Arrange - onboarding flag intentionally left unset (fresh install)
        final controller = StreamController<AuthState>();
        whenListen(
          mockAuthBloc,
          controller.stream,
          initialState: const AuthInitial(),
        );

        // Act
        await tester.pumpWidget(
          BlocProvider<AuthBloc>.value(
            value: mockAuthBloc,
            child: MaterialApp.router(
              routerConfig: AppRouter.createRouter(),
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

        // Even an authenticated user sees onboarding once before continuing.
        controller.add(
          const AuthAuthenticated(User(id: '1', email: 'a@b.com', name: 'A')),
        );
        await tester.pumpAndSettle();

        // Assert - first launch routes to onboarding, not home/signin
        expect(find.byType(SplashScreen), findsNothing);
        expect(find.byType(OnboardingScreen), findsOneWidget);

        // Cleanup
        await controller.close();
      },
    );
  });
}
