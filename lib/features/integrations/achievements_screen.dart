import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/pf_typography.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/utils/app_router.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/widgets/animated_state_switcher.dart';
import 'package:picklog/core/widgets/app_scaffold.dart';
import 'package:picklog/core/widgets/pf_button.dart';
import 'package:picklog/core/widgets/section_header.dart';
import 'package:picklog/core/widgets/skeleton_box.dart';
import 'package:picklog/core/widgets/staggered_reveal.dart';
import 'package:picklog/core/widgets/state_views.dart';
import 'package:picklog/features/integrations/bloc/achievements_cubit.dart';
import 'package:picklog/features/integrations/integrations_l10n.dart';
import 'package:picklog/features/integrations/integrations_models.dart';
import 'package:picklog/features/integrations/integrations_repository.dart';
import 'package:picklog/features/integrations/widgets/achievement_widgets.dart';

/// Most recent unlocks shown in the hub.
const int kHubRecentLimit = 6;

/// Opens the per-game achievements screen.
void openAchievementGame(
  BuildContext context,
  GameProvider provider,
  String externalGameId,
) {
  context.pushNamed(
    AppRouter.achievementGameName,
    pathParameters: {
      'provider': provider.apiValue,
      'externalGameId': externalGameId,
    },
  );
}

/// Achievements hub: completion ring, totals per provider, recent unlocks and
/// the games list with a provider filter.
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.achievementsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.link),
            tooltip: l10n.accountsTitle,
            onPressed: () => context.pushNamed(AppRouter.connectedAccountsName),
          ),
          const SizedBox(width: PfSpace.xs),
        ],
      ),
      body: SafeArea(
        top: false,
        child: BlocBuilder<AchievementsCubit, AchievementsState>(
          builder: (context, state) {
            final cubit = context.read<AchievementsCubit>();
            final Widget body;
            final summary = state.summary;
            if (state.status == AchievementsStatus.failure) {
              body = ErrorState(
                message: (state.errorKind ?? IntegrationErrorKind.unknown)
                    .message(context),
                onRetry: cubit.load,
              );
            } else if (summary == null) {
              body = const _HubSkeleton();
            } else if (summary.isEmpty) {
              body = EmptyState(
                icon: Icons.emoji_events_outlined,
                title: l10n.achievementsEmptyTitle,
                message: l10n.achievementsEmptyMessage,
                action: PfButton(
                  label: l10n.achievementsConnectAction,
                  icon: Icons.link,
                  onPressed: () =>
                      context.pushNamed(AppRouter.connectedAccountsName),
                ),
              );
            } else {
              body = RefreshIndicator(
                onRefresh: cubit.load,
                child: _Hub(state: state, summary: summary),
              );
            }
            return AnimatedStateSwitcher(
              stateKey: summary == null
                  ? state.status
                  : (summary.isEmpty ? 'empty' : 'ready'),
              child: body,
            );
          },
        ),
      ),
    );
  }
}

class _Hub extends StatelessWidget {
  const _Hub({required this.state, required this.summary});

