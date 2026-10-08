import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/core/data/services/storage/local_storage_service.dart';
import 'package:picklog/core/services/consent/consent_category.dart';
import 'package:picklog/core/services/consent/consent_service.dart';
import 'package:picklog/core/services/consent/telemetry_gateway.dart';
import 'package:picklog/core/theme/app_theme.dart';
import 'package:picklog/core/widgets/pf_page_indicator.dart';
import 'package:picklog/features/auth/widgets/auth_layout.dart';
import 'package:picklog/features/consent/bloc/consent_cubit.dart';
import 'package:picklog/features/consent/widgets/consent_banner.dart';
import 'package:picklog/features/onboarding/onboarding_screen.dart';
import 'package:picklog/features/onboarding/onboarding_service.dart';
import 'package:picklog/l10n/app_localizations.dart';

class _MockStorage extends Mock implements LocalStorageService {}

class _MockGateway extends Mock implements TelemetryGateway {}

void main() {
  setUpAll(() => registerFallbackValue(ConsentCategory.crash));

  late _MockStorage storage;
  late ConsentService service;

  setUp(() {
    storage = _MockStorage();
    final gateway = _MockGateway();
    when(() => storage.getBool(any())).thenAnswer((_) async => null);
    when(() => storage.setBool(any(), any())).thenAnswer((_) async => true);
    when(() => storage.remove(any())).thenAnswer((_) async => true);
    when(
      () => gateway.applyConsent(any(), granted: any(named: 'granted')),
    ).thenAnswer((_) async {});
    service = ConsentService(storage: storage, gateway: gateway);
  });

  tearDown(() => service.dispose());

  // The banner is mounted from MaterialApp.router's builder, as in main.dart.
  Future<void> pumpFirstRun(
    WidgetTester tester,
    Widget screen, {
    required Size size,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (_, _) => screen)],
    );
    await tester.pumpWidget(
      BlocProvider<ConsentCubit>(
        create: (_) => ConsentCubit(service),
        child: MaterialApp.router(
          theme: AppTheme.dark(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          routerConfig: router,
          builder: (context, child) =>
              ConsentBanner(child: child ?? const SizedBox.shrink()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  double bannerTop(WidgetTester tester) =>
      tester.getTopLeft(find.byKey(const Key('consent_banner_card'))).dy;

  const sizes = {'wide 1280x800': Size(1280, 800), 'phone': Size(390, 844)};

  for (final MapEntry(key: label, value: size) in sizes.entries) {
    testWidgets('onboarding keeps Next and the dots above the banner '
        '($label)', (tester) async {
      await pumpFirstRun(
        tester,
        OnboardingScreen(
          onboardingService: OnboardingService(storage),
          onCompleted: () {},
        ),
        size: size,
      );

      final top = bannerTop(tester);
      final next = find.widgetWithText(FilledButton, 'Next');
      expect(tester.getBottomLeft(next).dy, lessThanOrEqualTo(top));
      expect(
        tester.getBottomLeft(find.byType(PfPageIndicator)).dy,
        lessThanOrEqualTo(top),
      );

      // Next is tappable while the banner is still up.
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(find.text('Discover what to play next'), findsOneWidget);
    });

    testWidgets('sign-in and sign-up actions scroll clear of the banner '
        '($label)', (tester) async {
      await pumpFirstRun(
        tester,
        AuthLayout(
          eyebrow: 'eyebrow',
          title: 'title',
          subtitle: 'subtitle',
          children: [
            const SizedBox(height: 600),
            FilledButton(onPressed: () {}, child: const Text('submit')),
          ],
        ),
        size: size,
      );

      final submit = find.text('submit');
      await tester.scrollUntilVisible(submit, 200);
      await tester.pumpAndSettle();
      expect(
        tester.getBottomLeft(submit).dy,
        lessThanOrEqualTo(bannerTop(tester)),
      );
    });
  }

  testWidgets('the reserved space goes away once the user chooses', (
    tester,
  ) async {
    await pumpFirstRun(
      tester,
      OnboardingScreen(
        onboardingService: OnboardingService(storage),
        onCompleted: () {},
      ),
      size: const Size(1280, 800),
    );
    final next = find.widgetWithText(FilledButton, 'Next');
    final before = tester.getBottomLeft(next).dy;

    await tester.tap(find.text('Reject all'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('consent_banner_card')), findsNothing);
    expect(tester.getBottomLeft(next).dy, greaterThan(before));
  });
}
