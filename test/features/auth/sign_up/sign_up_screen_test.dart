import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/core/utils/app_router.dart';
import 'package:picklog/features/auth/bloc/auth_bloc.dart';
import 'package:picklog/features/auth/bloc/auth_state.dart';
import 'package:picklog/features/auth/sign_up/bloc/sign_up_bloc.dart';
import 'package:picklog/features/auth/sign_up/bloc/sign_up_event.dart';
import 'package:picklog/features/auth/sign_up/bloc/sign_up_state.dart';
import 'package:picklog/features/auth/sign_up/sign_up_screen.dart';
import 'package:picklog/features/legal/legal_document.dart';
import 'package:picklog/features/legal/presentation/legal_document_screen.dart';
import 'package:picklog/l10n/app_localizations.dart';

import '../../../mocks/mock_blocs.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(
      const SignUpSubmitted(
        email: '',
        password: '',
        username: '',
        acceptedTerms: false,
      ),
    );
  });

  group('SignUpScreen', () {
    late MockSignUpBloc signUpBloc;
    late MockAuthBloc authBloc;

    setUp(() {
      signUpBloc = MockSignUpBloc();
      authBloc = MockAuthBloc();
      when(() => signUpBloc.state).thenReturn(const SignUpInitial());
      when(() => authBloc.state).thenReturn(const AuthUnauthenticated());
    });

    tearDown(() {
      signUpBloc.close();
      authBloc.close();
    });

    // Minimal router that mirrors production: the sign-up screen plus the two
    // legal routes, registered under the same names the app uses so the
    // consent-checkbox links resolve.
    Widget buildApp() {
      final router = GoRouter(
        initialLocation: AppRouter.signUpPath,
        routes: [
          GoRoute(
            path: AppRouter.signUpPath,
            name: AppRouter.signUpName,
            builder: (_, _) => MultiBlocProvider(
              providers: [
                BlocProvider<SignUpBloc>.value(value: signUpBloc),
                BlocProvider<AuthBloc>.value(value: authBloc),
              ],
              child: const SignUpScreen(),
            ),
          ),
          GoRoute(
            path: AppRouter.privacyPolicyPath,
            name: AppRouter.privacyPolicyName,
            builder: (_, _) => const LegalDocumentScreen(
              document: LegalDocument.privacyPolicy,
            ),
          ),
          GoRoute(
            path: AppRouter.termsPath,
            name: AppRouter.termsName,
            builder: (_, _) =>
                const LegalDocumentScreen(document: LegalDocument.terms),
          ),
        ],
      );

      return MaterialApp.router(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      );
    }

    Finder signUpButton() => find.widgetWithText(FilledButton, 'Sign Up');

    Future<void> acceptTerms(WidgetTester tester) async {
      await tester.ensureVisible(find.byType(Checkbox));
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
    }

    testWidgets('renders the four credential fields and the submit button', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNWidgets(4));
      expect(find.widgetWithText(AppBar, 'Sign Up'), findsOneWidget);
      expect(signUpButton(), findsOneWidget);
    });

    testWidgets('Sign Up button is disabled until acceptance is checked', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Disabled before checking the box.
      expect(tester.widget<FilledButton>(signUpButton()).onPressed, isNull);

      await acceptTerms(tester);

      // Enabled after acceptance.
      expect(tester.widget<FilledButton>(signUpButton()).onPressed, isNotNull);
    });

    testWidgets('accepting and submitting dispatches SignUpSubmitted with '
        'acceptedTerms true and the trimmed credentials', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await acceptTerms(tester);

      await tester.enterText(find.byType(TextFormField).at(0), 'newuser');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'newuser@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      await tester.enterText(find.byType(TextFormField).at(3), 'password123');

      await tester.ensureVisible(signUpButton());
      await tester.tap(signUpButton());
      await tester.pumpAndSettle();

      final captured =
          verify(() => signUpBloc.add(captureAny())).captured.single
              as SignUpSubmitted;
      expect(captured.acceptedTerms, isTrue);
      expect(captured.email, 'newuser@example.com');
      expect(captured.username, 'newuser');
      expect(captured.password, 'password123');
    });

    testWidgets('mismatched passwords block submission even after acceptance', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await acceptTerms(tester);

      await tester.enterText(find.byType(TextFormField).at(0), 'gamer');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'gamer@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(2), 'secret123');
      await tester.enterText(find.byType(TextFormField).at(3), 'different');

      await tester.ensureVisible(signUpButton());
      await tester.tap(signUpButton());
      await tester.pumpAndSettle();

      verifyNever(() => signUpBloc.add(any<SignUpSubmitted>()));
    });

    testWidgets(
      'loading state shows a progress indicator and disables submit',
      (tester) async {
        when(() => signUpBloc.state).thenReturn(const SignUpLoading());

        await tester.pumpWidget(buildApp());
        // The loading button hosts a CircularProgressIndicator, which animates
        // forever — pumpAndSettle would time out, so pump a single frame.
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        // In the loading state the button shows the spinner instead of its
        // label, so locate it by type rather than by text.
        final button = tester.widget<FilledButton>(find.byType(FilledButton));
        expect(button.onPressed, isNull);
      },
    );

    testWidgets('an error state surfaces the message in a snackbar', (
      tester,
    ) async {
      whenListen(
        signUpBloc,
        Stream<SignUpState>.fromIterable([
          const SignUpError('Email already in use'),
        ]),
        initialState: const SignUpInitial(),
      );

      await tester.pumpWidget(buildApp());
      await tester.pump();

      expect(find.text('Email already in use'), findsOneWidget);
    });

    testWidgets('Privacy Policy link in the consent label opens the Privacy '
        'Policy screen', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // The link is a TextSpan inside the consent checkbox label, so tap it via
      // its text range rather than find.text (which can't target a span).
      await tester.ensureVisible(find.byType(Checkbox));
      await tester.tapOnText(find.textRange.ofSubstring('Privacy Policy'));
      await tester.pumpAndSettle();

      // AppBar title + body heading both read "Privacy Policy"; the localized
      // DRAFT banner confirms the placeholder document screen actually rendered.
      expect(find.text('Privacy Policy'), findsWidgets);
      expect(
        find.text(
          'DRAFT — placeholder text. Replace with the final legal text before release.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Terms link in the consent label opens the Terms of Service '
        'screen', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byType(Checkbox));
      await tester.tapOnText(find.textRange.ofSubstring('Terms of Service'));
      await tester.pumpAndSettle();

      expect(find.text('Terms of Service'), findsWidgets);
      expect(
        find.text(
          'DRAFT — placeholder text. Replace with the final legal text before release.',
        ),
        findsOneWidget,
      );
    });
  });
}
