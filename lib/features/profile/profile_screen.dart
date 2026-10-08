import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/pf_typography.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/utils/app_router.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/widgets/app_scaffold.dart';
import 'package:picklog/core/widgets/game_card.dart';
import 'package:picklog/core/widgets/press_scale.dart';
import 'package:picklog/core/widgets/section_header.dart';
import 'package:picklog/core/widgets/skeleton_box.dart';
import 'package:picklog/core/widgets/staggered_reveal.dart';
import 'package:picklog/core/widgets/state_views.dart';
import 'package:picklog/features/auth/bloc/auth_bloc.dart';
import 'package:picklog/features/auth/bloc/auth_state.dart';
import 'package:picklog/features/games/widgets/discovery_game_tile.dart';
import 'package:picklog/features/games/widgets/game_rail.dart';
import 'package:picklog/features/library/bloc/library_bloc.dart';
import 'package:picklog/features/library/bloc/library_state.dart';
import 'package:picklog/features/library/library_entry_model.dart';
import 'package:picklog/features/library/roulette/backlog_roulette_sheet.dart';
import 'package:picklog/features/library/stats/library_stats_model.dart';
import 'package:picklog/features/library/stats/stats_cubit.dart';
import 'package:picklog/features/library/widgets/library_stats_header.dart';
import 'package:picklog/features/library/widgets/library_status_pill.dart';

/// Hero prefix for the favorites shelf.
const String kProfileHeroPrefix = 'profile-fav-';

/// Up to two initials from a display name.
String profileInitials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'[\s._-]+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return (parts.first.characters.first + parts[1].characters.first)
      .toUpperCase();
}

