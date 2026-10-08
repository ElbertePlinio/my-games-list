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
import 'package:picklog/core/widgets/game_card.dart';
import 'package:picklog/core/widgets/game_cover.dart';
import 'package:picklog/core/widgets/skeleton_box.dart';
import 'package:picklog/core/widgets/state_views.dart';
import 'package:picklog/core/widgets/status_pill.dart';
import 'package:picklog/features/integrations/bloc/achievement_game_cubit.dart';
import 'package:picklog/features/integrations/integrations_l10n.dart';
import 'package:picklog/features/integrations/integrations_models.dart';
import 'package:picklog/features/integrations/integrations_repository.dart';
import 'package:picklog/features/integrations/widgets/achievement_widgets.dart';

/// Every achievement of one game: unlocked first with date and rarity,
/// locked ones dimmed.
class AchievementGameScreen extends StatelessWidget {
  const AchievementGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AchievementGameCubit, AchievementGameState>(
      builder: (context, state) {
        final cubit = context.read<AchievementGameCubit>();
        final game = state.game;
        final Widget body;
        if (state.status == AchievementGameStatus.failure) {
          body = ErrorState(
            message: (state.errorKind ?? IntegrationErrorKind.unknown).message(
              context,
            ),
            onRetry: cubit.load,
          );
        } else if (game == null) {
          body = const _GameSkeleton();
        } else {
          body = _GameBody(game: game);
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(
              game?.game.name ?? context.l10n.achievementsTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          body: SafeArea(
            top: false,
            child: AnimatedStateSwitcher(
              stateKey: game == null ? state.status : 'ready',
              child: body,
            ),
          ),
        );
      },
    );
  }
}

class _GameBody extends StatelessWidget {
  const _GameBody({required this.game});

  final GameAchievements game;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.pfColors;
    final progress = game.game;
    final achievements = game.sorted;
    final igdbId = progress.igdbId;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        PfSpace.lg,
        PfSpace.sm,
        PfSpace.lg,
        PfSpace.xxl + MediaQuery.viewPaddingOf(context).bottom,
      ),
      children: [
        MaxWidthBox(
          maxWidth: PfBreakpoints.narrow,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: InkWell(
                  onTap: igdbId == null
                      ? null
                      : () => context.pushNamed(
                          AppRouter.gameDetailsName,
                          pathParameters: {'id': '$igdbId'},
                        ),
                  child: Padding(
                    padding: const EdgeInsets.all(PfSpace.lg),
                    child: Row(
                      children: [
                        GameCover(
                          url: progress.coverUrl,
                          width: 64,
                          height: 64 / kCoverAspectRatio,
                          borderRadius: PfRadius.sm + 2,
                          semanticLabel: l10n.gameCoverLabel(progress.name),
                        ),
                        const SizedBox(width: PfSpace.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              StatusPill(
                                label: progress.provider.displayName,
                                tone: PfTone.neutral,
                                icon: progress.provider.icon,
                                dense: true,
                              ),
                              const SizedBox(height: PfSpace.sm),
                              Text(
                                progress.name,
                                style: theme.textTheme.headlineSmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: PfSpace.sm),
                              Row(
                                children: [
                                  Expanded(
                                    child: AchievementProgressBar(
                                      fraction: progress.fraction,
                                    ),
                                  ),
                                  const SizedBox(width: PfSpace.sm),
                                  Text(
                                    '${progress.completionPct.round()}%',
                                    style: PfTypography.monoStyle(
                                      colors.textHi,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: PfSpace.xs),
                              Text(
                                l10n.achievementsUnlockedOf(
                                  progress.unlocked,
                                  progress.total,
                                ),
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: PfSpace.lg),
              if (achievements.isEmpty)
                EmptyState(
                  icon: Icons.emoji_events_outlined,
                  title: l10n.achievementsGameEmpty,
                  compact: true,
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: PfSpace.lg,
                      vertical: PfSpace.sm,
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < achievements.length; i++) ...[
                          if (i > 0) const Divider(height: 1),
                          AchievementTile.fromAchievement(achievements[i]),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GameSkeleton extends StatelessWidget {
  const _GameSkeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.loadingLabel,
      child: ListView(
        padding: const EdgeInsets.all(PfSpace.lg),
        children: [
          MaxWidthBox(
            maxWidth: PfBreakpoints.narrow,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SkeletonBox(height: 120, borderRadius: PfRadius.card),
                const SizedBox(height: PfSpace.lg),
                for (var i = 0; i < 6; i++) ...[
                  const SkeletonBox(height: 60),
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
