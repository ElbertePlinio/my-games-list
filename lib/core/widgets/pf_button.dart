import 'package:flutter/material.dart';
import 'package:picklog/core/theme/picklog_colors.dart';

/// Visual role of a [PfButton].
///
/// Usage guidance (one primary per visible section):
/// - [primary]: ember pill, the single most important action.
/// - [secondary]: hairline pill on surface-1, a parallel action.
/// - [ghost]: text only, tertiary actions such as cancel or skip.
/// - [destructive]: outlined in the error tone, for sign out and deletes.
enum PfButtonVariant { primary, secondary, ghost, destructive }

/// Pill heights: sm 36, md 44, lg 56.
enum PfButtonSize {
  sm(36, 16, 14),
  md(44, 20, 15),
  lg(56, 28, 16);

  const PfButtonSize(this.height, this.paddingX, this.fontSize);

  final double height;
  final double paddingX;
  final double fontSize;
}

/// Brand pill button. Plain `FilledButton`, `OutlinedButton` and `TextButton`
/// already get these styles from the theme at the md size; use [PfButton]
/// when you need another size, the destructive role, an icon, a busy state
/// or full width.
class PfButton extends StatelessWidget {
  const PfButton({
    required this.label,
    required this.onPressed,
    this.variant = PfButtonVariant.primary,
    this.size = PfButtonSize.md,
    this.icon,
    this.isBusy = false,
    this.expand = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final PfButtonVariant variant;
  final PfButtonSize size;
  final IconData? icon;

  /// Shows a spinner and blocks taps.
  final bool isBusy;

  /// Stretches to the available width.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final colors = context.pfColors;
    final onTap = isBusy ? null : onPressed;
    var style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(64, size.height)),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: size.paddingX),
      ),
      textStyle: WidgetStatePropertyAll(
        Theme.of(context).textTheme.labelLarge!.copyWith(
          fontSize: size.fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    // A busy primary keeps its ember fill so the spinner stays visible.
    if (isBusy && variant == PfButtonVariant.primary) {
      style = style.copyWith(
        backgroundColor: WidgetStatePropertyAll(colors.ember),
      );
    }

    final spinnerColor = variant == PfButtonVariant.primary
        ? colors.onEmber
        : colors.textHi;
    final child = isBusy
        ? SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: spinnerColor,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: size.fontSize + 3),
                const SizedBox(width: 8),
              ],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );

    final button = switch (variant) {
      PfButtonVariant.primary => FilledButton(
        onPressed: onTap,
        style: style,
        child: child,
      ),
      PfButtonVariant.secondary => OutlinedButton(
        onPressed: onTap,
        style: style,
        child: child,
      ),
      PfButtonVariant.ghost => TextButton(
        onPressed: onTap,
        style: style.copyWith(
          minimumSize: WidgetStatePropertyAll(Size(48, size.height)),
        ),
        child: child,
      ),
      PfButtonVariant.destructive => OutlinedButton(
        onPressed: onTap,
        style: style.copyWith(
          foregroundColor: WidgetStatePropertyAll(colors.errorFg),
          side: WidgetStatePropertyAll(
            BorderSide(color: colors.errorFg.withValues(alpha: 0.5)),
          ),
          overlayColor: WidgetStatePropertyAll(
            colors.error.withValues(alpha: 0.08),
          ),
        ),
        child: child,
      ),
    };

    return Semantics(
      label: isBusy ? label : null,
      child: expand ? SizedBox(width: double.infinity, child: button) : button,
    );
  }
}
