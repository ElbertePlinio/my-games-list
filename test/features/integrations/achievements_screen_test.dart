import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/features/integrations/achievement_game_screen.dart';
import 'package:picklog/features/integrations/achievements_screen.dart';
import 'package:picklog/features/integrations/bloc/achievement_game_cubit.dart';
import 'package:picklog/features/integrations/bloc/achievements_cubit.dart';
import 'package:picklog/features/integrations/integrations_models.dart';
import 'package:picklog/features/integrations/widgets/achievement_widgets.dart';

import '../../helpers/stub_router_app.dart';
import 'integrations_fixtures.dart';

void main() {
  late MockIntegrationsRepository repository;

  setUp(() => repository = MockIntegrationsRepository());

  Future<void> pumpHub(WidgetTester tester, AchievementSummary summary) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    when(() => repository.getSummary()).thenAnswer((_) async => summary);
    final cubit = AchievementsCubit(repository: repository)..load();
    addTearDown(cubit.close);
    await tester.pumpWidget(
      stubRouterApp(
        BlocProvider.value(value: cubit, child: const AchievementsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('hub shows the ring, totals, recent unlocks and games', (
    tester,
  ) async {
    await pumpHub(tester, kSummary);

    expect(find.byType(CompletionRing), findsOneWidget);
    expect(find.text('34%'), findsOneWidget);
    expect(find.text('55 of 164 unlocked'), findsOneWidget);
    expect(find.text('Steam · 2 games'), findsOneWidget);
    expect(find.text('Xbox · 1 game'), findsOneWidget);
    expect(find.text('Escaped Tartarus'), findsOneWidget);
    expect(find.textContaining('Rare'), findsOneWidget);

    final names = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byType(GameProgressTile),
            matching: find.byType(Text),
          ),
        )
        .map((t) => t.data)
        .where((d) => ['Hades', 'Halo Infinite', 'Portal'].contains(d))
        .toList();
    expect(names, ['Hades', 'Halo Infinite', 'Portal']);
  });

  testWidgets('the provider filter narrows the games list', (tester) async {
    await pumpHub(tester, kSummary);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Xbox'));
    await tester.pumpAndSettle();

    expect(find.byType(GameProgressTile), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(GameProgressTile),
        matching: find.text('Halo Infinite'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('tapping a game opens the per-game screen', (tester) async {
    await pumpHub(tester, kSummary);
    await tester.tap(find.byType(GameProgressTile).first);
    await tester.pumpAndSettle();
    expect(find.text('route:achievementGame steam/1145360'), findsOneWidget);
  });

  testWidgets('an empty summary sends users to connected accounts', (
    tester,
  ) async {
    await pumpHub(
      tester,
      const AchievementSummary(
        totalUnlocked: 0,
        totalAvailable: 0,
        completionPct: 0,
        byProvider: [],
        recent: [],
        games: [],
      ),
    );

    expect(find.text('No achievements yet'), findsOneWidget);
    await tester.tap(find.text('Connect an account'));
    await tester.pumpAndSettle();
    expect(find.textContaining('route:connectedAccounts'), findsOneWidget);
  });

  testWidgets('per-game screen lists unlocked first and dims locked ones', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    when(
      () => repository.getGameAchievements(GameProvider.steam, '1145360'),
    ).thenAnswer((_) async => kHadesAchievements);
    final cubit = AchievementGameCubit(
      repository: repository,
      provider: GameProvider.steam,
      externalGameId: '1145360',
    )..load();
    addTearDown(cubit.close);
    await tester.pumpWidget(
      stubRouterApp(
        BlocProvider.value(value: cubit, child: const AchievementGameScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('30 of 49 unlocked'), findsOneWidget);
    final tiles = tester
        .widgetList<AchievementTile>(find.byType(AchievementTile))
        .toList();
    expect(tiles.map((t) => t.name), [
      'Escaped Tartarus',
      'First Steps',
      'Locked One',
    ]);
    expect(find.text('Unlocked Oct 5, 2026'), findsOneWidget);
    expect(find.text('Locked'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text('Locked One'),
        matching: find.byType(Opacity),
      ),
      findsWidgets,
    );
    expect(find.text('80% of players'), findsOneWidget);
  });
}
