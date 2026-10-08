import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/features/library/bloc/library_bloc.dart';
import 'package:picklog/features/library/bloc/library_event.dart';
import 'package:picklog/features/library/bloc/library_state.dart';
import 'package:picklog/features/library/library_entry_model.dart';
import 'package:picklog/features/library/roulette/backlog_roulette_sheet.dart';

import '../../../helpers/pump_app.dart';
import '../../../mocks/mock_blocs.dart';
import '../library_fixtures.dart';

class _FakeEvent extends Fake implements LibraryEvent {}

void main() {
  setUpAll(() => registerFallbackValue(_FakeEvent()));

  late MockLibraryBloc library;
  setUp(() => library = MockLibraryBloc());

  Future<void> open(WidgetTester t, List<LibraryEntry> entries) async {
    t.view.physicalSize = const Size(390, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    when(
      () => library.state,
    ).thenReturn(LibraryState(status: LibraryStatus.success, entries: entries));
    await pumpPicklog(
      t,
      BlocProvider<LibraryBloc>.value(
        value: library,
        child: Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                BacklogRouletteSheet.show(context, random: Random(3)),
            child: const Text('open'),
          ),
        ),
      ),
      reducedMotion: true,
    );
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
  }

  testWidgets('spins over the backlog and starts the pick', (t) async {
    await open(t, [
      entry(id: 'a', name: 'Alpha', status: GameStatus.planned),
      entry(id: 'b', name: 'Beta', status: GameStatus.onHold),
      entry(id: 'c', name: 'Gamma', status: GameStatus.finished),
    ]);

    expect(find.text('2 games in the draw'), findsOneWidget);
    await t.tap(find.byKey(const Key('roulette_spin_button')));
    await t.pumpAndSettle();

    final picked = find.text('Alpha').evaluate().isNotEmpty ? 'a' : 'b';
    expect(find.text('Gamma'), findsNothing);
    expect(find.text('Spin again'), findsOneWidget);

    await t.tap(find.byKey(const Key('roulette_start_button')));
    await t.pumpAndSettle();

    final event =
        verify(() => library.add(captureAny())).captured.single
            as LibraryUpdateEntryRequested;
    expect(event.entryId, picked);
    expect(event.status, GameStatus.playing);
    expect(find.textContaining('Have fun with'), findsOneWidget);
  });

  testWidgets('the hours filter can leave no candidates', (t) async {
    await open(t, [entry(id: 'a', status: GameStatus.planned, playtime: 600)]);
    await t.tap(find.text('Up to 1 h played'));
    await t.pumpAndSettle();
    expect(find.text('No backlog game matches these filters.'), findsOneWidget);
    final spin = t.widget<FilledButton>(
      find.descendant(
        of: find.byKey(const Key('roulette_spin_button')),
        matching: find.byType(FilledButton),
      ),
    );
    expect(spin.onPressed, isNull);
  });

  testWidgets('an empty backlog explains how to fill it', (t) async {
    await open(t, [entry(status: GameStatus.playing)]);
    expect(find.text('Your backlog is empty'), findsOneWidget);
  });
}
