import 'package:flutter/material.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/pf_typography.dart';
import 'package:picklog/core/theme/picklog_colors.dart';

/// Mono uppercase label above a title (for example "PICKLOG · LIBRARY").
///
/// Section eyebrows use the ember tone. Eyebrows inside cards use [muted].
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {this.muted = false, this.color, super.key});

  final String text;

  /// Uses the low-contrast text tone instead of ember.
  final bool muted;

  /// Overrides the tone, for example on an image.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.pfColors;
    return Text(
      text.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: PfTypography.eyebrow(
        color ?? (muted ? colors.textMed : colors.emberFg),
      ),
    );
  }
}

/// Section heading: optional eyebrow, a title, and an optional "see all".
///
/// Every home and browse row uses this so headings stay consistent. Pass
/// [onSeeAll] only when a destination screen exists.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.seeAllLabel,
    this.onSeeAll,
    this.padding = const EdgeInsets.fromLTRB(
      PfSpace.lg,
      PfSpace.lg,
      PfSpace.sm,
      PfSpace.sm,
    ),
    super.key,
  }) : assert(
         onSeeAll == null || seeAllLabel != null,
         'Provide seeAllLabel with onSeeAll',
       );

  final String title;
  final String? eyebrow;
  final String? subtitle;
  final String? seeAllLabel;
  final VoidCallback? onSeeAll;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.pfColors;

    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (eyebrow != null) ...[
                  Eyebrow(eyebrow!),
                  const SizedBox(height: PfSpace.xs),
                ],
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: theme.textTheme.headlineSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(foregroundColor: colors.textMed),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(seeAllLabel!),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right, size: 18),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
