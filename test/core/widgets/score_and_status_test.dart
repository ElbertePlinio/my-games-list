import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/widgets/score_badge.dart';
import 'package:picklog/core/widgets/status_pill.dart';
import 'package:picklog/features/library/library_entry_model.dart';
import 'package:picklog/features/library/widgets/library_status_pill.dart';

import '../../helpers/pump_app.dart';

Color _textColor(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style!.color!;

void main() {
  group('scoreTone', () {
    test('uses 75 and 50 as the tone boundaries', () {
      expect(scoreTone(100), PfTone.connected);
      expect(scoreTone(75), PfTone.connected);
      expect(scoreTone(74), PfTone.warning);
      expect(scoreTone(50), PfTone.warning);
      expect(scoreTone(49), PfTone.error);
      expect(scoreTone(0), PfTone.error);
    });

    test('normalizeScore rounds and clamps to an integer 0-100', () {
      expect(normalizeScore(null), isNull);
      expect(normalizeScore(92.82), 93);
      expect(normalizeScore(-3), 0);
      expect(normalizeScore(140), 100);
    });
  });

  group('ScoreBadge', () {
    testWidgets('renders nothing for a null score', (tester) async {
      await pumpPicklog(tester, const ScoreBadge(score: null));
      expect(find.byType(Text), findsNothing);
    });

    for (final (score, tone) in [
      (88, PfTone.connected),
      (60, PfTone.warning),
      (30, PfTone.error),
    ]) {
      testWidgets('shows $score in the $tone foreground', (tester) async {
        await pumpPicklog(
          tester,
          ScoreBadge(score: score),
          brightness: Brightness.light,
        );
        expect(find.text('$score'), findsOneWidget);
        expect(
          _textColor(tester, '$score'),
          PicklogColors.light.toneForeground(tone),
        );
      });
    }

    testWidgets('on images it uses the dark palette in light mode', (
      tester,
    ) async {
      await pumpPicklog(
        tester,
        const ScoreBadge(score: 90, onImage: true),
        brightness: Brightness.light,
      );
      expect(_textColor(tester, '90'), PicklogColors.dark.connectedFg);
    });

    testWidgets('exposes a semantics label', (tester) async {
      await pumpPicklog(
        tester,
        const ScoreBadge(score: 77, semanticLabel: 'Rating 77'),
      );
      expect(find.bySemanticsLabel('Rating 77'), findsOneWidget);
    });
  });

  group('ScoreRing', () {
    testWidgets('shows the number, or a dash when unset', (tester) async {
      await pumpPicklog(
        tester,
        const Column(children: [ScoreRing(score: 81), ScoreRing(score: null)]),
      );
      expect(find.text('81'), findsOneWidget);
      expect(find.text('-'), findsOneWidget);
    });
  });

  group('StatusPill', () {
    testWidgets('renders the label in the tone foreground', (tester) async {
      await pumpPicklog(
        tester,
        const StatusPill(label: 'Live', tone: PfTone.info),
      );
      expect(_textColor(tester, 'Live'), PicklogColors.dark.infoFg);
    });

    testWidgets('library statuses map to distinct tones and icons', (
      tester,
    ) async {
      expect(GameStatus.playing.tone, PfTone.connected);
      expect(GameStatus.finished.tone, PfTone.info);
      expect(GameStatus.onHold.tone, PfTone.warning);
      expect(GameStatus.dropped.tone, PfTone.error);
      expect(GameStatus.planned.tone, PfTone.neutral);
      expect(
        GameStatus.values.map((s) => s.icon).toSet(),
        hasLength(GameStatus.values.length),
      );

      await pumpPicklog(
        tester,
        const LibraryStatusPill(status: GameStatus.dropped),
        brightness: Brightness.light,
      );
      expect(find.text('Dropped'), findsOneWidget);
      expect(_textColor(tester, 'Dropped'), PicklogColors.light.errorFg);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });
  });
}
