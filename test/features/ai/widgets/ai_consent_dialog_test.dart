import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/core/widgets/pf_dialog.dart';
import 'package:picklog/features/ai/ai_models.dart';
import 'package:picklog/features/ai/bloc/ai_status_cubit.dart';
import 'package:picklog/features/ai/widgets/ai_consent_dialog.dart';
import 'package:picklog/features/ai/widgets/ai_feature_gate.dart';

import '../../../helpers/stub_router_app.dart';
import '../ai_fixtures.dart';

void main() {
  late MockAiRepository repository;

  setUp(() => repository = MockAiRepository());

  Future<AiStatusCubit> pumpGate(WidgetTester tester, AiStatus status) async {
    when(() => repository.getStatus()).thenAnswer((_) async => status);
    final cubit = AiStatusCubit(repository: repository)..load();
    addTearDown(cubit.close);
    await tester.pumpWidget(
      stubRouterApp(
        BlocProvider.value(
          value: cubit,
          child: const Scaffold(body: AiFeatureGate(child: Text('ai content'))),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  testWidgets('dialog explains what is sent and what is never sent', (
    tester,
  ) async {
    bool? result;
    await tester.pumpWidget(
      stubRouterApp(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => result = await showPfDialog<bool>(
                context: context,
                builder: (_) => const AiConsentDialog(),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Turn on AI suggestions?'), findsOneWidget);
    expect(
      find.textContaining('sends OpenAI the names, statuses, scores'),
      findsOneWidget,
    );
    expect(
      find.text('Picklog never sends your email or your name.'),
      findsOneWidget,
    );
    expect(find.textContaining('turn this off at any time'), findsOneWidget);

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(result, isFalse);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Turn on'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('gate opens the opt-in on first use and accepting stores it', (
    tester,
  ) async {
    when(
      () => repository.setConsent(granted: true),
    ).thenAnswer((_) async => const AiConsentResult(consented: true));

    await pumpGate(tester, kStatusNoConsent);

    expect(find.text('Turn on AI suggestions?'), findsOneWidget);
    expect(find.text('ai content'), findsNothing);

    await tester.tap(find.text('Turn on'));
    await tester.pumpAndSettle();

    verify(() => repository.setConsent(granted: true)).called(1);
    expect(find.text('ai content'), findsOneWidget);
  });

  testWidgets('declining sends nothing and offers to review again', (
    tester,
  ) async {
    await pumpGate(tester, kStatusNoConsent);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    verifyNever(() => repository.setConsent(granted: any(named: 'granted')));
    expect(find.text('AI suggestions need your OK'), findsOneWidget);

    await tester.tap(find.text('Review and turn on'));
    await tester.pumpAndSettle();
    expect(find.text('Turn on AI suggestions?'), findsOneWidget);
  });

  testWidgets('consented users see the content without a dialog', (
    tester,
  ) async {
    await pumpGate(tester, kStatusConsented);
    expect(find.text('ai content'), findsOneWidget);
    expect(find.byType(AiConsentDialog), findsNothing);
  });

  testWidgets('disabled AI shows the unavailable state', (tester) async {
    await pumpGate(tester, kStatusDisabled);
    expect(find.text('AI suggestions are off'), findsOneWidget);
    expect(find.byType(AiConsentDialog), findsNothing);
  });
}
