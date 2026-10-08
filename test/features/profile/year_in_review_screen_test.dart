import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklog/features/library/stats/library_stats_model.dart';
import 'package:picklog/features/library/stats/stats_cubit.dart';
import 'package:picklog/features/profile/widgets/count_up_text.dart';
import 'package:picklog/features/profile/year_in_review_screen.dart';

import '../../helpers/pump_app.dart';

class _MockStats extends MockCubit<StatsState> implements StatsCubit {}

final _summary = YearSummary(
  added: 24,
  finished: 11,
  playtimeMinutes: 18200,
  byMonth: [
    for (var m = 1; m <= 12; m++) StatsMonth(month: m, added: m, finished: 1),
  ],
  topRated: const [
    StatsYearEntry(libraryEntryId: 'e', igdbId: 1, name: 'Hades', score: 95),
  ],
  firstFinished: const StatsYearEntry(
    libraryEntryId: 'f',
    igdbId: 2,
    name: 'Celeste',
  ),
);

void main() {
  late _MockStats stats;

  setUp(() {
    stats = _MockStats();
    when(() => stats.state).thenReturn(
      StatsState(
        status: StatsStatus.success,
        year: 2026,
        stats: UserStats(
          year: 2026,
          yearSummary: _summary,
          topGenres: const [StatsGenre(id: 12, name: 'RPG', count: 9)],
        ),
      ),
    );
    when(() => stats.load(year: any(named: 'year'))).thenAnswer((_) async {});
  });

  Future<void> pump(
    WidgetTester t, {
    bool reducedMotion = false,
    YearShareHandler? onShare,
  }) async {
    t.view.physicalSize = const Size(390, 4000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await pumpPicklog(
      t,
      BlocProvider<StatsCubit>.value(
        value: stats,
        child: YearInReviewScreen(
          year: 2026,
          now: DateTime(2026, 10, 8),
          onShare: onShare,
        ),
      ),
      reducedMotion: reducedMotion,
      wrapInScaffold: false,
    );
  }

  testWidgets('counts up over 1600ms', (t) async {
    await pump(t);
    final added = find.descendant(
      of: find.byKey(const Key('year_added_count')),
      matching: find.byType(Text),
    );
    await t.pump(const Duration(milliseconds: 100));
    final early = int.parse(t.widget<Text>(added).data!);
    expect(early, lessThan(24));
    await t.pump(CountUpText.defaultDuration);
    expect(t.widget<Text>(added).data, '24');
  });

  testWidgets('reduced motion shows the final numbers at once', (t) async {
    await pump(t, reducedMotion: true);
    await t.pump();
    expect(find.text('24'), findsWidgets);
    expect(find.text('11'), findsWidgets);
    expect(find.text('303'), findsWidgets);
  });

  testWidgets('renders the story cards', (t) async {
    await pump(t, reducedMotion: true);
    await t.pump();
    expect(find.text('2026 in review'), findsOneWidget);
    expect(find.text('MONTH BY MONTH'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.label ==
                'Chart by month: 24 added and 11 finished in total',
      ),
      findsOneWidget,
    );
    expect(find.text('Hades'), findsOneWidget);
    expect(find.text('Celeste'), findsOneWidget);
    expect(find.text('RPG · 9'), findsOneWidget);
    expect(find.byType(YearShareCard), findsOneWidget);
  });

  testWidgets('the year picker loads another year', (t) async {
    await pump(t, reducedMotion: true);
    await t.tap(find.byKey(const Key('year_picker')));
    await t.pumpAndSettle();
    await t.tap(find.text('2024').last);
    await t.pumpAndSettle();
    verify(() => stats.load(year: 2024)).called(1);
    expect(find.text('2024 in review'), findsOneWidget);
  });

  testWidgets('share renders the summary card to a PNG', (t) async {
    Uint8List? png;
    String? name;
    await pump(
      t,
      reducedMotion: true,
      onShare: (bytes, fileName, text) async {
        png = bytes;
        name = fileName;
      },
    );
    await t.pump();
    await t.runAsync(() async {
      await t.tap(find.byKey(const Key('year_share_card_button')));
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await t.pump();
    expect(name, 'picklog-2026.png');
    expect(png, isNotNull);
    // PNG signature.
    expect(png!.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
  });

  testWidgets('a failure without data offers a retry', (t) async {
    when(
      () => stats.state,
    ).thenReturn(const StatsState(status: StatsStatus.failure, year: 2026));
    await pump(t, reducedMotion: true);
    await t.tap(find.text('Try again'));
    verify(() => stats.load(year: 2026)).called(1);
  });

  test('the picker offers the last ten years', () {
    expect(yearInReviewYears(2026).first, 2026);
    expect(yearInReviewYears(2026).last, 2017);
  });
}
