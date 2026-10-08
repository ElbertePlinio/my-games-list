import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/features/integrations/bloc/achievement_game_cubit.dart';
import 'package:picklog/features/integrations/integrations_models.dart';
import 'package:picklog/features/integrations/widgets/achievement_widgets.dart';
import 'package:picklog/features/integrations/widgets/game_achievements_section.dart';

import '../../../helpers/stub_router_app.dart';
import '../integrations_fixtures.dart';

void main() {
  late MockIntegrationsRepository repository;

  setUp(() => repository = MockIntegrationsRepository());

  Future<void> pump(WidgetTester tester, List<GameAchievements> games) async {
    when(
      () => repository.getAchievementsForGame(113112),
    ).thenAnswer((_) async => games);
    final cubit = GameAchievementsCubit(repository: repository)..load(113112);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      stubRouterApp(
        BlocProvider.value(
          value: cubit,
          child: const Scaffold(
            body: SingleChildScrollView(child: GameAchievementsSection()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows progress and the first achievements', (tester) async {
    final many = GameAchievements(
      game: kGameHades,
      achievements: [
        for (var i = 0; i < 6; i++)
          Achievement(id: '$i', name: 'Achievement $i', unlocked: i.isEven),
      ],
    );
    await pump(tester, [many]);

    expect(find.text('Achievements'), findsOneWidget);
    expect(find.text('30 of 49 unlocked'), findsOneWidget);
    expect(find.byType(AchievementProgressBar), findsOneWidget);
    expect(
      find.byType(AchievementTile),
      findsNWidgets(kDetailsAchievementPreview),
    );

    await tester.tap(find.text('See all'));
    await tester.pumpAndSettle();
    expect(find.text('route:achievementGame steam/1145360'), findsOneWidget);
  });

  testWidgets('is hidden when the user has no data for the game', (
    tester,
  ) async {
    await pump(tester, const []);
    expect(find.text('Achievements'), findsNothing);
  });

  testWidgets('is hidden without a cubit', (tester) async {
    await tester.pumpWidget(
      stubRouterApp(const Scaffold(body: GameAchievementsSection())),
    );
    expect(find.text('Achievements'), findsNothing);
  });
}
