import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/core/domain/models/app_failure.dart';
import 'package:picklog/features/browse/bloc/browse_genre_games_bloc.dart';
import 'package:picklog/features/browse/bloc/browse_genre_games_event.dart';
import 'package:picklog/features/browse/bloc/browse_genre_games_state.dart';
import 'package:picklog/features/browse/browse_genre_games_screen.dart';
import 'package:picklog/features/games/discovery_game_model.dart';
import 'package:picklog/features/games/widgets/discovery_game_tile.dart';

import '../../helpers/pump_app.dart';

class _MockBloc extends MockBloc<BrowseGenreGamesEvent, BrowseGenreGamesState>
    implements BrowseGenreGamesBloc {}

void main() {
  late _MockBloc bloc;

  setUp(() => bloc = _MockBloc());

  List<DiscoveryGame> games(int n) => [
    for (var i = 0; i < n; i++) DiscoveryGame(id: i, name: 'Game $i'),
  ];

  Future<void> pump(WidgetTester tester, {double width = 390}) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpPicklog(
      tester,
      BlocProvider<BrowseGenreGamesBloc>.value(
        value: bloc,
        child: const BrowseGenreGamesScreen(genreId: 12, genreName: 'RPG'),
      ),
      wrapInScaffold: false,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('loads the next page near the end of the grid', (tester) async {
    when(() => bloc.state).thenReturn(
      BrowseGenreGamesState(
        status: BrowseGenreGamesStatus.success,
        games: games(40),
        genreId: 12,
        hasMore: true,
        nextOffset: 40,
      ),
    );
    await pump(tester);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -8000));
    await tester.pump();

    verify(
      () => bloc.add(const BrowseGenreGamesLoadMore()),
    ).called(greaterThan(0));
  });

  testWidgets('uses more columns on wide screens', (tester) async {
    when(() => bloc.state).thenReturn(
      BrowseGenreGamesState(
        status: BrowseGenreGamesStatus.success,
        games: games(12),
        genreId: 12,
      ),
    );
    await pump(tester, width: 1280);

    final first = tester.getTopLeft(find.byType(DiscoveryGameTile).at(0));
    final sixth = tester.getTopLeft(find.byType(DiscoveryGameTile).at(5));
    // Six columns: the sixth card sits on the first row.
    expect(sixth.dy, first.dy);
  });

  testWidgets('a failed page shows an inline retry', (tester) async {
    when(() => bloc.state).thenReturn(
      BrowseGenreGamesState(
        status: BrowseGenreGamesStatus.success,
        games: games(4),
        genreId: 12,
        hasMore: true,
        nextOffset: 40,
        errorKind: AppErrorKind.network,
      ),
    );
    await pump(tester);

    await tester.scrollUntilVisible(find.text('Try again'), 300);
    await tester.tap(find.text('Try again'));
    verify(() => bloc.add(const BrowseGenreGamesLoadMore())).called(1);
  });
}
