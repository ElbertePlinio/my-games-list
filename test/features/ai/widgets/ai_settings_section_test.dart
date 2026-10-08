import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/features/ai/ai_models.dart';
import 'package:picklog/features/ai/bloc/ai_status_cubit.dart';
import 'package:picklog/features/ai/widgets/ai_settings_section.dart';

import '../../../helpers/stub_router_app.dart';
import '../ai_fixtures.dart';

void main() {
  late MockAiRepository repository;

  setUp(() => repository = MockAiRepository());

  Future<void> pump(WidgetTester tester, AiStatus status) async {
    when(() => repository.getStatus()).thenAnswer((_) async => status);
    final cubit = AiStatusCubit(repository: repository)..load();
    addTearDown(cubit.close);
    await tester.pumpWidget(
      stubRouterApp(
        BlocProvider.value(
          value: cubit,
          child: const Scaffold(body: AiSettingsSection()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the switch on and today\'s usage', (tester) async {
    await pump(tester, kStatusConsented);
    expect(find.text('AI suggestions'.toUpperCase()), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(find.text('3 of 20 used today'), findsOneWidget);
  });

  testWidgets('turning it off revokes consent', (tester) async {
    when(
      () => repository.setConsent(granted: false),
    ).thenAnswer((_) async => const AiConsentResult(consented: false));
    await pump(tester, kStatusConsented);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    verify(() => repository.setConsent(granted: false)).called(1);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    expect(find.text('Nothing is sent to OpenAI.'), findsOneWidget);
  });

  testWidgets('turning it on asks first', (tester) async {
    when(
      () => repository.setConsent(granted: true),
    ).thenAnswer((_) async => const AiConsentResult(consented: true));
    await pump(tester, kStatusNoConsent);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('Turn on AI suggestions?'), findsOneWidget);
    verifyNever(() => repository.setConsent(granted: true));

    await tester.tap(find.text('Turn on'));
    await tester.pumpAndSettle();
    verify(() => repository.setConsent(granted: true)).called(1);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
  });

  testWidgets('disabled AI explains it is unavailable', (tester) async {
    await pump(tester, kStatusDisabled);
    expect(find.byType(Switch), findsNothing);
    expect(
      find.text('AI suggestions are not available on this server.'),
      findsOneWidget,
    );
  });
}
