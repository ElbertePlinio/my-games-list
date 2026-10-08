import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:picklog/features/library/library_entry_model.dart';
import 'package:picklog/features/library/roulette/roulette_cubit.dart';

import '../library_fixtures.dart';

final _library = [
  entry(id: 'p1', status: GameStatus.planned, platformId: 6),
  entry(id: 'p2', status: GameStatus.planned, platformId: 167, playtime: 600),
  entry(id: 'h1', status: GameStatus.onHold, platformId: 6, playtime: 30),
  entry(id: 'x1', status: GameStatus.playing, platformId: 6),
  entry(id: 'x2', status: GameStatus.finished, platformId: 6),
];

void main() {
  test('the backlog is planned and on-hold entries only', () {
    final cubit = RouletteCubit(library: _library);
    expect(cubit.state.backlog.map((e) => e.id), ['p1', 'p2', 'h1']);
    expect(cubit.state.platforms.map((p) => p.igdbPlatformId), {6, 167});
  });

  test('spin picks a candidate and never repeats when others exist', () {
    final cubit = RouletteCubit(library: _library, random: Random(1));
    final first = cubit.spin();
    expect(first, isNotNull);
    for (var i = 0; i < 20; i++) {
      final previous = cubit.state.picked!.id;
      final next = cubit.spin()!;
      expect(next.id, isNot(previous));
      expect(['p1', 'p2', 'h1'], contains(next.id));
    }
    expect(cubit.state.spins, 21);
  });

  test('platform and hours filters narrow the candidates', () {
    final cubit = RouletteCubit(library: _library)..setPlatform(6);
    expect(cubit.state.candidates.map((e) => e.id), ['p1', 'h1']);
    cubit.setMaxHoursPlayed(0);
    expect(cubit.state.candidates.map((e) => e.id), ['p1']);
    cubit
      ..setPlatform(null)
      ..setMaxHoursPlayed(10);
    expect(cubit.state.candidates.map((e) => e.id), ['p1', 'p2', 'h1']);
  });

  test('a filter that excludes the pick clears it', () {
    final cubit = RouletteCubit(library: [_library[1]])..spin();
    expect(cubit.state.picked?.id, 'p2');
    cubit.setPlatform(6);
    expect(cubit.state.picked, isNull);
    expect(cubit.spin(), isNull);
  });
}
