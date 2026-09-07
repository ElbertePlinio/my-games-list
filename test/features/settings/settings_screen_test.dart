import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/features/auth/auth_repository.dart';
import 'package:picklog/features/auth/bloc/auth_bloc.dart';
import 'package:picklog/features/auth/bloc/auth_event.dart';
import 'package:picklog/features/auth/bloc/auth_state.dart';
import 'package:picklog/features/auth/user_model.dart';
import 'package:picklog/core/services/consent/consent_category.dart';
import 'package:picklog/features/consent/bloc/consent_cubit.dart';
import 'package:picklog/features/consent/bloc/consent_state.dart';
import 'package:picklog/features/settings/bloc/account_management_bloc.dart';
import 'package:picklog/features/settings/bloc/account_management_state.dart';
import 'package:picklog/features/settings/bloc/settings_bloc.dart';
import 'package:picklog/features/settings/bloc/settings_state.dart';
import 'package:picklog/features/settings/services/account_export_saver.dart';
import 'package:picklog/features/settings/settings_screen.dart';
import 'package:picklog/l10n/app_localizations.dart';

import '../../mocks/mock_blocs.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class FakeAuthEvent extends Fake implements AuthEvent {}

class FakeAccountExportSaver implements AccountExportSaver {
  bool called = false;

  Rect? sharePositionOrigin;

  @override
  Future<void> save({
    required String fileName,
    required String json,
    Rect? sharePositionOrigin,
  }) async {
    called = true;
    this.sharePositionOrigin = sharePositionOrigin;
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeAuthEvent());
    registerFallbackValue(ConsentCategory.crash);
  });

  late MockAuthBloc mockAuthBloc;
  late MockSettingsBloc mockSettingsBloc;
  late MockConsentCubit mockConsentCubit;
  late MockAuthRepository mockRepository;
  late FakeAccountExportSaver fakeSaver;
  late AccountManagementBloc accountBloc;

  const deniedConsent = ConsentState(
    hasAnswered: true,
    granted: {
      ConsentCategory.analytics: false,
      ConsentCategory.crash: false,
      ConsentCategory.push: false,
    },
  );

  const testUser = User(
    id: '123',
    email: 'test@example.com',
    name: 'Test User',
    username: 'testuser',
  );

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockSettingsBloc = MockSettingsBloc();
    mockConsentCubit = MockConsentCubit();
    mockRepository = MockAuthRepository();
    fakeSaver = FakeAccountExportSaver();

    when(
      () => mockAuthBloc.state,
    ).thenReturn(const AuthAuthenticated(testUser));
    when(() => mockSettingsBloc.state).thenReturn(const SettingsState());
    when(() => mockConsentCubit.state).thenReturn(deniedConsent);
    when(
      () => mockConsentCubit.setCategory(any(), granted: any(named: 'granted')),
    ).thenAnswer((_) async {});
  });

  tearDown(() async {
    await mockAuthBloc.close();
    await mockSettingsBloc.close();
    await mockConsentCubit.close();
  });

  // The AccountManagementBloc is created inside BlocProvider.create so it lives
  // in the test's async zone (a bloc built in setUp would schedule its async on
  // the wrong zone and never settle under the fake clock).
  Widget buildScreen() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        BlocProvider<SettingsBloc>.value(value: mockSettingsBloc),
        BlocProvider<ConsentCubit>.value(value: mockConsentCubit),
        BlocProvider<AccountManagementBloc>(
          create: (_) {
            accountBloc = AccountManagementBloc(
              authRepository: mockRepository,
              exportSaver: fakeSaver,
            );
            return accountBloc;
          },
        ),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsScreen(),
      ),
    );
  }

  testWidgets('shows the privacy & data actions', (tester) async {
    await tester.pumpWidget(buildScreen());

    expect(find.text('Privacy & data'), findsOneWidget);
    expect(find.text('Export my data'), findsOneWidget);
    expect(find.text('Delete my account'), findsOneWidget);
  });

  testWidgets('delete requires typing the confirmation word before it runs', (
    tester,
  ) async {
    await tester.pumpWidget(buildScreen());

    await tester.ensureVisible(find.text('Delete my account'));
    await tester.tap(find.text('Delete my account'));
    await tester.pumpAndSettle();

    // Dialog is shown.
    expect(find.text('Delete account?'), findsOneWidget);

    // Confirm button is present but disabled until the word is typed.
    final confirmButton = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Delete account'),
    );
    expect(confirmButton.onPressed, isNull);

    // Tapping the disabled confirm must NOT delete or log out.
    await tester.tap(find.widgetWithText(TextButton, 'Delete account'));
    await tester.pumpAndSettle();
    verifyNever(() => mockRepository.deleteAccount());
    verifyNever(() => mockAuthBloc.add(any()));
  });

  testWidgets(
    'confirming deletion deletes the account and tears down session',
    (tester) async {
      when(() => mockRepository.deleteAccount()).thenAnswer((_) async {});

      await tester.pumpWidget(buildScreen());

      await tester.ensureVisible(find.text('Delete my account'));
      await tester.tap(find.text('Delete my account'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'DELETE');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Delete account'));
      await tester.pumpAndSettle();

      verify(() => mockRepository.deleteAccount()).called(1);
      verify(() => mockAuthBloc.add(const AuthLogoutRequested())).called(1);
    },
  );

  testWidgets('export triggers the request and delivers the payload', (
    tester,
  ) async {
    when(
      () => mockRepository.exportData(),
    ).thenAnswer((_) async => '{"user":{}}');

    await tester.pumpWidget(buildScreen());

    await tester.ensureVisible(find.text('Export my data'));
    await tester.tap(find.text('Export my data'));
    await tester.pumpAndSettle();

    verify(() => mockRepository.exportData()).called(1);
    expect(fakeSaver.called, isTrue);
    // The tile's anchor rect is threaded through for the iPad share sheet.
    expect(fakeSaver.sharePositionOrigin, isNotNull);
    expect(fakeSaver.sharePositionOrigin!.isEmpty, isFalse);
    expect(accountBloc.state.exportStatus, AccountActionStatus.success);
  });

  testWidgets('shows the per-category consent toggles', (tester) async {
    await tester.pumpWidget(buildScreen());

    expect(find.text('Usage analytics'), findsOneWidget);
    expect(find.text('Crash reports'), findsOneWidget);
    expect(find.text('Push notifications'), findsOneWidget);
  });

  testWidgets('toggling a consent switch grants that category', (tester) async {
    await tester.pumpWidget(buildScreen());

    final crashSwitch = find.widgetWithText(SwitchListTile, 'Crash reports');
    await tester.ensureVisible(crashSwitch);
    await tester.tap(crashSwitch);
    await tester.pumpAndSettle();

    verify(
      () => mockConsentCubit.setCategory(ConsentCategory.crash, granted: true),
    ).called(1);
  });
}
