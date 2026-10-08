import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picklog/features/library/library_entry_model.dart';
import 'package:picklog/features/library/widgets/library_entry_actions.dart';
import 'package:picklog/features/library/widgets/library_entry_views.dart';

import '../../../helpers/pump_app.dart';
import '../library_fixtures.dart';

void main() {
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
}
