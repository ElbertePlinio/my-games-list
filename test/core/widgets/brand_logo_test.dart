import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picklog/core/widgets/brand_logo.dart';

void main() {
  group('BrandLogo', () {
    testWidgets('renders the controller glyph at the requested size', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: BrandLogo(size: 96))),
        ),
      );

      expect(find.byType(BrandLogo), findsOneWidget);
      expect(find.byIcon(Icons.games), findsOneWidget);

      final box = tester.getSize(find.byType(BrandLogo));
      expect(box.width, 96);
      expect(box.height, 96);
    });
  });
}