/// Profile dashboard: who you are, what you play and where to go next.
///
/// User data comes from the global AuthBloc; numbers from [StatsCubit]; the
/// favorites shelf and the roulette read the shared [LibraryBloc]. Account
/// changes live in Settings.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.now});

  /// Clock override for tests.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.profileTitle),
        actions: [
          IconButton(
            key: const Key('profile_settings_button'),
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRouter.settingsPath),
            tooltip: context.l10n.settingsTitle,
          ),
          const SizedBox(width: PfSpace.xs),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is! AuthAuthenticated) {
            // Fallback for non-authenticated state (shouldn't normally happen)
            return EmptyState(
              icon: Icons.person_off_outlined,
              title: context.l10n.noUserInfo,
            );
          }
          return _Dashboard(
            name: state.user.name,
            email: state.user.email,
            year: (now ?? DateTime.now()).year,
          );
        },
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({
    required this.name,
    required this.email,
    required this.year,
  });

  final String name;
  final String email;
  final int year;

  @override
  Widget build(BuildContext context) {
    final statsState = _maybeStats(context);
    final sections = _DashboardSections(
      context,
      statsState: statsState,
      header: _ProfileHeader(
        name: name,
        email: email,
        totalGames: statsState?.stats?.totalGames,
      ),
      yearCard: _YearInReviewCard(year: year),
    );

    return RefreshIndicator(
      onRefresh: () async {
        if (statsState != null) await context.read<StatsCubit>().load();
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= PfBreakpoints.twoPane;
          final children = wide ? sections.wide() : sections.narrow();
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              PfSpace.lg,
              PfSpace.xs,
              PfSpace.lg,
              PfSpace.xxl,
            ),
            child: MaxWidthBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < children.length; i++)
                    StaggeredReveal(index: i, child: children[i]),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static StatsState? _maybeStats(BuildContext context) {
    try {
      return context.watch<StatsCubit>().state;
    } on ProviderNotFoundException {
      return null;
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.totalGames,
  });

  final String name;
  final String email;
  final int? totalGames;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.pfColors;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Eyebrow(l10n.profileEyebrow),
        const SizedBox(height: PfSpace.lg),
        Row(
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.surface2,
                border: Border.all(color: colors.hairlineStrong),
              ),
              child: ExcludeSemantics(
                child: Text(
                  profileInitials(name),
                  style: theme.textTheme.headlineMedium,
                ),
              ),
            ),
            const SizedBox(width: PfSpace.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.headlineLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: colors.textMed,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: PfSpace.xs),
                  Text(
                    totalGames == null
                        ? l10n.profileMemberLine
                        : l10n.profileMemberLineCount(totalGames!),
                    style: PfTypography.monoStyle(colors.textMed, size: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCards extends StatelessWidget {
  const _StatCards({required this.stats, required this.loading});

  final UserStats? stats;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stats = this.stats;
    if (stats == null && !loading) return const SizedBox.shrink();
    final locale = Localizations.localeOf(context).toString();
    final number = NumberFormat.decimalPattern(locale);
    final average = stats?.averageScore;
    final cards = stats == null
        ? null
        : [
            (
              Icons.sports_esports_outlined,
              l10n.profileStatGames,
              number.format(stats.totalGames),
            ),
            (
              Icons.schedule,
              l10n.statsHours,
              formatHours(context, stats.totalPlaytimeMinutes),
            ),
            (
              Icons.star_outline,
              l10n.profileStatAverage,
              average == null ? '-' : average.round().toString(),
            ),
            (
              Icons.bookmark_border,
              l10n.profileStatBacklog,
              number.format(stats.backlogCount),
            ),
          ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 520 ? 4 : 2;
        const spacing = PfSpace.md;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (var i = 0; i < 4; i++)
              SizedBox(
                width: width,
                child: cards == null
                    ? const SkeletonBox(height: 92, borderRadius: PfRadius.card)
                    : _StatCard(
                        icon: cards[i].$1,
                        label: cards[i].$2,
                        value: cards[i].$3,
                      ),
              ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.pfColors;
    return Semantics(
      container: true,
      label: '$label: $value',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(PfSpace.lg),
        decoration: BoxDecoration(
          color: colors.surface1,
          borderRadius: PfRadius.cardAll,
          border: Border.all(color: colors.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: colors.textMed),
            const SizedBox(height: PfSpace.sm),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: PfTypography.monoStyle(
                  colors.textHi,
                  size: 24,
                  weight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Eyebrow(label, muted: true),
          ],
        ),
      ),
    );
  }
}

/// The dashboard's sections, laid out in one column or two.
class _DashboardSections {
  _DashboardSections(
    BuildContext context, {
    required StatsState? statsState,
    required this.header,
    required this.yearCard,
  }) : stats = statsState?.stats,
       loading =
           statsState != null &&
           !statsState.hasStats &&
           statsState.status != StatsStatus.failure,
       failed =
           statsState?.status == StatsStatus.failure &&
           statsState?.stats == null {
    settings = _settingsTile(context);
    error = failed
        ? ErrorState(
            compact: true,
            message: context.l10n.profileStatsFailed,
            onRetry: () => context.read<StatsCubit>().load(),
          )
        : null;
    final stats = this.stats;
    genres = stats == null || stats.topGenres.isEmpty
        ? null
        : _RankedCard(
            title: context.l10n.profileTopGenres,
            items: [for (final g in stats.topGenres.take(5)) (g.name, g.count)],
          );
    platforms = stats == null || stats.topPlatforms.isEmpty
        ? null
        : _RankedCard(
            title: context.l10n.profileTopPlatforms,
            items: [
              for (final p in stats.topPlatforms.take(5))
                (p.displayName, p.count),
            ],
          );
  }

  static const _gap = SizedBox(height: PfSpace.lg);
  static const _favorites = _FavoritesShelf();

  final UserStats? stats;
  final bool loading;
  final bool failed;
  final Widget header;
  final Widget yearCard;
  late final Widget settings;
  late final Widget? error;
  late final Widget? genres;
  late final Widget? platforms;
  late final Widget statCards = _StatCards(stats: stats, loading: loading);
  late final Widget tiles = _ActionTiles(stats: stats);
  late final Widget? distribution = switch (stats) {
    final s? => _StatusDistribution(stats: s),
    null => null,
  };

  static Widget _settingsTile(BuildContext context) => ListTile(
    key: const Key('profile_settings_link'),
    contentPadding: const EdgeInsets.symmetric(horizontal: PfSpace.lg),
    shape: RoundedRectangleBorder(
      borderRadius: PfRadius.cardAll,
      side: BorderSide(color: context.pfColors.hairline),
    ),
    tileColor: context.pfColors.surface1,
    leading: const Icon(Icons.settings_outlined),
    title: Text(context.l10n.settingsTitle),
    subtitle: Text(context.l10n.profileSettingsHint),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => context.push(AppRouter.settingsPath),
  );

  List<Widget> wide() => [
    header,
    const SizedBox(height: PfSpace.xl),
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ?error,
              if (error != null) _gap,
              statCards,
              if (distribution != null) ...[_gap, distribution!],
              _gap,
              _favorites,
            ],
          ),
        ),
        const SizedBox(width: PfSpace.xl),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              yearCard,
              _gap,
              tiles,
              if (genres != null) ...[_gap, genres!],
              if (platforms != null) ...[_gap, platforms!],
              _gap,
              settings,
            ],
          ),
        ),
      ],
    ),
  ];

  List<Widget> narrow() => [
    header,
    const SizedBox(height: PfSpace.xl),
    ?error,
    if (error != null) _gap,
    statCards,
    _gap,
    yearCard,
    _gap,
    tiles,
    if (distribution != null) ...[_gap, distribution!],
    _gap,
    _favorites,
    if (genres != null) ...[_gap, genres!],
    if (platforms != null) ...[_gap, platforms!],
    _gap,
    settings,
  ];
}

