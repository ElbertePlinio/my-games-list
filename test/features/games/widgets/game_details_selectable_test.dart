import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picklog/features/games/bloc/game_details_bloc.dart';
import 'package:picklog/features/games/bloc/game_details_event.dart';
import 'package:picklog/features/games/bloc/game_details_state.dart';
import 'package:picklog/features/games/game_detail_model.dart';
import 'package:picklog/features/games/game_details_screen.dart';
import 'package:picklog/features/library/bloc/library_bloc.dart';
import 'package:picklog/features/library/bloc/library_event.dart';
import 'package:picklog/features/library/bloc/library_state.dart';
import 'package:picklog/l10n/app_localizations.dart';

class MockGameDetailsBloc extends MockBloc<GameDetailsEvent, GameDetailsState>
    implements GameDetailsBloc {}

class MockLibraryBloc extends MockBloc<LibraryEvent, LibraryState>
    implements LibraryBloc {}

void main() {
  late MockGameDetailsBloc gameDetailsBloc;
  late MockLibraryBloc libraryBloc;

  final mockGame = GameDetail.fromJson(const {
    'id': 1942,
    'name': 'The Witcher 3: Wild Hunt',
    'storyline': 'Geralt of Rivia hunts for Ciri across a war-torn continent.',
    'summary':
        'An open-world action RPG with a deep story and meaningful choices.',
  });

  setUp(() {
    gameDetailsBloc = MockGameDetailsBloc();
    libraryBloc = MockLibraryBloc();

    whenListen(
      gameDetailsBloc,
      const Stream<GameDetailsState>.empty(),
      initialState: GameDetailsState(
        status: GameDetailsStatus.success,
        game: mockGame,
      ),
    );
    whenListen(
      libraryBloc,
      const Stream<LibraryState>.empty(),
      initialState: const LibraryState(),
    );
  });

  Widget createScreen() {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: MultiBlocProvider(
        providers: [
          BlocProvider<GameDetailsBloc>.value(value: gameDetailsBloc),
          BlocProvider<LibraryBloc>.value(value: libraryBloc),
        ],
        child: const GameDetailsScreen(gameId: 1942),
      ),
    );
  }

  testWidgets('game description is wrapped in a SelectionArea so web users '
      'can select and copy the storyline/summary', (tester) async {
    await tester.pumpWidget(createScreen());
    await tester.pump();

    expect(find.byType(SelectionArea), findsOneWidget);
    expect(
      find.text('Geralt of Rivia hunts for Ciri across a war-torn continent.'),
      findsOneWidget,
    );
  });
}
