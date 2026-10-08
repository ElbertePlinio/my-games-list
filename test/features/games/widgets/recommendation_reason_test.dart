import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picklog/features/games/discovery_game_model.dart';
import 'package:picklog/features/games/widgets/recommendations_widget.dart';

import '../../../helpers/pump_app.dart';

void main() {
  Future<void> pumpReason(
    WidgetTester t,
    RecommendationReason? reason, {
    Locale locale = const Locale('en'),
  }) => pumpPicklog(
    t,
    SizedBox(width: 132, child: RecommendationReasonLine(reason: reason)),
    locale: locale,
  );

  testWidgets('shows each localized reason', (t) async {
    await pumpReason(
      t,
      const RecommendationReason(
        type: RecommendationReasonType.similar,
        sourceGameName: 'Hades',
      ),
    );
    expect(find.text('Because you liked Hades'), findsOneWidget);

    await pumpReason(
      t,
      const RecommendationReason(
        type: RecommendationReasonType.genre,
        genreName: 'RPG',
      ),
    );
    expect(find.text('More RPG'), findsOneWidget);

    await pumpReason(
      t,
      const RecommendationReason(type: RecommendationReasonType.popular),
    );
    expect(find.text('Popular now'), findsOneWidget);
  });

  testWidgets('falls back when names are missing and localizes pt-BR', (
    t,
  ) async {
    await pumpReason(
      t,
      const RecommendationReason(type: RecommendationReasonType.similar),
    );
    expect(find.text('Similar to games you like'), findsOneWidget);

    await pumpReason(
      t,
      const RecommendationReason(
        type: RecommendationReasonType.genre,
        genreName: 'RPG',
      ),
      locale: const Locale('pt'),
    );
    expect(find.text('Mais RPG'), findsOneWidget);
  });

  testWidgets('a missing reason keeps the row height', (t) async {
    await pumpReason(t, null);
    expect(t.getSize(find.byType(RecommendationReasonLine)).height, 22);
  });
}
