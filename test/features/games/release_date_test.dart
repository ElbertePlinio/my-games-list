import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picklog/features/ai/ai_models.dart';
import 'package:picklog/features/games/discovery_game_model.dart';
import 'package:picklog/features/games/game_detail_model.dart';
import 'package:picklog/features/games/release_date.dart';
import 'package:picklog/features/games/search_game_model.dart';
import 'package:picklog/features/games/widgets/game_search_card.dart';
import 'package:picklog/features/library/library_entry_model.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('parseReleaseDate', () {
    test('treats 0, the epoch, the zero time and missing as unknown', () {
      expect(parseReleaseDate(null), isNull);
      expect(parseReleaseDate(0), isNull);
      expect(parseReleaseDate(0, isUtc: true), isNull);
      expect(parseReleaseDate(''), isNull);
      expect(parseReleaseDate('not a date'), isNull);
      expect(parseReleaseDate('1970-01-01T00:00:00Z'), isNull);
      expect(parseReleaseDate('0001-01-01T00:00:00Z'), isNull);
    });

    test('parses Unix seconds and RFC 3339 strings', () {
      final seconds = DateTime.utc(2020, 9, 17).millisecondsSinceEpoch ~/ 1000;
      final utc = parseReleaseDate(seconds, isUtc: true)!;
      expect(utc.isUtc, isTrue);
      expect(utc.year, 2020);
      expect(
        parseReleaseDate('2020-09-17T00:00:00Z'),
        DateTime.utc(2020, 9, 17),
      );
    });
  });

  group('every game model treats a 0 release date as unknown', () {
    test('search results', () {
      final game = SearchGame.fromJson(const {
        'id': 1,
        'name': 'Hade: Forbidden Levels',
        'first_release_date': 0,
      });
      expect(game.firstReleaseDate, isNull);
    });

    test('game details', () {
      final game = GameDetail.fromJson(const {
        'id': 1,
        'name': 'x',
        'first_release_date': 0,
      });
      expect(game.firstReleaseDate, isNull);
    });

    test('explore and recommendations', () {
      final game = DiscoveryGame.fromJson(const {
        'id': 1,
        'name': 'x',
        'first_release_date': '1970-01-01T00:00:00Z',
      });
      expect(game.firstReleaseDate, isNull);
      expect(game.releaseYear, isNull);
    });

    test('AI discover', () {
      final game = AiDiscoverGame.fromJson(const {
        'id': 1,
        'name': 'x',
        'first_release_date': '1970-01-01T00:00:00Z',
      });
      expect(game.firstReleaseDate, isNull);
    });

    test('library games', () {
      final game = CachedGame.fromJson(const {
        'igdb_id': 1,
        'name': 'x',
        'first_release_date': '1970-01-01T00:00:00Z',
        'last_synced_at': '2026-01-01T00:00:00Z',
      });
      expect(game.firstReleaseDate, isNull);
    });
  });

  testWidgets('the search card shows no year for a 0 release date', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpPicklog(
      tester,
      GameSearchCard(
        game: SearchGame.fromJson(const {
          'id': 1,
          'name': 'Hade: Forbidden Levels',
          'first_release_date': 0,
          'genres': [
            {'id': 15, 'name': 'Strategy'},
            {'id': 32, 'name': 'Indie'},
          ],
        }),
      ),
    );

    expect(find.textContaining('1970'), findsNothing);
    expect(find.byIcon(Icons.calendar_today_outlined), findsNothing);
    expect(
      find.bySemanticsLabel('Hade: Forbidden Levels. Strategy, Indie'),
      findsOneWidget,
    );
    handle.dispose();
  });
}
