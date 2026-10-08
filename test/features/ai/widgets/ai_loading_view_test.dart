import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picklog/features/ai/widgets/ai_loading_view.dart';

import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('shows one status line over the skeleton cards', (tester) async {
    await pumpPicklog(
      tester,
      const SingleChildScrollView(
        child: AiLoadingView(lines: ['Reading your backlog', 'Picking']),
      ),
      reducedMotion: true,
    );

    expect(find.byType(AiPickCardSkeleton), findsNWidgets(3));
    expect(find.text('Reading your backlog'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AiLoadingView),
        matching: find.byType(Icon),
      ),
      findsNothing,
    );
  });
}
