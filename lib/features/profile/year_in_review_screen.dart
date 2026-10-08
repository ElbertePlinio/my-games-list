import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:picklog/core/domain/models/app_failure.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/pf_typography.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/utils/error_l10n.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/utils/messages_extensions.dart';
import 'package:picklog/core/widgets/app_scaffold.dart';
import 'package:picklog/core/widgets/brand_mark.dart';
import 'package:picklog/core/widgets/game_cover.dart';
import 'package:picklog/core/widgets/score_badge.dart';
import 'package:picklog/core/widgets/section_header.dart';
import 'package:picklog/core/widgets/skeleton_box.dart';
import 'package:picklog/core/widgets/staggered_reveal.dart';
import 'package:picklog/core/widgets/state_views.dart';
import 'package:picklog/features/games/widgets/discovery_game_tile.dart';
import 'package:picklog/features/library/stats/library_stats_model.dart';
import 'package:picklog/features/library/stats/stats_cubit.dart';
import 'package:picklog/features/library/widgets/library_stats_header.dart';
import 'package:picklog/features/profile/widgets/count_up_text.dart';
import 'package:picklog/features/profile/widgets/month_bars.dart';
import 'package:share_plus/share_plus.dart';

/// Shares a rendered PNG. Replaced in tests.
typedef YearShareHandler =
    Future<void> Function(Uint8List png, String fileName, String text);

Future<void> _sharePng(Uint8List png, String fileName, String text) async {
  await Share.shareXFiles([
    XFile.fromData(png, mimeType: 'image/png', name: fileName),
  ], text: text);
}

/// Hero prefix for covers on the year screen.
const String kYearHeroPrefix = 'year-';

/// Years offered by the picker, newest first.
List<int> yearInReviewYears(int currentYear) => [
  for (var y = currentYear; y >= currentYear - 9 && y >= 2000; y--) y,
];

/// "Wrapped" style year in review: a vertical story of cards with counted-up
/// numbers, a month chart, top games and a shareable summary card.
class YearInReviewScreen extends StatefulWidget {
  const YearInReviewScreen({
    required this.year,
    this.onShare,
    this.now,
    super.key,
  });

  final int year;
  final YearShareHandler? onShare;

  /// Clock override for tests.
  final DateTime? now;

  @override
  State<YearInReviewScreen> createState() => _YearInReviewScreenState();
}

class _YearInReviewScreenState extends State<YearInReviewScreen> {
  final GlobalKey _shareKey = GlobalKey();
  late int _year = widget.year;
  bool _sharing = false;

  void _pickYear(int year) {
    if (year == _year) return;
    setState(() => _year = year);
    context.read<StatsCubit>().load(year: year);
  }

  Future<void> _share() async {
    final l10n = context.l10n;
    final boundary =
        _shareKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    setState(() => _sharing = true);
    try {
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) throw StateError('no image data');
      final handler = widget.onShare ?? _sharePng;
      await handler(
        data.buffer.asUint8List(),
        'picklog-$_year.png',
        l10n.yearShareText(_year),
      );
    } catch (_) {
      if (mounted) context.showErrorMessage(l10n.yearShareFailed);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final current = (widget.now ?? DateTime.now()).year;
    final years = yearInReviewYears(current);
    if (!years.contains(_year)) years.add(_year);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.yearInReviewTitle(_year)),
        actions: [
          PopupMenuButton<int>(
            key: const Key('year_picker'),
            tooltip: l10n.yearPickerTooltip,
            initialValue: _year,
            onSelected: _pickYear,
            itemBuilder: (context) => [
              for (final y in years)
                CheckedPopupMenuItem(
                  value: y,
                  checked: y == _year,
                  child: Text('$y'),
                ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: PfSpace.md),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$_year',
                    style: PfTypography.monoStyle(context.pfColors.textHi),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          BlocBuilder<StatsCubit, StatsState>(
            builder: (context, state) => IconButton(
              key: const Key('year_share_button'),
              icon: _sharing
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.ios_share),
              tooltip: l10n.yearShareTooltip,
              onPressed: state.stats?.yearSummary == null || _sharing
                  ? null
                  : _share,
            ),
          ),
          const SizedBox(width: PfSpace.xs),
        ],
      ),
      body: BlocBuilder<StatsCubit, StatsState>(
        builder: (context, state) {
          final summary = state.stats?.yearSummary;
          if (summary == null &&
              (state.isLoading || state.status == StatsStatus.initial)) {
            return const _StorySkeleton();
          }
          if (summary == null) {
            return ErrorState(
              message: (state.errorKind ?? AppErrorKind.unknown).message(
                context,
              ),
              onRetry: () => context.read<StatsCubit>().load(year: _year),
            );
          }
          return _Story(
            key: ValueKey(_year),
            year: _year,
            stats: state.stats!,
            summary: summary,
            shareKey: _shareKey,
            onShare: _sharing ? null : _share,
          );
        },
      ),
    );
  }
}

