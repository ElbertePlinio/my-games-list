import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/pf_typography.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/widgets/section_header.dart';
import 'package:picklog/core/widgets/skeleton_box.dart';
import 'package:picklog/features/library/library_entry_model.dart';
import 'package:picklog/features/library/stats/library_stats_model.dart';

/// Whole hours for a minute count, formatted for the locale.
String formatHours(BuildContext context, int minutes) {
  final locale = Localizations.localeOf(context).toString();
  return NumberFormat.decimalPattern(locale).format((minutes / 60).round());
}

/// Compact library summary: total, playing, finished and hours.
class LibraryStatsHeader extends StatelessWidget {
  const LibraryStatsHeader({
    required this.stats,
    this.loading = false,
    super.key,
  });

  /// Null while loading or when stats failed.
  final UserStats? stats;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stats = this.stats;
    if (stats == null && !loading) return const SizedBox.shrink();
    final locale = Localizations.localeOf(context).toString();
    final number = NumberFormat.decimalPattern(locale);
    final metrics = <(String, String)>[
      if (stats != null) ...[
        (l10n.statsTotal, number.format(stats.totalGames)),
        (l10n.statusPlaying, number.format(stats.countFor(GameStatus.playing))),
        (
          l10n.statusFinished,
          number.format(stats.countFor(GameStatus.finished)),
        ),
        (l10n.statsHours, formatHours(context, stats.totalPlaytimeMinutes)),
      ],
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PfSpace.lg,
        PfSpace.xs,
        PfSpace.lg,
        PfSpace.md,
      ),
      child: Semantics(
        container: true,
        label: stats == null
            ? null
            : l10n.libraryStatsSemantics(
                stats.totalGames,
                stats.countFor(GameStatus.playing),
                stats.countFor(GameStatus.finished),
                formatHours(context, stats.totalPlaytimeMinutes),
              ),
        excludeSemantics: stats != null,
        child: Row(
          children: [
            for (var i = 0; i < 4; i++) ...[
              if (i > 0) const SizedBox(width: PfSpace.sm),
              Expanded(
                child: stats == null
                    ? const SkeletonBox(height: 58, borderRadius: PfRadius.md)
                    : _Metric(label: metrics[i].$1, value: metrics[i].$2),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.pfColors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PfSpace.md,
        vertical: PfSpace.sm + 2,
      ),
      decoration: BoxDecoration(
        color: colors.surface1,
        borderRadius: PfRadius.mdAll,
        border: Border.all(color: colors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: PfTypography.monoStyle(
                colors.textHi,
                size: 18,
                weight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Eyebrow(label, muted: true),
          ),
        ],
      ),
    );
  }
}
