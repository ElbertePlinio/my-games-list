import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/core/services/connectivity_cubit.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/widgets/app_error_boundary.dart';
import 'package:picklog/core/widgets/offline_banner.dart';
import 'package:picklog/features/browse/widgets/browse_status_views.dart';
import 'package:picklog/l10n/app_localizations.dart';

class _MockConnectivityCubit extends MockCubit<bool>
    implements ConnectivityCubit {}

/// Pumps [child] under the `pt` locale with the real localization delegates, so
/// failures here mean a translation didn't resolve and fell back to English.
Future<void> pumpPt(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('pt'),
      home: child,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  // Portuguese strings asserted below come straight from lib/l10n/app_pt.arb.
  group('pt locale renders Portuguese strings', () {
    testWidgets('AppErrorBoundary uses the pt error title and message', (
      tester,
    ) async {
      await pumpPt(tester, const AppErrorBoundary());

      expect(find.text('Erro'), findsOneWidget);
      expect(find.text('Ops! Algo deu errado.'), findsOneWidget);
      // Guard against an English fallback slipping through.
      expect(find.text('Error'), findsNothing);
    });

    testWidgets('BrowseErrorView uses the pt heading and retry label', (
      tester,
    ) async {
      final connectivity = _MockConnectivityCubit();
      when(() => connectivity.state).thenReturn(true);

      await pumpPt(
        tester,
        BlocProvider<ConnectivityCubit>.value(
          value: connectivity,
          child: Scaffold(
            body: BrowseErrorView(message: 'detalhe', onRetry: () {}),
          ),
        ),
      );

      expect(find.text('Erro ao carregar dados'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
    });

    testWidgets('BrowseErrorView uses the pt offline copy while offline', (
      tester,
    ) async {
      final connectivity = _MockConnectivityCubit();
      when(() => connectivity.state).thenReturn(false);

      await pumpPt(
        tester,
        BlocProvider<ConnectivityCubit>.value(
          value: connectivity,
          child: Scaffold(
            body: BrowseErrorView(message: 'detalhe', onRetry: () {}),
          ),
        ),
      );

      expect(find.text('Você está offline'), findsOneWidget);
      expect(
        find.text('Verifique sua conexão e tente novamente.'),
        findsOneWidget,
      );
      expect(find.text("You're offline"), findsNothing);
    });

    testWidgets('BrowseEmptyView renders the pt message from l10n', (
      tester,
    ) async {
      // Resolve the message through context.l10n inside the pumped tree (as the
      // real screen does) so a missing/fallback pt string fails this test.
      await pumpPt(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => BrowseEmptyView(
              icon: Icons.inbox,
              message: context.l10n.browseGenresEmpty,
            ),
          ),
        ),
      );

      expect(find.text('Nenhum gênero disponível no momento.'), findsOneWidget);
    });

    group('OfflineBanner', () {
      late _MockConnectivityCubit connectivity;

      setUp(() => connectivity = _MockConnectivityCubit());

      testWidgets('shows the pt offline message while offline', (tester) async {
        when(() => connectivity.state).thenReturn(false);

        await pumpPt(
          tester,
          BlocProvider<ConnectivityCubit>.value(
            value: connectivity,
            child: const OfflineBanner(child: SizedBox.shrink()),
          ),
        );

        expect(find.text('Você está offline'), findsOneWidget);
        expect(find.text("You're offline"), findsNothing);
      });

      testWidgets('hides the banner while online', (tester) async {
        when(() => connectivity.state).thenReturn(true);

        await pumpPt(
          tester,
          BlocProvider<ConnectivityCubit>.value(
            value: connectivity,
            child: const OfflineBanner(child: SizedBox.shrink()),
          ),
        );

        expect(find.text('Você está offline'), findsNothing);
      });
    });
  });
}
