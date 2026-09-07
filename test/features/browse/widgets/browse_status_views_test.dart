import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/core/services/connectivity_cubit.dart';
import 'package:picklog/features/browse/widgets/browse_status_views.dart';
import 'package:picklog/l10n/app_localizations.dart';

class _MockConnectivityCubit extends MockCubit<bool>
    implements ConnectivityCubit {}

void main() {
  group('BrowseErrorView', () {
    late _MockConnectivityCubit connectivity;

    setUp(() => connectivity = _MockConnectivityCubit());

    Future<void> pumpView(WidgetTester tester, {required bool online}) async {
      when(() => connectivity.state).thenReturn(online);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: BlocProvider<ConnectivityCubit>.value(
              value: connectivity,
              child: BrowseErrorView(message: 'Boom', onRetry: () {}),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('shows the generic error when online', (tester) async {
      await pumpView(tester, online: true);

      expect(find.text('Error loading data'), findsOneWidget);
      expect(find.text('Boom'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text("You're offline"), findsNothing);
    });

    testWidgets('shows the offline message when offline', (tester) async {
      await pumpView(tester, online: false);

      expect(find.text("You're offline"), findsOneWidget);
      expect(find.text('Check your connection and try again.'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
      expect(find.text('Boom'), findsNothing);
    });

    testWidgets('always offers a retry button', (tester) async {
      await pumpView(tester, online: true);
      expect(find.text('Try again'), findsOneWidget);

      await pumpView(tester, online: false);
      expect(find.text('Try again'), findsOneWidget);
    });
  });
}
