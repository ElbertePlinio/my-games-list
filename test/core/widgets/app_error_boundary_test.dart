import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picklog/core/widgets/app_error_boundary.dart';
import 'package:picklog/l10n/app_localizations.dart';

void main() {
  group('AppErrorBoundary', () {
    testWidgets('renders the localized error title and message', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: AppErrorBoundary(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Error'), findsOneWidget);
      expect(find.text('Oops! Something went wrong.'), findsOneWidget);
    });

    testWidgets('falls back to default text without localizations', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MediaQuery(data: MediaQueryData(), child: AppErrorBoundary()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Error'), findsOneWidget);
      expect(find.text('Something went wrong.'), findsOneWidget);
    });
  });
}