class _Story extends StatelessWidget {
  const _Story({
    required this.year,
    required this.stats,
    required this.summary,
    required this.shareKey,
    required this.onShare,
    super.key,
  });

  final int year;
  final UserStats stats;
  final YearSummary summary;
  final GlobalKey shareKey;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.pfColors;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final number = NumberFormat.decimalPattern(locale);
    final bigNumber = PfTypography.monoStyle(
      colors.textHi,
      size: 56,
      weight: FontWeight.w600,
    );
    final monthLabels = [
      for (var m = 1; m <= 12; m++)
        DateFormat.MMM(
          locale,
        ).format(DateTime(2000, m)).substring(0, 1).toUpperCase(),
    ];

    final cards = <Widget>[
      _StoryCard(
        accent: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Eyebrow(l10n.yearInReviewEyebrow),
            const SizedBox(height: PfSpace.md),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '$year',
                maxLines: 1,
                style: PfTypography.monoStyle(
                  colors.textHi,
                  size: 72,
                  weight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: PfSpace.sm),
            Text(l10n.yearIntroTitle, style: theme.textTheme.headlineMedium),
            const SizedBox(height: PfSpace.xs),
            Text(
              summary.isEmpty ? l10n.yearIntroEmpty : l10n.yearIntroHint,
              style: theme.textTheme.bodyLarge!.copyWith(color: colors.textMed),
            ),
          ],
        ),
      ),
      _StoryCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BigStat(
              label: l10n.yearGamesAdded,
              child: CountUpText(
                key: const Key('year_added_count'),
                value: summary.added,
                style: bigNumber,
                format: number.format,
              ),
            ),
            const SizedBox(height: PfSpace.xl),
            _BigStat(
              label: l10n.yearGamesFinished,
              child: CountUpText(
                key: const Key('year_finished_count'),
                value: summary.finished,
                style: bigNumber,
                format: number.format,
              ),
            ),
            const SizedBox(height: PfSpace.xl),
            _BigStat(
              label: l10n.yearHoursPlayed,
              child: CountUpText(
                key: const Key('year_hours_count'),
                value: (summary.playtimeMinutes / 60).round(),
                style: bigNumber,
                format: number.format,
              ),
            ),
          ],
        ),
      ),
      _StoryCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Eyebrow(l10n.yearByMonth, muted: true),
            const SizedBox(height: PfSpace.lg),
            MonthBarsChart(
              months: summary.byMonth,
              addedColor: colors.toneFill(PfTone.info),
              finishedColor: colors.toneFill(PfTone.connected),
              gridColor: colors.hairlineStrong,
              labelStyle: PfTypography.monoStyle(colors.textMed, size: 10),
              monthLabels: monthLabels,
              semanticLabel: l10n.yearByMonthSemantics(
                summary.added,
                summary.finished,
              ),
            ),
            const SizedBox(height: PfSpace.md),
            Wrap(
              spacing: PfSpace.lg,
              children: [
                _Legend(
                  color: colors.toneFill(PfTone.info),
                  label: l10n.yearLegendAdded,
                ),
                _Legend(
                  color: colors.toneFill(PfTone.connected),
                  label: l10n.yearLegendFinished,
                ),
              ],
            ),
          ],
        ),
      ),
      if (summary.topRated.isNotEmpty)
        _StoryCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Eyebrow(l10n.yearTopRated, muted: true),
              const SizedBox(height: PfSpace.md),
              for (final (i, entry) in summary.topRated.take(5).indexed)
                _RankedGame(rank: i + 1, entry: entry),
            ],
          ),
        ),
      if (stats.topGenres.isNotEmpty)
        _StoryCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Eyebrow(l10n.yearTopGenres, muted: true),
              const SizedBox(height: PfSpace.md),
              Wrap(
                spacing: PfSpace.sm,
                runSpacing: PfSpace.sm,
                children: [
                  for (final g in stats.topGenres.take(6))
                    Chip(label: Text(l10n.yearGenreChip(g.name, g.count))),
                ],
              ),
            ],
          ),
        ),
      if (summary.firstFinished != null)
        _StoryCard(
          child: _FeaturedGame(
            label: l10n.yearFirstFinished,
            entry: summary.firstFinished!,
          ),
        ),
      _StoryCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Eyebrow(l10n.yearShareEyebrow, muted: true),
            const SizedBox(height: PfSpace.md),
            Center(
              child: RepaintBoundary(
                key: shareKey,
                child: YearShareCard(
                  year: year,
                  summary: summary,
                  topGenre: stats.topGenres.isEmpty
                      ? null
                      : stats.topGenres.first.name,
                ),
              ),
            ),
            const SizedBox(height: PfSpace.lg),
            Center(
              child: OutlinedButton.icon(
                key: const Key('year_share_card_button'),
                onPressed: onShare,
                icon: const Icon(Icons.ios_share),
                label: Text(l10n.yearShareAction),
              ),
            ),
          ],
        ),
      ),
    ];

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        PfSpace.lg,
        PfSpace.sm,
        PfSpace.lg,
        PfSpace.xxxl,
      ),
      itemCount: cards.length,
      separatorBuilder: (_, _) => const SizedBox(height: PfSpace.lg),
      itemBuilder: (context, index) => MaxWidthBox(
        maxWidth: PfBreakpoints.narrow,
        child: StaggeredReveal(index: index, offset: 24, child: cards[index]),
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({required this.child, this.accent = false});

  final Widget child;

  /// The intro card carries the screen's single ember accent.
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final colors = context.pfColors;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 200),
      padding: const EdgeInsets.all(PfSpace.xl),
      decoration: BoxDecoration(
        borderRadius: PfRadius.xlAll,
        color: accent ? null : colors.surface1,
        gradient: accent
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.alphaBlend(
                    colors.ember.withValues(alpha: colors.isDark ? 0.24 : 0.16),
                    colors.surface1,
                  ),
                  colors.surface1,
                ],
              )
            : null,
        border: Border.all(
          color: accent
              ? colors.ember.withValues(alpha: 0.45)
              : colors.hairline,
        ),
      ),
      child: child,
    );
  }
}

