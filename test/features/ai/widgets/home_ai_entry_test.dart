import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/features/ai/ai_models.dart';
import 'package:picklog/features/ai/ai_repository.dart';
import 'package:picklog/features/ai/bloc/ai_status_cubit.dart';
import 'package:picklog/features/ai/widgets/home_ai_entry.dart';

import '../../../helpers/stub_router_app.dart';
import '../ai_fixtures.dart';

void main() {
  late MockAiRepository repository;

  setUp(() => repository = MockAiRepository());

  Future<void> pump(WidgetTester tester, {AiStatus? status}) async {
    if (status == null) {
      when(
        () => repository.getStatus(),
      ).thenThrow(const AiException(AiErrorKind.network));
    } else {
      when(() => repository.getStatus()).thenAnswer((_) async => status);
    }
    final cubit = AiStatusCubit(repository: repository)..load();
    addTearDown(cubit.close);
    await tester.pumpWidget(
      stubRouterApp(
        BlocProvider.value(
          value: cubit,
          child: const Scaffold(
            body: SingleChildScrollView(child: HomeAiEntry()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows both entries when AI is enabled', (tester) async {
    await pump(tester, status: kStatusNoConsent);
    expect(find.text('What should I play tonight?'), findsOneWidget);
    expect(find.text('Discover with AI'), findsOneWidget);
  });

  testWidgets('hides both entries when AI is disabled', (tester) async {
    await pump(tester, status: kStatusDisabled);
    expect(find.text('What should I play tonight?'), findsNothing);
    expect(find.text('Discover with AI'), findsNothing);
  });

  testWidgets('hides both entries when the status fails to load', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('What should I play tonight?'), findsNothing);
  });

  testWidgets('renders nothing without an AiStatusCubit', (tester) async {
    await tester.pumpWidget(stubRouterApp(const Scaffold(body: HomeAiEntry())));
    expect(find.text('What should I play tonight?'), findsNothing);
  });

  testWidgets('the card opens Play next and the row opens Discover', (
    tester,
  ) async {
    await pump(tester, status: kStatusConsented);
    await tester.tap(find.text('Pick for me'));
    await tester.pumpAndSettle();
    expect(find.textContaining('route:aiPlayNext'), findsOneWidget);
  });

  testWidgets('the discover row opens Discover', (tester) async {
    await pump(tester, status: kStatusConsented);
    await tester.tap(find.text('Discover with AI'));
    await tester.pumpAndSettle();
    expect(find.textContaining('route:aiDiscover'), findsOneWidget);
  });
}