  final AchievementsState state;
  final AchievementSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<AchievementsCubit>();
    final games = state.games;
    final providers = state.providersWithGames;
    final recent = summary.recent.take(kHubRecentLimit).toList();

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: MaxWidthBox(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                PfSpace.lg,
                PfSpace.xs,
                PfSpace.lg,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Eyebrow(l10n.achievementsEyebrow),
                  const SizedBox(height: PfSpace.md),
                  _HeroSummary(summary: summary),
                  if (recent.isNotEmpty) ...[
                    SectionHeader(
                      title: l10n.achievementsRecentTitle,
                      padding: const EdgeInsets.only(
                        top: PfSpace.xl,
                        bottom: PfSpace.xs,
                      ),
                    ),
                    _RecentList(recent: recent),
                  ],
                  SectionHeader(
                    title: l10n.achievementsGamesTitle,
                    padding: const EdgeInsets.only(
                      top: PfSpace.xl,
                      bottom: PfSpace.sm,
                    ),
                  ),
                  if (providers.length > 1) ...[
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: Text(l10n.achievementsFilterAll),
                            selected: state.providerFilter == null,
                            onSelected: (_) => cubit.filterProvider(null),
                          ),
                          for (final p in providers) ...[
                            const SizedBox(width: PfSpace.sm),
                            ChoiceChip(
                              avatar: Icon(p.icon, size: 16),
                              label: Text(p.displayName),
                              selected: state.providerFilter == p,
                              onSelected: (_) => cubit.filterProvider(
                                state.providerFilter == p ? null : p,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: PfSpace.md),
                  ],
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.only(
            bottom: PfSpace.xxl + MediaQuery.viewPaddingOf(context).bottom,
          ),
          sliver: SliverList.separated(
            itemCount: games.length,
            separatorBuilder: (_, _) => const SizedBox(height: PfSpace.sm),
            itemBuilder: (context, i) => MaxWidthBox(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: PfSpace.lg),
                child: StaggeredReveal(
                  index: i,
                  child: GameProgressTile(
                    game: games[i],
                    onTap: () => openAchievementGame(
                      context,
                      games[i].provider,
                      games[i].externalGameId,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroSummary extends StatelessWidget {
  const _HeroSummary({required this.summary});

  final AchievementSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.pfColors;

    final totals = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Eyebrow(l10n.achievementsCompletion, muted: true),
        const SizedBox(height: PfSpace.xs),
        Text(
          l10n.achievementsUnlockedOf(
            summary.totalUnlocked,
            summary.totalAvailable,
          ),
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: PfSpace.md),
        for (final p in summary.byProvider)
          Padding(
            padding: const EdgeInsets.only(bottom: PfSpace.sm),
            child: Row(
              children: [
                Icon(p.provider.icon, size: 16, color: colors.textMed),
                const SizedBox(width: PfSpace.sm),
                Expanded(
                  child: Text(
                    '${p.provider.displayName} · '
                    '${l10n.achievementsGamesCount(p.games)}',
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: colors.textHi,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${p.unlocked}/${p.total}',
                  style: PfTypography.monoStyle(colors.textMed, size: 11),
                ),
              ],
            ),
          ),
      ],
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(PfSpace.xl),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final ring = CompletionRing(
              percent: summary.completionPct,
              size: constraints.maxWidth < 360 ? 104 : 128,
              semanticLabel:
                  '${l10n.achievementsCompletion} '
                  '${summary.completionPct.round()}%',
            );
            // Large text needs the full width for the totals.
            final stacked =
                constraints.maxWidth < 300 ||
                MediaQuery.textScalerOf(context).scale(10) > 14;
            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: ring),
                  const SizedBox(height: PfSpace.xl),
                  totals,
                ],
              );
            }
            return Row(
              children: [
                ring,
                const SizedBox(width: PfSpace.xl),
                Expanded(child: totals),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RecentList extends StatelessWidget {
  const _RecentList({required this.recent});

  final List<RecentAchievement> recent;

  Widget _tile(BuildContext context, RecentAchievement r) => InkWell(
    onTap: () => openAchievementGame(context, r.provider, r.externalGameId),
    child: AchievementTile(
      name: r.achievementName,
      subtitle: r.gameName,
      description: r.description,
      iconUrl: r.iconUrl,
      unlocked: true,
      unlockedAt: r.unlockedAt,
      rarityPct: r.rarityPct,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: PfSpace.lg,
          vertical: PfSpace.sm,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Two columns on wide screens so the games list stays in view.
            final columns = constraints.maxWidth >= PfBreakpoints.twoPane - 64
                ? 2
                : 1;
            final rows = <List<RecentAchievement>>[
              for (var i = 0; i < recent.length; i += columns)
                recent.sublist(i, (i + columns).clamp(0, recent.length)),
            ];
            return Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var j = 0; j < columns; j++) ...[
                          if (j > 0) const SizedBox(width: PfSpace.xl),
                          Expanded(
                            child: j < rows[i].length
                                ? _tile(context, rows[i][j])
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HubSkeleton extends StatelessWidget {
  const _HubSkeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.loadingLabel,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          PfSpace.lg,
          PfSpace.xs,
          PfSpace.lg,
          PfSpace.xxl,
        ),
        children: [
          MaxWidthBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SkeletonBox(width: 140, height: 12),
                const SizedBox(height: PfSpace.md),
                const SkeletonBox(height: 176, borderRadius: PfRadius.card),
                const SizedBox(height: PfSpace.xl),
                const SkeletonBox(width: 180, height: 20),
                const SizedBox(height: PfSpace.md),
                for (var i = 0; i < 4; i++) ...[
                  const SkeletonBox(height: 88, borderRadius: PfRadius.card),
                  const SizedBox(height: PfSpace.sm),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
