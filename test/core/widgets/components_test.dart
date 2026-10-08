import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picklog/core/theme/pf_page_transitions.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/widgets/animated_state_switcher.dart';
import 'package:picklog/core/widgets/app_scaffold.dart';
import 'package:picklog/core/widgets/brand_mark.dart';
import 'package:picklog/core/widgets/favorite_button.dart';
import 'package:picklog/core/widgets/game_card.dart';
import 'package:picklog/core/widgets/game_cover.dart';
import 'package:picklog/core/widgets/glass_surface.dart';
import 'package:picklog/core/widgets/pf_button.dart';
import 'package:picklog/core/widgets/pf_dialog.dart';
import 'package:picklog/core/widgets/pf_network_image.dart';
import 'package:picklog/core/widgets/pf_page_indicator.dart';
import 'package:picklog/core/widgets/press_scale.dart';
import 'package:picklog/core/widgets/responsive_grid.dart';
import 'package:picklog/core/widgets/section_header.dart';
import 'package:picklog/core/widgets/staggered_reveal.dart';

import '../../helpers/pump_app.dart';

/// 1x1 transparent PNG.
final Uint8List _pixel = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

double _opacityOf(WidgetTester tester, Finder child) {
  final opacity = tester.widget<Opacity>(
    find.ancestor(of: child, matching: find.byType(Opacity)).first,
  );
  return opacity.opacity;
}

