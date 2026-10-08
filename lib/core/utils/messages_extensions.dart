import 'package:flutter/material.dart';
import 'package:picklog/core/theme/picklog_colors.dart';

/// Themed snackbars. Each variant adds a tone icon; colours come from the
/// brand tokens, never hardcoded Material colours.
extension MessagesX on BuildContext {
  void showMessage(String message) => _show(message, PfTone.neutral, null);

  void showErrorMessage(String message) =>
      _show(message, PfTone.error, Icons.error_outline);

  void showSuccessMessage(String message) =>
      _show(message, PfTone.connected, Icons.check_circle_outline);

  void showWarningMessage(String message) =>
      _show(message, PfTone.warning, Icons.info_outline);

  void hideCurrentMessage() {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
  }

  void _show(String message, PfTone tone, IconData? icon) {
    final colors = PicklogColors.of(this);
    // The snackbar is dark in both themes (inverse in light), so the tone
    // icon uses the dark palette's foreground.
    final iconColor = PicklogColors.dark.toneForeground(tone);
    final messenger = ScaffoldMessenger.of(this);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 10),
            ],
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: colors.isDark ? colors.surface3 : colors.textHi,
      ),
    );
  }
}
