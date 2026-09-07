import 'package:flutter_test/flutter_test.dart';
import 'package:picklog/features/games/search_game_model.dart';

void main() {
  group('SearchGame.fromJson', () {
    test('parses the release timestamp as UTC so the year is zone-stable', () {
      // 2017-01-01T00:00:00Z in epoch seconds. Parsed as local time on a device
      // west of UTC this would yield 2016; parsing as UTC keeps it in 2017.
      final epochSeconds =
          DateTime.utc(2017, 1, 1).millisecondsSinceEpoch ~/ 1000;

      final game = SearchGame.fromJson({
        'id': 1,
        'name': 'New Year Release',
        'first_release_date': epochSeconds,
      });

      expect(game.firstReleaseDate!.isUtc, isTrue);
      expect(game.firstReleaseDate!.toUtc().year, 2017);
    });

    test('leaves the release date null when absent', () {
      final game = SearchGame.fromJson(const {'id': 2, 'name': 'No Date'});
      expect(game.firstReleaseDate, isNull);
    });
  });
}