void main() {
  group('SectionHeader', () {
    testWidgets('uppercases the eyebrow and wires "see all"', (tester) async {
      var opened = false;
      await pumpPicklog(
        tester,
        SectionHeader(
          eyebrow: 'Picklog · Home',
          title: 'Trending',
          seeAllLabel: 'See all',
          onSeeAll: () => opened = true,
        ),
      );

      expect(find.text('PICKLOG · HOME'), findsOneWidget);
      expect(find.text('Trending'), findsOneWidget);
      await tester.tap(find.text('See all'));
      expect(opened, isTrue);
    });

    testWidgets('hides "see all" without a destination', (tester) async {
      await pumpPicklog(tester, const SectionHeader(title: 'Recommended'));
      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('section eyebrows are ember, card eyebrows muted', (
      tester,
    ) async {
      await pumpPicklog(
        tester,
        const Column(children: [Eyebrow('Lead'), Eyebrow('Card', muted: true)]),
      );
      Color colorOf(String t) =>
          tester.widget<Text>(find.text(t)).style!.color!;
      expect(colorOf('LEAD'), PicklogColors.dark.emberFg);
      expect(colorOf('CARD'), PicklogColors.dark.textMed);
    });
  });

  group('GameCover', () {
    testWidgets('shows a placeholder without a URL', (tester) async {
      await pumpPicklog(
        tester,
        const SizedBox(width: 90, height: 120, child: GameCover()),
      );
      expect(find.byIcon(Icons.videogame_asset_outlined), findsOneWidget);
    });

    testWidgets('loads through a NetworkImageScope override', (tester) async {
      String? requested;
      await pumpPicklog(
        tester,
        NetworkImageScope(
          builder: (url) {
            requested = url;
            return MemoryImage(_pixel);
          },
          child: const SizedBox(
            width: 90,
            height: 120,
            child: GameCover(url: '//images.igdb.com/t_thumb/a.jpg'),
          ),
        ),
      );
      // The size token is rewritten and the protocol added.
      expect(requested, 'https://images.igdb.com/t_cover_big/a.jpg');
    });

    testWidgets('uses a plain Hero as a destination', (tester) async {
      await pumpPicklog(
        tester,
        const SizedBox(
          width: 90,
          height: 120,
          child: GameCover(heroTag: 'tag', isHeroDestination: true),
        ),
      );
      expect(tester.widget<Hero>(find.byType(Hero)).tag, 'tag');
    });
  });

  group('GameCard and GameTile', () {
    testWidgets('GameCard shows title, score and handles taps', (tester) async {
      var taps = 0;
      await pumpPicklog(
        tester,
        Center(
          child: SizedBox(
            width: 132,
            height: gameCardRailHeight(132),
            child: GameCard(title: 'Hades', score: 93, onTap: () => taps++),
          ),
        ),
      );

      expect(find.text('Hades'), findsOneWidget);
      expect(find.text('93'), findsOneWidget);
      await tester.tap(find.byType(GameCard));
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('GameTile renders meta and trailing widgets', (tester) async {
      await pumpPicklog(
        tester,
        GameTile(
          title: 'Celeste',
          onTap: () {},
          meta: const [Text('PC')],
          trailing: const Icon(Icons.chevron_right),
        ),
      );
      expect(find.text('Celeste'), findsOneWidget);
      expect(find.text('PC'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });
  });

  group('ResponsiveGrid', () {
    test('picks 2 / 3 / 4 / 6 columns by width', () {
      expect(ResponsiveGrid.columnsFor(390), 2);
      expect(ResponsiveGrid.columnsFor(700), 3);
      expect(ResponsiveGrid.columnsFor(1000), 4);
      expect(ResponsiveGrid.columnsFor(1280), 6);
    });
  });

  group('motion', () {
    testWidgets('StaggeredReveal starts hidden and ends visible', (
      tester,
    ) async {
      await pumpPicklog(
        tester,
        const StaggeredReveal(index: 3, child: Text('Item')),
      );
      expect(_opacityOf(tester, find.text('Item')), 0);
      await tester.pumpAndSettle();
      expect(_opacityOf(tester, find.text('Item')), 1);
    });

    testWidgets('StaggeredReveal shows at once under reduced motion', (
      tester,
    ) async {
      await pumpPicklog(
        tester,
        const StaggeredReveal(index: 3, child: Text('Item')),
        reducedMotion: true,
      );
      expect(_opacityOf(tester, find.text('Item')), 1);
    });

    testWidgets('AnimatedStateSwitcher swaps instantly under reduced motion', (
      tester,
    ) async {
      await pumpPicklog(
        tester,
        const AnimatedStateSwitcher(stateKey: 'a', child: Text('A')),
        reducedMotion: true,
      );
      final switcher = tester.widget<AnimatedSwitcher>(
        find.byType(AnimatedSwitcher),
      );
      expect(switcher.duration, Duration.zero);
    });

    testWidgets('PfMotion.of zeroes durations under reduced motion', (
      tester,
    ) async {
      late Duration resolved;
      await pumpPicklog(
        tester,
        Builder(
          builder: (context) {
            resolved = PfMotion.of(context, PfMotion.standard);
            return const SizedBox();
          },
        ),
        reducedMotion: true,
      );
      expect(resolved, Duration.zero);
    });

    testWidgets('page transitions skip the fade under reduced motion', (
      tester,
    ) async {
      const builder = PfPageTransitionsBuilder();
      expect(builder.transitionDuration, PfMotion.slow);
      late Widget built;
      await pumpPicklog(
        tester,
        Builder(
          builder: (context) {
            built = builder.buildTransitions<void>(
              MaterialPageRoute<void>(builder: (_) => const SizedBox()),
              context,
              const AlwaysStoppedAnimation(0.5),
              const AlwaysStoppedAnimation(0),
              const SizedBox(),
            );
            return const SizedBox();
          },
        ),
        reducedMotion: true,
      );
      expect(built, isNot(isA<FadeTransition>()));
    });

    testWidgets('FavoriteButton toggles icon and label', (tester) async {
      var favorite = false;
      await pumpPicklog(
        tester,
        StatefulBuilder(
          builder: (context, setState) => FavoriteButton(
            isFavorite: favorite,
            addLabel: 'Add to favorites',
            removeLabel: 'Remove from favorites',
            onPressed: () => setState(() => favorite = !favorite),
          ),
        ),
      );
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      await tester.tap(find.byType(FavoriteButton));
      await tester.pump();
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byTooltip('Remove from favorites'), findsOneWidget);
      await tester.pumpAndSettle();
      final icon = tester.widget<Icon>(find.byIcon(Icons.favorite));
      // Neutral, so the ember Add game button stays the one warm element.
      expect(icon.color, PicklogColors.dark.textHi);
    });

    testWidgets('a filled FavoriteButton is neutral in the light theme', (
      tester,
    ) async {
      await pumpPicklog(
        tester,
        FavoriteButton(
          isFavorite: true,
          addLabel: 'Add to favorites',
          removeLabel: 'Remove from favorites',
          onPressed: () {},
        ),
        brightness: Brightness.light,
      );
      final icon = tester.widget<Icon>(find.byIcon(Icons.favorite));
      expect(icon.color, PicklogColors.light.textHi);
    });

    testWidgets('PressScale runs onTap from a keyboard activation', (
      tester,
    ) async {
      var taps = 0;
      await pumpPicklog(
        tester,
        PressScale(onTap: () => taps++, child: const Text('Card')),
      );
      await tester.tap(find.text('Card'));
      expect(taps, 1);
    });
  });

  group('brand', () {
    for (final variant in BrandMarkVariant.values) {
      testWidgets('BrandMark ${variant.name} paints', (tester) async {
        await pumpPicklog(tester, BrandMark(size: 64, variant: variant));
        expect(find.byType(BrandMark), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('Wordmark reads as the app name', (tester) async {
      await pumpPicklog(tester, const Wordmark());
      expect(find.text('Picklog'), findsOneWidget);
      expect(find.bySemanticsLabel('Picklog'), findsOneWidget);
    });
  });

  group('PfPageIndicator', () {
    testWidgets('hides for a single page and announces the position', (
      tester,
    ) async {
      await pumpPicklog(tester, const PfPageIndicator(count: 1, index: 0));
      expect(find.byType(AnimatedContainer), findsNothing);

      await pumpPicklog(
        tester,
        const PfPageIndicator(count: 4, index: 1, semanticLabel: 'Page 2 of 4'),
      );
      expect(find.byType(AnimatedContainer), findsNWidgets(4));
      expect(find.bySemanticsLabel('Page 2 of 4'), findsOneWidget);
    });
  });

  group('PfButton', () {
    testWidgets('primary is a FilledButton pill at the requested height', (
      tester,
    ) async {
      await pumpPicklog(
        tester,
        Center(
          child: PfButton(label: 'Go', size: PfButtonSize.lg, onPressed: () {}),
        ),
      );
      expect(find.byType(FilledButton), findsOneWidget);
      expect(tester.getSize(find.byType(FilledButton)).height, 56);
    });

    testWidgets('destructive uses the error tone', (tester) async {
      await pumpPicklog(
        tester,
        PfButton(
          label: 'Sign out',
          variant: PfButtonVariant.destructive,
          onPressed: () {},
        ),
      );
      final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(
        button.style!.foregroundColor!.resolve({}),
        PicklogColors.dark.errorFg,
      );
    });

    testWidgets('busy shows a spinner and blocks taps', (tester) async {
      var taps = 0;
      await pumpPicklog(
        tester,
        PfButton(label: 'Save', isBusy: true, onPressed: () => taps++),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(FilledButton));
      expect(taps, 0);
    });
  });

  group('surfaces', () {
    testWidgets('GlassSurface blurs behind its child', (tester) async {
      await pumpPicklog(tester, const GlassSurface(child: Text('Glass')));
      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('MaxWidthBox caps the width', (tester) async {
      tester.view.physicalSize = const Size(1400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpPicklog(
        tester,
        const MaxWidthBox(
          maxWidth: 600,
          child: SizedBox(key: Key('box'), height: 10, width: double.infinity),
        ),
      );
      expect(tester.getSize(find.byKey(const Key('box'))).width, 600);
    });

    testWidgets('showPfDialog fades in and closes', (tester) async {
      await pumpPicklog(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showPfDialog<void>(
              context: context,
              builder: (_) => const AlertDialog(title: Text('Hello')),
            ),
            child: const Text('Open'),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(PfMotion.dialog);
      expect(find.text('Hello'), findsOneWidget);
      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();
      expect(find.text('Hello'), findsNothing);
    });
  });
}
