import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picklog/core/utils/website_category.dart';

void main() {
  group('WebsiteCategory constants', () {
    test('has correct values', () {
      expect(WebsiteCategory.official, equals(1));
      expect(WebsiteCategory.wikia, equals(2));
      expect(WebsiteCategory.wikipedia, equals(3));
      expect(WebsiteCategory.facebook, equals(4));
      expect(WebsiteCategory.twitter, equals(5));
      expect(WebsiteCategory.twitch, equals(6));
      expect(WebsiteCategory.instagram, equals(8));
      expect(WebsiteCategory.youtube, equals(9));
      expect(WebsiteCategory.iphone, equals(10));
      expect(WebsiteCategory.ipad, equals(11));
      expect(WebsiteCategory.android, equals(12));
      expect(WebsiteCategory.steam, equals(13));
      expect(WebsiteCategory.reddit, equals(14));
      expect(WebsiteCategory.itch, equals(15));
      expect(WebsiteCategory.epicGames, equals(16));
      expect(WebsiteCategory.gog, equals(17));
      expect(WebsiteCategory.discord, equals(18));
    });
  });

  group('getWebsiteIcon', () {
    test('returns language icon for official website', () {
      expect(getWebsiteIcon(WebsiteCategory.official), equals(Icons.language));
    });

    test('returns menu_book icon for wikia', () {
      expect(getWebsiteIcon(WebsiteCategory.wikia), equals(Icons.menu_book));
    });

    test('returns menu_book icon for wikipedia', () {
      expect(
        getWebsiteIcon(WebsiteCategory.wikipedia),
        equals(Icons.menu_book),
      );
    });

    test('returns facebook icon for facebook', () {
      expect(getWebsiteIcon(WebsiteCategory.facebook), equals(Icons.facebook));
    });

    test('returns games icon for steam', () {
      expect(getWebsiteIcon(WebsiteCategory.steam), equals(Icons.games));
    });

    test('returns play_circle_fill icon for youtube', () {
      expect(
        getWebsiteIcon(WebsiteCategory.youtube),
        equals(Icons.play_circle_fill),
      );
    });

    test('returns chat_bubble icon for discord', () {
      expect(
        getWebsiteIcon(WebsiteCategory.discord),
        equals(Icons.chat_bubble),
      );
    });

    test('returns link icon for unknown category', () {
      expect(getWebsiteIcon(999), equals(Icons.link));
    });

    test('returns link icon for category 0', () {
      expect(getWebsiteIcon(0), equals(Icons.link));
    });
  });

  group('getWebsiteName', () {
    test('returns correct name for official website', () {
      expect(getWebsiteName(WebsiteCategory.official), equals('Official'));
    });

    test('returns correct name for Steam', () {
      expect(getWebsiteName(WebsiteCategory.steam), equals('Steam'));
    });

    test('returns correct name for Epic Games', () {
      expect(getWebsiteName(WebsiteCategory.epicGames), equals('Epic Games'));
    });

    test('returns correct name for GOG', () {
      expect(getWebsiteName(WebsiteCategory.gog), equals('GOG'));
    });

    test('returns correct name for Discord', () {
      expect(getWebsiteName(WebsiteCategory.discord), equals('Discord'));
    });

    test('returns correct name for Twitter/X', () {
      expect(getWebsiteName(WebsiteCategory.twitter), equals('Twitter (X)'));
    });

    test('returns Website for unknown category', () {
      expect(getWebsiteName(999), equals('Website'));
    });

    test('returns Website for category 0', () {
      expect(getWebsiteName(0), equals('Website'));
    });
  });

  group('isStoreCategory', () {
    test('returns true for Steam', () {
      expect(isStoreCategory(WebsiteCategory.steam), isTrue);
    });

    test('returns true for Epic Games', () {
      expect(isStoreCategory(WebsiteCategory.epicGames), isTrue);
    });

    test('returns true for GOG', () {
      expect(isStoreCategory(WebsiteCategory.gog), isTrue);
    });

    test('returns true for App Store (iPhone)', () {
      expect(isStoreCategory(WebsiteCategory.iphone), isTrue);
    });

    test('returns true for Google Play (Android)', () {
      expect(isStoreCategory(WebsiteCategory.android), isTrue);
    });

    test('returns true for itch.io', () {
      expect(isStoreCategory(WebsiteCategory.itch), isTrue);
    });

    test('returns false for official website', () {
      expect(isStoreCategory(WebsiteCategory.official), isFalse);
    });

    test('returns false for Twitter', () {
      expect(isStoreCategory(WebsiteCategory.twitter), isFalse);
    });

    test('returns false for unknown category', () {
      expect(isStoreCategory(999), isFalse);
    });
  });

  group('isSocialCategory', () {
    test('returns true for Facebook', () {
      expect(isSocialCategory(WebsiteCategory.facebook), isTrue);
    });

    test('returns true for Twitter', () {
      expect(isSocialCategory(WebsiteCategory.twitter), isTrue);
    });

    test('returns true for Instagram', () {
      expect(isSocialCategory(WebsiteCategory.instagram), isTrue);
    });

    test('returns true for YouTube', () {
      expect(isSocialCategory(WebsiteCategory.youtube), isTrue);
    });

    test('returns true for Twitch', () {
      expect(isSocialCategory(WebsiteCategory.twitch), isTrue);
    });

    test('returns true for Reddit', () {
      expect(isSocialCategory(WebsiteCategory.reddit), isTrue);
    });

    test('returns true for Discord', () {
      expect(isSocialCategory(WebsiteCategory.discord), isTrue);
    });

    test('returns false for Steam', () {
      expect(isSocialCategory(WebsiteCategory.steam), isFalse);
    });

    test('returns false for official website', () {
      expect(isSocialCategory(WebsiteCategory.official), isFalse);
    });

    test('returns false for unknown category', () {
      expect(isSocialCategory(999), isFalse);
    });
  });

  group('URL-based detection fallback', () {
    group('getWebsiteName with URL fallback', () {
      test('detects Steam from URL when category is 0', () {
        expect(
          getWebsiteName(0, 'https://store.steampowered.com/app/12345'),
          equals('Steam'),
        );
      });

      test('detects Epic Games from URL when category is 0', () {
        expect(
          getWebsiteName(0, 'https://www.epicgames.com/store/game'),
          equals('Epic Games'),
        );
      });

      test('detects GOG from URL when category is 0', () {
        expect(
          getWebsiteName(0, 'https://www.gog.com/game/test'),
          equals('GOG'),
        );
      });

      test('detects Twitter/X from URL when category is 0', () {
        expect(
          getWebsiteName(0, 'https://twitter.com/game'),
          equals('Twitter (X)'),
        );
        expect(getWebsiteName(0, 'https://x.com/game'), equals('Twitter (X)'));
      });

      test('detects Discord from URL when category is 0', () {
        expect(
          getWebsiteName(0, 'https://discord.gg/invite'),
          equals('Discord'),
        );
      });

      test('detects YouTube from URL when category is 0', () {
        expect(
          getWebsiteName(0, 'https://www.youtube.com/channel'),
          equals('YouTube'),
        );
      });

      test('detects Reddit from URL when category is 0', () {
        expect(
          getWebsiteName(0, 'https://www.reddit.com/r/game'),
          equals('Reddit'),
        );
      });

      test('detects Wikipedia from URL when category is 0', () {
        expect(
          getWebsiteName(0, 'https://en.wikipedia.org/wiki/Game'),
          equals('Wikipedia'),
        );
      });

      test('detects Wiki/Fandom from URL when category is 0', () {
        expect(
          getWebsiteName(0, 'https://game.fandom.com/wiki'),
          equals('Wiki'),
        );
      });

      test('returns Website for unrecognized URL', () {
        expect(
          getWebsiteName(0, 'https://unknown-site.com'),
          equals('Website'),
        );
      });

      test('prefers category over URL when category is known', () {
        // Even if URL contains "steam", if category is discord, use discord
        expect(
          getWebsiteName(
            WebsiteCategory.discord,
            'https://store.steampowered.com',
          ),
          equals('Discord'),
        );
      });
    });

    group('getWebsiteIcon with URL fallback', () {
      test('detects Steam icon from URL when category is 0', () {
        expect(
          getWebsiteIcon(0, 'https://store.steampowered.com/app/12345'),
          equals(Icons.games),
        );
      });

      test('detects Discord icon from URL when category is 0', () {
        expect(
          getWebsiteIcon(0, 'https://discord.gg/invite'),
          equals(Icons.chat_bubble),
        );
      });

      test('returns link icon for unrecognized URL', () {
        expect(
          getWebsiteIcon(0, 'https://unknown-site.com'),
          equals(Icons.link),
        );
      });
    });

    group('isStoreCategory with URL fallback', () {
      test('detects Steam as store from URL when category is 0', () {
        expect(
          isStoreCategory(0, 'https://store.steampowered.com/app/12345'),
          isTrue,
        );
      });

      test('detects Epic Games as store from URL when category is 0', () {
        expect(isStoreCategory(0, 'https://www.epicgames.com/store'), isTrue);
      });

      test('detects GOG as store from URL when category is 0', () {
        expect(isStoreCategory(0, 'https://www.gog.com/game'), isTrue);
      });

      test('detects Itch.io as store from URL when category is 0', () {
        expect(isStoreCategory(0, 'https://game.itch.io'), isTrue);
      });

      test('does not detect Discord as store from URL', () {
        expect(isStoreCategory(0, 'https://discord.gg/invite'), isFalse);
      });

      test('does not detect Twitter as store from URL', () {
        expect(isStoreCategory(0, 'https://twitter.com/game'), isFalse);
      });
    });

    group('isSocialCategory with URL fallback', () {
      test('detects Discord as social from URL when category is 0', () {
        expect(isSocialCategory(0, 'https://discord.gg/invite'), isTrue);
      });

      test('detects Twitter as social from URL when category is 0', () {
        expect(isSocialCategory(0, 'https://twitter.com/game'), isTrue);
      });

      test('detects YouTube as social from URL when category is 0', () {
        expect(isSocialCategory(0, 'https://www.youtube.com/channel'), isTrue);
      });

      test('does not detect Steam as social from URL', () {
        expect(
          isSocialCategory(0, 'https://store.steampowered.com/app'),
          isFalse,
        );
      });
    });
  });
}
