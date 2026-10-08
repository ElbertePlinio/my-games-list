import 'package:flutter/material.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';

/// Shows [message] with an "Undo" action in the app's snackbar style.
void showUndoSnackBar(
  BuildContext context, {
  required String message,
  required VoidCallback onUndo,
}) {
  final colors = context.pfColors;
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: colors.isDark ? colors.surface3 : colors.textHi,
      action: SnackBarAction(
        label: context.l10n.undo,
        // The snackbar is dark in both themes, so the action uses the dark
        // palette's ember foreground.
        textColor: PicklogColors.dark.emberFg,
        onPressed: onUndo,
      ),
    ),
  );
}
