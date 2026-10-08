import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picklog/features/library/library_formatters.dart';
import 'package:picklog/l10n/app_localizations.dart';

Future<String Function(int?)> _formatter(
  WidgetTester tester,
  Locale locale,
) async {
  late BuildContext captured;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: Builder(
        builder: (context) {
          captured = context;
          return const SizedBox();
        },
      ),
    ),
  );
  return (int? minutes) => formatPlaytime(captured, minutes);
}

void main() {
  testWidgets('formats playtime in English', (tester) async {
    final format = await _formatter(tester, const Locale('en'));
    expect(format(null), 'No playtime');
    expect(format(0), 'No playtime');
    expect(format(45), '45 min');
    expect(format(60), '1 h');
    expect(format(750), '12.5 h');
    expect(format(120000), '2,000 h');
  });

  testWidgets('formats playtime in Portuguese with a comma decimal', (
    tester,
  ) async {
    final format = await _formatter(tester, const Locale('pt'));
    expect(format(null), 'Sem tempo de jogo');
    expect(format(750), '12,5 h');
  });
}
