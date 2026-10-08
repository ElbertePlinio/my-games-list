import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/widgets/pf_dialog.dart';

import '../../helpers/pump_app.dart';

void main() {
  for (final (brightness, colors) in [
    (Brightness.dark, PicklogColors.dark),
    (Brightness.light, PicklogColors.light),
  ]) {
    testWidgets('the barrier uses the $brightness scrim token', (tester) async {
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
        brightness: brightness,
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final barrier = tester.widget<ModalBarrier>(
        find.byType(ModalBarrier).last,
      );
      expect(barrier.color, colors.scrim);
      expect(colors.scrim, colors.surface.withValues(alpha: 0.62));
    });
  }
}
