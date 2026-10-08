import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picklog/features/home/home_screen.dart';
import 'package:picklog/l10n/app_localizations.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final pt = lookupAppLocalizations(const Locale('pt'));

  List<String> day(AppLocalizations l10n) => [
    for (var hour = 0; hour < 24; hour++) homeGreeting(l10n, 'Ana Lima', hour),
  ];

  test('greets by time band: night 0-4, morning 5-11, afternoon 12-17, '
      'evening 18-23', () {
    expect(day(en), [
      ...List.filled(5, 'Up late, Ana?'),
      ...List.filled(7, 'Good morning, Ana'),
      ...List.filled(6, 'Good afternoon, Ana'),
      ...List.filled(6, 'Good evening, Ana'),
    ]);
  });

  test('the bands are localized in Portuguese', () {
    expect(day(pt), [
      ...List.filled(5, 'Boa madrugada, Ana'),
      ...List.filled(7, 'Bom dia, Ana'),
      ...List.filled(6, 'Boa tarde, Ana'),
      ...List.filled(6, 'Boa noite, Ana'),
    ]);
  });

  test('03:46 is not morning', () {
    expect(homeGreeting(en, 'Ana', 3), isNot(contains('morning')));
  });

  test('an unknown name gets the anonymous greeting at any hour', () {
    expect(homeGreeting(en, null, 3), 'Welcome back');
    expect(homeGreeting(pt, '  ', 20), 'Que bom te ver');
  });
}
