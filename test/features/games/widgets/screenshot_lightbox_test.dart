import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picklog/core/widgets/pf_network_image.dart';
import 'package:picklog/features/games/widgets/screenshot_lightbox.dart';

import 'package:picklog/core/theme/app_theme.dart';
import 'package:picklog/l10n/app_localizations.dart';

final Uint8List _pixel = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

/// Image decoding never finishes under the fake clock, so the loading
/// spinner keeps animating; advance a fixed amount instead of settling.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  const urls = [
    '//img/t_thumb/1.jpg',
    '//img/t_thumb/2.jpg',
    '//img/t_thumb/3.jpg',
  ];

  Future<void> open(WidgetTester tester, {int index = 0}) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // The scope sits above the app so the dialog route inherits it.
    await tester.pumpWidget(
      NetworkImageScope(
        builder: (_) => MemoryImage(_pixel),
        child: MaterialApp(
          theme: AppTheme.dark(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => ScreenshotLightbox.show(
                  context,
                  urls: urls,
                  initialIndex: index,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await _settle(tester);
  }

  testWidgets('opens at the tapped screenshot and swipes', (tester) async {
    await open(tester, index: 1);
    expect(find.text('2 / 3'), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(-600, 0), 1500);
    await _settle(tester);
    expect(find.text('3 / 3'), findsOneWidget);
  });

  testWidgets('arrow keys move and Escape closes', (tester) async {
    await open(tester);
    expect(find.text('1 / 3'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await _settle(tester);
    expect(find.text('2 / 3'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await _settle(tester);
    expect(find.byType(ScreenshotLightbox), findsNothing);
  });

  testWidgets('the close button dismisses the viewer', (tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('Close'));
    await _settle(tester);
    expect(find.byType(ScreenshotLightbox), findsNothing);
  });
}