/// Stacked bar of the status counts with a legend.
class _StatusDistribution extends StatelessWidget {
  const _StatusDistribution({required this.stats});

  final UserStats stats;

  Widget _buildBar(PicklogColors colors, int total, List<GameStatus> visible) {
    return ClipRRect(
      borderRadius: PfRadius.pillAll,
      child: SizedBox(
        height: 12,
        child: total == 0
            ? ColoredBox(color: colors.surface3, child: const SizedBox.expand())
            : Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < visible.length; i++) ...[
                    if (i > 0) const SizedBox(width: 2),
                    Expanded(
                      flex: stats.countFor(visible[i]),
                      child: ColoredBox(
                        color: colors.toneFill(visible[i].tone),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pfColors;
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final total = GameStatus.values.fold<int>(
      0,
      (sum, s) => sum + stats.countFor(s),
    );
    final visible = [
      for (final s in GameStatus.values)
        if (stats.countFor(s) > 0) s,
    ];

    return _Card(
      title: l10n.profileStatusDistribution,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: [
              for (final s in visible)
                '${s.localizedName(context)} ${stats.countFor(s)}',
            ].join(', '),
            child: _buildBar(colors, total, visible),
          ),
          const SizedBox(height: PfSpace.md),
          ExcludeSemantics(
            child: Wrap(
              spacing: PfSpace.lg,
              runSpacing: PfSpace.sm,
              children: [
                for (final s in GameStatus.values)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: colors.toneFill(s.tone),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: PfSpace.xs + 2),
                      Text(
                        s.localizedName(context),
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(width: PfSpace.xs),
                      Text(
                        '${stats.countFor(s)}',
                        style: PfTypography.monoStyle(colors.textHi, size: 11),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ranked list with proportional bars (top genres or platforms).
class _RankedCard extends StatelessWidget {
  const _RankedCard({required this.title, required this.items});

  final String title;
  final List<(String, int)> items;

  @override
  Widget build(BuildContext context) {
    final colors = context.pfColors;
    final theme = Theme.of(context);
    final max = items.fold<int>(1, (m, i) => i.$2 > m ? i.$2 : m);
    return _Card(
      title: title,
      child: Column(
        children: [
          for (final (label, count) in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: PfSpace.xs),
              child: Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(width: PfSpace.sm),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, c) => Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          height: 8,
                          width: c.maxWidth * (count / max),
                          decoration: BoxDecoration(
                            color: colors.toneFill(PfTone.info),
                            borderRadius: PfRadius.pillAll,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: PfSpace.sm),
                  Text(
                    '$count',
                    style: PfTypography.monoStyle(colors.textMed, size: 11),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.pfColors;
    return Container(
      padding: const EdgeInsets.all(PfSpace.lg),
      decoration: BoxDecoration(
        color: colors.surface1,
        borderRadius: PfRadius.cardAll,
        border: Border.all(color: colors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Eyebrow(title, muted: true),
          const SizedBox(height: PfSpace.md),
          child,
        ],
      ),
    );
  }
}

/// The ember card of the dashboard: the current year's review.
class _YearInReviewCard extends StatelessWidget {
  const _YearInReviewCard({required this.year});

  final int year;

  @override
  Widget build(BuildContext context) {
    final colors = context.pfColors;
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return PressScale(
      key: const Key('profile_year_in_review'),
      onTap: () => context.pushNamed(
        AppRouter.yearInReviewName,
        pathParameters: {'year': '$year'},
      ),
      semanticLabel: l10n.profileYearInReviewLabel(year),
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(PfSpace.xl),
          decoration: BoxDecoration(
            borderRadius: PfRadius.cardAll,
            border: Border.all(color: colors.ember.withValues(alpha: 0.45)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(
                  colors.ember.withValues(alpha: colors.isDark ? 0.22 : 0.16),
                  colors.surface1,
                ),
                colors.surface1,
              ],
            ),
            boxShadow: colors.glowSoft,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Eyebrow(l10n.yearInReviewEyebrow),
                    const SizedBox(height: PfSpace.sm),
                    Text(
                      '$year',
                      style: PfTypography.monoStyle(
                        colors.textHi,
                        size: 40,
                        weight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: PfSpace.xs),
                    Text(
                      l10n.profileYearInReviewHint,
                      style: theme.textTheme.bodyMedium!.copyWith(
                        color: colors.textMed,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.auto_awesome_outlined,
                color: colors.emberFg,
                size: 32,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Achievements and backlog roulette entry tiles.
class _ActionTiles extends StatelessWidget {
  const _ActionTiles({required this.stats});

  final UserStats? stats;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final achievements = stats?.achievements;
    final backlog = stats?.backlogCount;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _Tile(
            key: const Key('profile_achievements_tile'),
            icon: Icons.emoji_events_outlined,
            title: l10n.profileAchievements,
            value: achievements == null
                ? '-'
                : l10n.profileAchievementsValue(
                    achievements.unlocked,
                    achievements.total,
                  ),
            onTap: () => context.pushNamed(AppRouter.achievementsName),
          ),
        ),
        const SizedBox(width: PfSpace.md),
        Expanded(
          child: _Tile(
            key: const Key('profile_roulette_tile'),
            icon: Icons.casino_outlined,
            title: l10n.rouletteTitle,
            value: backlog == null ? '-' : l10n.profileBacklogValue(backlog),
            onTap: _hasLibrary(context)
                ? () => BacklogRouletteSheet.show(context)
                : null,
          ),
        ),
      ],
    );
  }

  static bool _hasLibrary(BuildContext context) {
    try {
      context.read<LibraryBloc>();
      return true;
    } on ProviderNotFoundException {
      return false;
    }
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.pfColors;
    final theme = Theme.of(context);
    return PressScale(
      onTap: onTap,
      semanticLabel: '$title, $value',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(PfSpace.lg),
          decoration: BoxDecoration(
            color: colors.surface1,
            borderRadius: PfRadius.cardAll,
            border: Border.all(color: colors.hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: colors.textHi),
                  const Spacer(),
                  Icon(Icons.chevron_right, size: 18, color: colors.textLow),
                ],
              ),
              const SizedBox(height: PfSpace.md),
              Text(
                title,
                style: theme.textTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: PfTypography.monoStyle(colors.textMed, size: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rail of favorite games from the shared library.
class _FavoritesShelf extends StatelessWidget {
  const _FavoritesShelf();

  @override
  Widget build(BuildContext context) {
    LibraryBloc? bloc;
    try {
      bloc = context.read<LibraryBloc>();
    } on ProviderNotFoundException {
      return const SizedBox.shrink();
    }
    return BlocBuilder<LibraryBloc, LibraryState>(
      bloc: bloc,
      builder: (context, state) {
        final favorites = state.entries.where((e) => e.isFavorite).toList();
        final l10n = context.l10n;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: PfSpace.md),
              child: Eyebrow(l10n.profileFavorites, muted: true),
            ),
            if (state.isLoading && favorites.isEmpty)
              const SkeletonBox(height: 120, borderRadius: PfRadius.card)
            else if (favorites.isEmpty)
              Text(
                l10n.profileFavoritesEmpty,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (favorites.isNotEmpty)
              SizedBox(
                height: railHeight(context),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: favorites.length,
                  separatorBuilder: (_, _) => const SizedBox(width: PfSpace.md),
                  itemBuilder: (context, index) {
                    final entry = favorites[index];
                    return SizedBox(
                      width: kRailCardWidth,
                      child: GameCard(
                        title: entry.game.name,
                        coverUrl: entry.game.coverUrl,
                        score: entry.score,
                        heroTag: gameCoverHeroTag(
                          kProfileHeroPrefix,
                          entry.game.igdbId,
                        ),
                        subtitle: entry.status.localizedName(context),
                        onTap: () => openGameDetails(
                          context,
                          entry.game.igdbId,
                          heroPrefix: kProfileHeroPrefix,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}
