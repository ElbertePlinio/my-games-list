import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picklog/core/widgets/google_logo.dart';
import 'package:picklog/core/widgets/google_sign_in_button.dart';

void main() {
  group('GoogleSignInButton', () {
    testWidgets('shows the label and the Google logo', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GoogleSignInButton(
              label: 'Continue with Google',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.byType(GoogleLogo), findsOneWidget);
    });

    testWidgets('invokes onPressed when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GoogleSignInButton(
              label: 'Continue with Google',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GoogleSignInButton));
      expect(tapped, isTrue);
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GoogleSignInButton(
              label: 'Continue with Google',
              onPressed: null,
            ),
          ),
        ),
      );

      // OutlinedButton.icon builds an internal button subtype, so match any
      // ButtonStyleButton and assert it has no callback (disabled).
      final button = tester.widget<ButtonStyleButton>(
        find.byWidgetPredicate((w) => w is ButtonStyleButton),
      );
      expect(button.enabled, isFalse);
    });
  });
}
