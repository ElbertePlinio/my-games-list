import 'package:flutter/material.dart';
import 'package:picklog/core/theme/pf_tokens.dart';

/// Shows [builder] as a dialog that fades in and rises 8px in 160ms.
///
/// Same contract as [showDialog]. Under reduced motion it appears at once.
Future<T?> showPfDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  final reduced = PfMotion.reduced(context);
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: const Color(0x99000000),
    transitionDuration: reduced ? Duration.zero : PfMotion.dialog,
    pageBuilder: (dialogContext, _, _) => builder(dialogContext),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: PfMotion.forge,
        reverseCurve: PfMotion.out.flipped,
      );
      return FadeTransition(
        opacity: curved,
        child: AnimatedBuilder(
          animation: curved,
          builder: (context, child) => Transform.translate(
            offset: Offset(0, PfMotion.dialogRise * (1 - curved.value)),
            child: child,
          ),
          child: child,
        ),
      );
    },
  );
}
