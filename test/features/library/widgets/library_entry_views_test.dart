import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/core/domain/models/app_failure.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/features/library/bloc/library_bloc.dart';
import 'package:picklog/features/library/bloc/library_event.dart';
import 'package:picklog/features/library/bloc/library_state.dart';
import 'package:picklog/features/library/library_entry_model.dart';
import 'package:picklog/features/library/widgets/library_entry_actions.dart';
import 'package:picklog/features/library/widgets/library_entry_views.dart';

import '../../../helpers/pump_app.dart';
import '../../../mocks/mock_blocs.dart';
import '../library_fixtures.dart';

class _FakeLibraryEvent extends Fake implements LibraryEvent {}

void main() {
  setUpAll(() => registerFallbackValue(_FakeLibraryEvent()));

  final favorite = entry(
    status: GameStatus.playing,
    score: 85,
    playtime: 150,
    favorite: true,
  );

  testWidgets('a list row reads its visible metadata', (t) async {
    final handle = t.ensureSemantics();
    await pumpPicklog(
      t,
      LibraryEntryRow(entry: favorite, heroPrefix: 'test-', swipeable: false),
    );

    expect(
      find.bySemanticsLabel(
        'Hollow Knight, Playing, score 85, P6, 2.5 h, Favorited',
      ),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('a grid card reads its visible metadata', (t) async {
    final handle = t.ensureSemantics();
    await pumpPicklog(
      t,
      Center(
        child: SizedBox(
          width: 180,
          height: 320,
          child: LibraryEntryGridCard(entry: favorite, heroPrefix: 'test-'),
        ),
      ),
    );

    expect(
      find.bySemanticsLabel('Hollow Knight, Playing, score 85, Favorited'),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('the grid favorite heart is neutral, not ember', (t) async {
    await pumpPicklog(
      t,
      Center(
        child: SizedBox(
          width: 180,
          height: 320,
          child: LibraryEntryGridCard(entry: favorite, heroPrefix: 'test-'),
        ),
      ),
    );

    final heart = t.widget<Icon>(find.byIcon(Icons.favorite));
    expect(heart.color, PicklogColors.onImage);
  });

  testWidgets('the grid menu is at least 44 px', (t) async {
    await pumpPicklog(
      t,
      Center(
        child: SizedBox(
          width: 180,
          height: 320,
          child: LibraryEntryGridCard(entry: favorite, heroPrefix: 'test-'),
        ),
      ),
    );

    final size = t.getSize(find.byType(LibraryEntryMenuButton));
    expect(size.width, greaterThanOrEqualTo(44));
    expect(size.height, greaterThanOrEqualTo(44));
  });

  group('editing', () {
    late MockLibraryBloc library;

    setUp(() {
      library = MockLibraryBloc();
      when(() => library.state).thenReturn(LibraryState(entries: [favorite]));
    });

    tearDown(() => library.close());

    Future<void> pumpRow(WidgetTester t) {
      // Tall enough for the whole status list.
      t.view.physicalSize = const Size(800, 1400);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      return pumpPicklog(
        t,
        BlocProvider<LibraryBloc>.value(
          value: library,
          child: LibraryEntryRow(
            entry: favorite,
            heroPrefix: 'test-',
            swipeable: false,
          ),
        ),
      );
    }

    Future<void> pickStatus(WidgetTester t, String status) async {
      await t.tap(find.byType(LibraryEntryMenuButton));
      await t.pumpAndSettle();
      await t.tap(find.text('Change status'));
      await t.pumpAndSettle();
      await t.tap(find.text(status).last);
      await t.pumpAndSettle();
    }

    testWidgets('the row pencil opens the edit sheet', (t) async {
      await pumpRow(t);

      await t.tap(find.byTooltip('Edit entry'));
      await t.pumpAndSettle();

      expect(find.text('Edit entry'), findsWidgets);
      expect(find.text('Remove from library'), findsOneWidget);
    });

    testWidgets('the grid card has a pencil too', (t) async {
      await pumpPicklog(
        t,
        BlocProvider<LibraryBloc>.value(
          value: library,
          child: Center(
            child: SizedBox(
              width: 180,
              height: 320,
              child: LibraryEntryGridCard(entry: favorite, heroPrefix: 'test-'),
            ),
          ),
        ),
      );

      await t.tap(find.byTooltip('Edit entry'));
      await t.pumpAndSettle();

      expect(find.text('Remove from library'), findsOneWidget);
    });

    testWidgets('picking Finished opens the sheet and saves with it', (
      t,
    ) async {
      await pumpRow(t);
      await pickStatus(t, 'Finished');

      expect(find.text('Remove from library'), findsOneWidget);
      verifyNever(() => library.add(any()));

      await t.tap(find.text('Save'));
      await t.pump();

      final event =
          verify(() => library.add(captureAny())).captured.single
              as LibraryUpdateEntryRequested;
      expect(event.status, GameStatus.finished);
      final today = DateTime.now();
      expect(
        event.details?.endDate,
        DateTime(today.year, today.month, today.day),
      );
    });

    testWidgets('closing the sheet after Finished still saves the status', (
      t,
    ) async {
      await pumpRow(t);
      await pickStatus(t, 'Finished');

      await t.tap(find.byTooltip('Cancel'));
      await t.pumpAndSettle();

      final event =
          verify(() => library.add(captureAny())).captured.single
              as LibraryUpdateEntryRequested;
      expect(event.status, GameStatus.finished);
      expect(event.details, isNull);
    });

    testWidgets('picking On hold saves without the sheet', (t) async {
      await pumpRow(t);
      await pickStatus(t, 'On hold');

      expect(find.text('Remove from library'), findsNothing);
      final event =
          verify(() => library.add(captureAny())).captured.single
              as LibraryUpdateEntryRequested;
      expect(event.status, GameStatus.onHold);
    });

    testWidgets('picking Dropped opens the sheet too', (t) async {
      await pumpRow(t);
      await pickStatus(t, 'Dropped');

      expect(find.text('Remove from library'), findsOneWidget);
      verifyNever(() => library.add(any()));
    });

    testWidgets('closing the sheet while its save runs sends no second write', (
      t,
    ) async {
      await pumpRow(t);
      await pickStatus(t, 'Finished');

      await t.tap(find.text('Save'));
      await t.pump();
      await t.tap(find.byTooltip('Cancel'));
      await t.pumpAndSettle();

      final events = verify(() => library.add(captureAny())).captured;
      expect(events, hasLength(1));
      expect((events.single as LibraryUpdateEntryRequested).details, isNotNull);
    });

    testWidgets('closing after a failed save still applies the status', (
      t,
    ) async {
      final states = StreamController<LibraryState>();
      addTearDown(states.close);
      whenListen(
        library,
        states.stream,
        initialState: LibraryState(entries: [favorite]),
      );
      await pumpRow(t);
      await pickStatus(t, 'Finished');

      await t.tap(find.text('Save'));
      final save =
          verify(() => library.add(captureAny())).captured.single
              as LibraryUpdateEntryRequested;
      states.add(
        LibraryState(
          entries: [favorite],
          failure: LibraryFailure(
            LibraryAction.update,
            AppErrorKind.network,
            requestId: save.requestId,
          ),
        ),
      );
      await t.pump();
      await t.tap(find.byTooltip('Cancel'));
      await t.pumpAndSettle();

      final fallback =
          verify(() => library.add(captureAny())).captured.single
              as LibraryUpdateEntryRequested;
      expect(fallback.status, GameStatus.finished);
      expect(fallback.details, isNull);
    });
  });
}
