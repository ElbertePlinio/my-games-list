import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/core/data/services/storage/local_storage_service.dart';
import 'package:picklog/core/services/consent/consent_category.dart';
import 'package:picklog/core/services/consent/consent_service.dart';
import 'package:picklog/core/services/consent/telemetry_gateway.dart';
import 'package:picklog/features/consent/bloc/consent_cubit.dart';
import 'package:picklog/features/consent/widgets/consent_banner.dart';
import 'package:picklog/l10n/app_localizations.dart';

class _MockStorage extends Mock implements LocalStorageService {}

class _MockGateway extends Mock implements TelemetryGateway {}

void main() {
  setUpAll(() {
    registerFallbackValue(ConsentCategory.crash);
  });

  late _MockStorage storage;
  late _MockGateway gateway;
  late ConsentService service;

  setUp(() {
    storage = _MockStorage();
    gateway = _MockGateway();
    when(() => storage.getBool(any())).thenAnswer((_) async => null);
    when(() => storage.setBool(any(), any())).thenAnswer((_) async => true);
    when(() => storage.remove(any())).thenAnswer((_) async => true);
    when(
      () => gateway.applyConsent(any(), granted: any(named: 'granted')),
    ).thenAnswer((_) async {});
    service = ConsentService(storage: storage, gateway: gateway);
  });

  tearDown(() => service.dispose());

  // Mirrors production: the banner is mounted from MaterialApp.router's
  // builder, ABOVE the Router's Navigator. This is the placement that exposes
  // the "Customize" Navigator-lookup bug — a banner under MaterialApp.home
  // would have a Navigator in its own context and hide it.
  //
  // The cubit is created inside BlocProvider.create so it lives in the test's
  // async zone — a cubit built in setUp schedules its stream-driven emits on
  // the wrong zone and the BlocBuilder never rebuilds under the fake clock.
  Widget buildApp() {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) =>
              const Scaffold(body: Center(child: Text('app body'))),
        ),
      ],
    );

    return BlocProvider<ConsentCubit>(
      create: (_) => ConsentCubit(service),
      child: MaterialApp.router(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
        builder: (context, child) =>
            ConsentBanner(child: child ?? const SizedBox.shrink()),
      ),
    );
  }

  testWidgets('shows the banner when consent is unanswered', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Your privacy choices'), findsOneWidget);
    expect(find.text('Accept all'), findsOneWidget);
    expect(find.text('Reject all'), findsOneWidget);
    expect(find.text('Customize'), findsOneWidget);
    // App content stays usable behind the non-modal banner.
    expect(find.text('app body'), findsOneWidget);
  });

  testWidgets('accept all grants every category and hides the banner', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Accept all'));
    await tester.pumpAndSettle();

    expect(find.text('Your privacy choices'), findsNothing);
    expect(service.hasAnswered, isTrue);
    for (final category in ConsentCategory.values) {
      expect(service.isGranted(category), isTrue);
    }
  });

  testWidgets('reject all denies every category and hides the banner', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reject all'));
    await tester.pumpAndSettle();

    expect(find.text('Your privacy choices'), findsNothing);
    expect(service.hasAnswered, isTrue);
    for (final category in ConsentCategory.values) {
      expect(service.isGranted(category), isFalse);
    }
  });

  testWidgets('opens the customize sheet under MaterialApp.router', (
    tester,
  ) async {
    // Reproduces the production placement: the banner is mounted ABOVE the
    // Router's Navigator, so opening the sheet on the banner's own context
    // would fail its Navigator.of lookup. The sheet must still open.
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Customize'));
    await tester.pumpAndSettle();

    expect(find.text('Choose what you allow'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('customize sheet applies per-category choices', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Customize'));
    await tester.pumpAndSettle();

    // Sheet shows a switch per category; enable crash reporting only.
    expect(find.text('Choose what you allow'), findsOneWidget);
    await tester.tap(find.widgetWithText(SwitchListTile, 'Crash reports'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Your privacy choices'), findsNothing);
    expect(service.isGranted(ConsentCategory.crash), isTrue);
    expect(service.isGranted(ConsentCategory.analytics), isFalse);
    expect(service.hasAnswered, isTrue);
  });

  testWidgets('disables actions while a choice is saving so a second tap is '
      'ignored', (tester) async {
    // Hold the first write open so the save stays in flight while we tap again.
    final gate = Completer<void>();
    when(
      () => gateway.applyConsent(any(), granted: any(named: 'granted')),
    ).thenAnswer((_) => gate.future);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Start "Accept all"; it stalls on the gated gateway write.
    await tester.tap(find.text('Accept all'));
    await tester.pump();

    // All three actions are disabled while the save is in flight.
    expect(
      tester
          .widget<FilledButton>(
            find.ancestor(
              of: find.text('Accept all'),
              matching: find.byType(FilledButton),
            ),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.ancestor(
              of: find.text('Reject all'),
              matching: find.byType(FilledButton),
            ),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<TextButton>(
            find.ancestor(
              of: find.text('Customize'),
              matching: find.byType(TextButton),
            ),
          )
          .onPressed,
      isNull,
    );

    // A second tap on the opposite action is a no-op while saving.
    await tester.tap(find.text('Reject all'), warnIfMissed: false);
    await tester.pump();

    // Let the original Accept write finish.
    gate.complete();
    await tester.pumpAndSettle();

    // Accept won; the Reject tap during the save never ran.
    expect(find.text('Your privacy choices'), findsNothing);
    expect(service.hasAnswered, isTrue);
    for (final category in ConsentCategory.values) {
      expect(service.isGranted(category), isTrue);
    }
  });

  testWidgets('banner does not show once consent is already answered', (
    tester,
  ) async {
    when(
      () => storage.getBool(ConsentService.answeredStorageKey),
    ).thenAnswer((_) async => true);
    await service.load();

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Your privacy choices'), findsNothing);
  });
}
