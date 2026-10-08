import 'package:flutter/material.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/picklog_colors.dart';

/// Small tinted pill with a tone dot (or icon) and a label.
///
/// The label uses the tone's foreground token, which passes AA on the theme
/// surfaces. Features map their own states to a [PfTone] (see the library
/// status pill).
class StatusPill extends StatelessWidget {
  const StatusPill({
    required this.label,
    required this.tone,
    this.icon,
    this.dense = false,
    super.key,
  });

  final String label;
  final PfTone tone;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final colors = context.pfColors;
    final foreground = colors.toneForeground(tone);
    final textStyle = Theme.of(context).textTheme.labelSmall!.copyWith(
      color: foreground,
      fontWeight: FontWeight.w600,
      fontSize: dense ? 10.5 : 11,
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? PfSpace.sm - 1 : PfSpace.sm + 2,
        vertical: dense ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: colors.toneBackground(tone),
        borderRadius: PfRadius.pillAll,
        border: Border.all(
          color: colors.toneFill(tone).withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(icon, size: dense ? 11 : 12, color: foreground)
          else
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: colors.toneFill(tone),
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: PfSpace.xs + 1),
          Flexible(
            child: Text(
              label,
              style: textStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
