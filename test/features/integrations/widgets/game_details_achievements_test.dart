import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/features/games/bloc/game_details_bloc.dart';
import 'package:picklog/features/games/bloc/game_details_state.dart';
import 'package:picklog/features/games/game_detail_model.dart';
import 'package:picklog/features/games/game_details_screen.dart';
import 'package:picklog/features/integrations/bloc/achievement_game_cubit.dart';
import 'package:picklog/features/integrations/widgets/game_achievements_section.dart';
import 'package:picklog/features/library/bloc/library_bloc.dart';
import 'package:picklog/features/library/bloc/library_state.dart';

import '../../../helpers/stub_router_app.dart';
import '../../../mocks/mock_blocs.dart';
import '../integrations_fixtures.dart';

const _game = GameDetail(
  id: 113112,
  name: 'Hades',
  summary: 'Defy the god of the dead.',
  screenshots: [],
  videos: [],
  genres: [],
  platforms: [],
  involvedCompanies: [],
  websites: [],
  similarGames: [],
);

void main() {
  testWidgets('game details shows the achievements section with data', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final details = MockGameDetailsBloc();
    final library = MockLibraryBloc();
    when(() => details.state).thenReturn(
      const GameDetailsState(status: GameDetailsStatus.success, game: _game),
    );
    when(() => library.state).thenReturn(const LibraryState());
    final repository = MockIntegrationsRepository();
    when(
      () => repository.getAchievementsForGame(113112),
    ).thenAnswer((_) async => [kHadesAchievements]);
    final achievements = GameAchievementsCubit(repository: repository)
      ..load(113112);
    addTearDown(achievements.close);

    await tester.pumpWidget(
      stubRouterApp(
        MultiBlocProvider(
          providers: [
            BlocProvider<GameDetailsBloc>.value(value: details),
            BlocProvider<LibraryBloc>.value(value: library),
            BlocProvider.value(value: achievements),
          ],
          child: const GameDetailsScreen(gameId: 113112),
        ),
        brightness: Brightness.light,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(GameAchievementsSection), findsOneWidget);
    expect(find.text('Achievements'), findsOneWidget);
    expect(find.text('30 of 49 unlocked'), findsOneWidget);
    expect(find.text('Escaped Tartarus'), findsOneWidget);
  });
}
