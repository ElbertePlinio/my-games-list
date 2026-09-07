import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picklog/core/widgets/shimmer_loading.dart';

void main() {
  testWidgets('ShimmerLoading renders its child through a ShaderMask', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ShimmerLoading(
            child: SizedBox(
              width: 100,
              height: 100,
              child: ColoredBox(color: Colors.grey),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(ShimmerLoading), findsOneWidget);
    expect(find.byType(ShaderMask), findsOneWidget);

    // Advance the (infinite) shimmer animation; it should keep rendering.
    await tester.pump(const Duration(milliseconds: 700));
    expect(tester.takeException(), isNull);
  });
}
