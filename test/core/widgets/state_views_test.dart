import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/core/domain/models/api_error.dart';
import 'package:picklog/core/domain/models/app_failure.dart';
import 'package:picklog/core/services/connectivity_cubit.dart';
import 'package:picklog/core/utils/error_l10n.dart';
import 'package:picklog/core/widgets/state_views.dart';

import '../../helpers/pump_app.dart';

class _MockConnectivityCubit extends Mock implements ConnectivityCubit {}

void main() {
  group('EmptyState', () {
    testWidgets('renders the title, message and action', (tester) async {
      var tapped = false;
      await pumpPicklog(
        tester,
        EmptyState(
          icon: Icons.inbox,
          title: 'Nothing here',
          message: 'Add something',
          action: FilledButton(
            onPressed: () => tapped = true,
            child: const Text('Add'),
          ),
        ),
      );

      expect(find.text('Nothing here'), findsOneWidget);
      expect(find.text('Add something'), findsOneWidget);
      await tester.tap(find.text('Add'));
      expect(tapped, isTrue);
    });

    testWidgets('compact variant fits in a row', (tester) async {
      await pumpPicklog(
        tester,
        const EmptyState(icon: Icons.inbox, title: 'Nothing', compact: true),
      );
      expect(find.text('Nothing'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('ErrorState', () {
    testWidgets('shows the default heading and calls retry', (tester) async {
      var retries = 0;
      await pumpPicklog(
        tester,
        ErrorState(message: 'Boom', onRetry: () => retries++),
      );

      expect(find.text('Error loading data'), findsOneWidget);
      expect(find.text('Boom'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      expect(retries, 1);
    });

    testWidgets('explains the offline state when connectivity is down', (
      tester,
    ) async {
      final connectivity = _MockConnectivityCubit();
      when(() => connectivity.state).thenReturn(false);
      when(
        () => connectivity.stream,
      ).thenAnswer((_) => const Stream<bool>.empty());

      await pumpPicklog(
        tester,
        BlocProvider<ConnectivityCubit>.value(
          value: connectivity,
          child: ErrorState(message: 'Boom', onRetry: () {}),
        ),
      );

      expect(find.text("You're offline"), findsOneWidget);
      expect(find.text('Boom'), findsNothing);
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('compact variant renders an inline retry', (tester) async {
      await pumpPicklog(
        tester,
        ErrorState(message: 'Row failed', onRetry: () {}, compact: true),
      );
      expect(
        find.ancestor(
          of: find.text('Try again'),
          matching: find.byWidgetPredicate((w) => w is OutlinedButton),
        ),
        findsOneWidget,
      );
    });
  });

  group('AppErrorKind', () {
    ApiError api(int status, String code) => ApiError(
      name: 'n',
      message: 'm',
      action: 'a',
      statusCode: status,
      errorCode: code,
    );

    test('maps API errors to kinds', () {
      expect(
        AppErrorKind.from(ApiException(api(0, 'error.network.timeout'))),
        AppErrorKind.network,
      );
      expect(
        AppErrorKind.from(ApiException(api(404, 'error.api.not_found'))),
        AppErrorKind.notFound,
      );
      expect(
        AppErrorKind.from(ApiException(api(401, 'error.auth.unauthorized'))),
        AppErrorKind.unauthorized,
      );
      expect(
        AppErrorKind.from(ApiException(api(503, 'error.api.server_error'))),
        AppErrorKind.server,
      );
      expect(AppErrorKind.from(Exception('x')), AppErrorKind.unknown);
    });

    testWidgets('every kind has a localized pt message', (tester) async {
      late BuildContext captured;
      await pumpPicklog(
        tester,
        Builder(
          builder: (context) {
            captured = context;
            return const SizedBox();
          },
        ),
        locale: const Locale('pt'),
      );
      final messages = AppErrorKind.values
          .map((k) => k.message(captured))
          .toSet();
      expect(messages, hasLength(AppErrorKind.values.length));
      expect(AppErrorKind.network.message(captured), contains('conexão'));
    });
  });
}