class _BigStat extends StatelessWidget {
  const _BigStat({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Eyebrow(label, muted: true),
        const SizedBox(height: PfSpace.xs),
        FittedBox(fit: BoxFit.scaleDown, child: child),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: PfRadius.smAll),
        ),
        const SizedBox(width: PfSpace.xs + 2),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _RankedGame extends StatelessWidget {
  const _RankedGame({required this.rank, required this.entry});

  final int rank;
  final StatsYearEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = context.pfColors;
    return InkWell(
      borderRadius: PfRadius.mdAll,
      onTap: () =>
          openGameDetails(context, entry.igdbId, heroPrefix: kYearHeroPrefix),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: PfSpace.xs + 2),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                '$rank',
                style: PfTypography.monoStyle(colors.textLow, size: 16),
              ),
            ),
            GameCover(
              url: entry.coverUrl,
              width: 40,
              height: 53,
              borderRadius: PfRadius.sm,
              heroTag: gameCoverHeroTag(kYearHeroPrefix, entry.igdbId),
            ),
            const SizedBox(width: PfSpace.md),
            Expanded(
              child: Text(
                entry.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            ScoreBadge(score: entry.score),
          ],
        ),
      ),
    );
  }
}

class _FeaturedGame extends StatelessWidget {
  const _FeaturedGame({required this.label, required this.entry});

