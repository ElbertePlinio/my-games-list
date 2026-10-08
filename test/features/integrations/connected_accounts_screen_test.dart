import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/features/integrations/bloc/connected_accounts_cubit.dart';
import 'package:picklog/features/integrations/connected_accounts_screen.dart';
import 'package:picklog/features/integrations/integrations_models.dart';
import 'package:picklog/features/integrations/integrations_repository.dart';
import 'package:picklog/features/integrations/widgets/link_account_sheet.dart';

import '../../helpers/stub_router_app.dart';
import 'integrations_fixtures.dart';

void main() {
  late MockIntegrationsRepository repository;

  setUpAll(() => registerFallbackValue(GameProvider.steam));

  setUp(() => repository = MockIntegrationsRepository());

  Future<ConnectedAccountsCubit> pump(
    WidgetTester tester,
    List<LinkedProvider> list, {
    bool settle = true,
  }) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    when(() => repository.getLinkedAccounts()).thenAnswer((_) async => list);
    final cubit = ConnectedAccountsCubit(repository: repository)..load();
    // The provider closes the cubit with the tree, which stops polling.
    await tester.pumpWidget(
      stubRouterApp(
        BlocProvider(
          create: (_) => cubit,
          child: const ConnectedAccountsScreen(),
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }
    return cubit;
  }

  testWidgets('lists every provider with its state', (tester) async {
    await pump(tester, providers());

    expect(find.text('Steam'), findsOneWidget);
    expect(find.text('Xbox'), findsOneWidget);
    expect(find.text('RetroAchievements'), findsOneWidget);
    expect(find.text('PlayStation'), findsOneWidget);
    expect(find.text('Experimental'), findsOneWidget);
    expect(find.text('Unavailable'), findsNWidgets(2));
    expect(find.widgetWithText(OutlinedButton, 'Link'), findsNWidgets(2));
  });

  testWidgets('the link sheet shows Steam help and links the account', (
    tester,
  ) async {
    when(
      () => repository.link(GameProvider.steam, 'hornet'),
    ).thenAnswer((_) async => account());
    await pump(tester, providers());

    await tester.tap(find.widgetWithText(OutlinedButton, 'Link').first);
    await tester.pumpAndSettle();

    expect(find.byType(LinkAccountSheet), findsOneWidget);
    expect(find.text('Link Steam'), findsOneWidget);
    expect(find.text('Steam profile URL or ID'), findsOneWidget);
    expect(find.textContaining('Game details must be public'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'hornet');
    await tester.tap(find.text('Link account'));
    await tester.pumpAndSettle();

    expect(find.byType(LinkAccountSheet), findsNothing);
    expect(find.text('Hornet'), findsOneWidget);
    expect(
      find.text('Steam linked. Tap Sync now to import your data.'),
      findsOneWidget,
    );
  });

  for (final (kind, message) in [
    (
      IntegrationErrorKind.accountNotFound,
      'We could not find that account. Check the spelling and try again.',
    ),
    (
      IntegrationErrorKind.privateProfile,
      'This profile is private. Make your game details public and try again.',
    ),
  ]) {
    testWidgets('the link sheet maps $kind to a helpful message', (
      tester,
    ) async {
      when(
        () => repository.link(any(), any()),
      ).thenThrow(IntegrationException(kind));
      await pump(tester, providers());

      await tester.tap(find.widgetWithText(OutlinedButton, 'Link').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'nobody');
      await tester.tap(find.text('Link account'));
      await tester.pumpAndSettle();

      expect(find.byType(LinkAccountSheet), findsOneWidget);
      expect(find.text(message), findsOneWidget);
    });
  }

  testWidgets('a linked account shows name, last sync and actions', (
    tester,
  ) async {
    await pump(
      tester,
      providers(
        steam: account(
          lastSyncedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      ),
    );

    expect(find.text('Hornet'), findsOneWidget);
    expect(find.text('Last synced 5 min ago'), findsOneWidget);
    expect(find.text('Up to date'), findsOneWidget);
    expect(find.text('Sync now'), findsOneWidget);
    expect(find.text('Also import games to my library'), findsOneWidget);
    expect(find.text('Unlink'), findsOneWidget);
  });

  testWidgets('a syncing account shows progress and disables sync', (
    tester,
  ) async {
    await pump(
      tester,
      providers(xbox: account(status: SyncStatus.syncing)),
      settle: false,
    );

    expect(find.text('Syncing'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    final sync = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Sync now'),
    );
    expect(sync.onPressed, isNull);
  });

  testWidgets('sync now sends the import choice', (tester) async {
    when(
      () => repository.sync(GameProvider.steam, importLibrary: true),
    ).thenAnswer((_) async {});
    await pump(tester, providers(steam: account()));
    when(
      () => repository.getLinkedAccounts(),
    ).thenAnswer((_) async => providers(steam: account()));

    await tester.tap(find.text('Also import games to my library'));
    await tester.pump();
    await tester.tap(find.text('Sync now'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    verify(
      () => repository.sync(GameProvider.steam, importLibrary: true),
    ).called(1);
    expect(
      find.text('Syncing Steam. This can take a few minutes.'),
      findsOneWidget,
    );
  });

  testWidgets('sync too soon shows the cooldown message', (tester) async {
    when(
      () => repository.sync(any(), importLibrary: any(named: 'importLibrary')),
    ).thenThrow(const IntegrationException(IntegrationErrorKind.syncTooSoon));
    await pump(tester, providers(steam: account()));

    await tester.tap(find.text('Sync now'));
    await tester.pumpAndSettle();
    expect(
      find.text('This account synced recently. Try again in a few minutes.'),
      findsOneWidget,
    );
  });

  testWidgets('unlink asks to confirm', (tester) async {
    when(() => repository.unlink(GameProvider.steam)).thenAnswer((_) async {});
    await pump(tester, providers(steam: account()));

    await tester.tap(find.text('Unlink'));
    await tester.pumpAndSettle();
    expect(find.text('Unlink Steam?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    verifyNever(() => repository.unlink(any()));

    await tester.tap(find.text('Unlink'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Unlink').last);
    await tester.pumpAndSettle();

    verify(() => repository.unlink(GameProvider.steam)).called(1);
    expect(find.text('Hornet'), findsNothing);
  });

  testWidgets('a load failure shows a retry', (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    when(
      () => repository.getLinkedAccounts(),
    ).thenThrow(const IntegrationException(IntegrationErrorKind.network));
    final cubit = ConnectedAccountsCubit(repository: repository)..load();
    addTearDown(cubit.close);
    await tester.pumpWidget(
      stubRouterApp(
        BlocProvider.value(
          value: cubit,
          child: const ConnectedAccountsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('the settings section opens connected accounts', (tester) async {
    await tester.pumpWidget(
      stubRouterApp(const Scaffold(body: ConnectedAccountsSettingsSection())),
    );
    await tester.tap(find.text('Connected accounts'));
    await tester.pumpAndSettle();
    expect(find.textContaining('route:connectedAccounts'), findsOneWidget);
  });
}
