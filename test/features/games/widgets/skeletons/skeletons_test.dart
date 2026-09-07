import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picklog/core/widgets/shimmer_loading.dart';
import 'package:picklog/core/widgets/skeleton_box.dart';
import 'package:picklog/features/games/widgets/skeletons/discovery_grid_skeleton.dart';
import 'package:picklog/features/games/widgets/skeletons/discovery_tile_skeleton.dart';
import 'package:picklog/features/games/widgets/skeletons/game_details_skeleton.dart';
import 'package:picklog/features/games/widgets/skeletons/library_entry_skeleton.dart';
import 'package:picklog/features/games/widgets/skeletons/search_card_skeleton.dart';

Widget _wrap(Widget child, {Brightness brightness = Brightness.light}) {
  return MaterialApp(
    theme: ThemeData(brightness: brightness),
    home: Scaffold(body: child),
  );
}

void main() {
  group('SkeletonBox', () {
    testWidgets('shimmers in light theme', (tester) async {
      await tester.pumpWidget(_wrap(const SkeletonBox(width: 100, height: 50)));

      expect(find.byType(ShimmerLoading), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });

    testWidgets('shimmers in dark theme', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SkeletonBox(width: 100, height: 50),
          brightness: Brightness.dark,
        ),
      );

      expect(find.byType(ShimmerLoading), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('DiscoveryRowSkeleton renders the given number of tiles', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const DiscoveryRowSkeleton(itemCount: 4)));

    expect(find.byType(DiscoveryTileSkeleton), findsNWidgets(4));
    expect(find.byType(ShimmerLoading), findsNWidgets(4));
  });

  testWidgets('DiscoveryGridSkeleton renders shimmering tiles', (tester) async {
    await tester.pumpWidget(_wrap(const DiscoveryGridSkeleton(itemCount: 4)));

    // GridView lazily builds only the tiles within the viewport, so assert at
    // least the first row is present and shimmering.
    expect(find.byType(DiscoveryTileSkeleton), findsWidgets);
    expect(find.byType(ShimmerLoading), findsWidgets);
  });

  testWidgets('DiscoveryListSkeleton renders shimmering rows', (tester) async {
    await tester.pumpWidget(_wrap(const DiscoveryListSkeleton(itemCount: 3)));

    expect(find.byType(Card), findsNWidgets(3));
    expect(find.byType(ShimmerLoading), findsWidgets);
  });

  testWidgets('SearchResultsSkeleton renders shimmering cards', (tester) async {
    await tester.pumpWidget(_wrap(const SearchResultsSkeleton(itemCount: 3)));

    expect(find.byType(SearchCardSkeleton), findsNWidgets(3));
    expect(find.byType(ShimmerLoading), findsWidgets);
  });

  testWidgets('LibraryListSkeleton renders shimmering entries', (tester) async {
    await tester.pumpWidget(_wrap(const LibraryListSkeleton(itemCount: 3)));

    expect(find.byType(LibraryEntrySkeleton), findsNWidgets(3));
    expect(find.byType(ShimmerLoading), findsWidgets);
  });

  testWidgets('GameDetailsSkeleton renders a header and info shimmer', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const GameDetailsSkeleton()));

    expect(find.byType(GameDetailsSkeleton), findsOneWidget);
    expect(find.byType(ShimmerLoading), findsWidgets);
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });

  testWidgets('GameDetailsSkeleton keeps a pinned app bar with a back button', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const GameDetailsSkeleton()));

    // The real screen pins a SliverAppBar with a back affordance, so the
    // skeleton must too: the back button stays visible during a slow fetch and
    // no app-bar chrome shifts in when content arrives.
    expect(find.byType(SliverAppBar), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
  });
}