  final String label;
  final StatsYearEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        GameCover(url: entry.coverUrl, width: 96, height: 128),
        const SizedBox(width: PfSpace.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Eyebrow(label, muted: true),
              const SizedBox(height: PfSpace.sm),
              Text(
                entry.name,
                style: theme.textTheme.headlineSmall,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (entry.score != null) ...[
                const SizedBox(height: PfSpace.sm),
                ScoreBadge(score: entry.score),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Branded 4:5 summary card rendered to PNG for sharing. It always uses the
/// dark palette so shared images look the same from either theme.
class YearShareCard extends StatelessWidget {
  const YearShareCard({
    required this.year,
    required this.summary,
    this.topGenre,
    super.key,
  });

  final int year;
  final YearSummary summary;
  final String? topGenre;

  static const double width = 320;

  @override
  Widget build(BuildContext context) {
    const colors = PicklogColors.dark;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final number = NumberFormat.decimalPattern(locale);
    final top = summary.topRated.isEmpty ? null : summary.topRated.first;
    TextStyle mono(double size, [Color? color]) => PfTypography.monoStyle(
      color ?? colors.textHi,
      size: size,
      weight: FontWeight.w600,
    );
    final label = PfTypography.eyebrow(colors.textMed);

    Widget stat(String value, String caption) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: mono(30)),
          ),
          const SizedBox(height: 2),
          Text(caption.toUpperCase(), style: label, maxLines: 1),
        ],
      ),
    );

    return MediaQuery.withNoTextScaling(
      child: Container(
        width: width,
        height: width * 5 / 4,
        padding: const EdgeInsets.all(PfSpace.xl),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: PfRadius.xlAll,
          border: Border.all(color: colors.hairlineStrong),
          gradient: RadialGradient(
            center: const Alignment(0.9, -0.9),
            radius: 1.2,
            colors: [
              Color.alphaBlend(
                colors.ember.withValues(alpha: 0.28),
                colors.surface,
              ),
              colors.surface,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const BrandMark(size: 28, variant: BrandMarkVariant.dark),
                const SizedBox(width: PfSpace.sm),
                Flexible(
                  child: Text(
                    l10n.appTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium!.copyWith(color: colors.textHi),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              l10n.yearInReviewEyebrow.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: PfTypography.eyebrow(colors.emberFg),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('$year', style: mono(64)),
            ),
            const SizedBox(height: PfSpace.lg),
            Row(
              children: [
                stat(number.format(summary.added), l10n.yearShareAdded),
                stat(number.format(summary.finished), l10n.yearShareFinished),
                stat(
                  formatHours(context, summary.playtimeMinutes),
                  l10n.yearShareHours,
                ),
              ],
            ),
            const SizedBox(height: PfSpace.lg),
            if (top != null)
              Text(
                l10n.yearShareTopRated(top.name),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium!.copyWith(color: colors.textHi),
              ),
            if (topGenre != null)
              Text(
                l10n.yearShareTopGenre(topGenre!),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall!.copyWith(color: colors.textMed),
              ),
          ],
        ),
      ),
    );
  }
}

class _StorySkeleton extends StatelessWidget {
  const _StorySkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(PfSpace.lg),
      children: const [
        MaxWidthBox(
          maxWidth: PfBreakpoints.narrow,
          child: SkeletonBox(height: 220, borderRadius: PfRadius.xl),
        ),
        SizedBox(height: PfSpace.lg),
        MaxWidthBox(
          maxWidth: PfBreakpoints.narrow,
          child: SkeletonBox(height: 320, borderRadius: PfRadius.xl),
        ),
      ],
    );
  }
}
