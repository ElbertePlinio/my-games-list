import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/pf_typography.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/features/integrations/achievements_screen.dart';
import 'package:picklog/features/integrations/bloc/achievement_game_cubit.dart';
import 'package:picklog/features/integrations/integrations_l10n.dart';
import 'package:picklog/features/integrations/integrations_models.dart';
import 'package:picklog/features/integrations/widgets/achievement_widgets.dart';

/// Achievements shown on the game details screen.
const int kDetailsAchievementPreview = 3;

/// Game details section with the user's achievement progress for this game.
///
/// It appears only when the user has synced data for the game. It renders
/// nothing while loading, on errors, and when the route provides no
/// [GameAchievementsCubit]. It adds its own top gap so an absent section
/// leaves no space.
class GameAchievementsSection extends StatelessWidget {
  const GameAchievementsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final GameAchievementsCubit cubit;
    try {
      cubit = context.read<GameAchievementsCubit>();
    } on ProviderNotFoundException {
      return const SizedBox.shrink();
    }
    return BlocBuilder<GameAchievementsCubit, GameAchievementsState>(
      bloc: cubit,
      builder: (context, state) {
        if (!state.hasData) return const SizedBox.shrink();
        final games = state.games.where((g) => g.game.total > 0).toList();
        return Padding(
          padding: const EdgeInsets.only(top: PfSpace.xl),
          child: _Content(games: games),
        );
      },
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.games});

  final List<GameAchievements> games;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.pfColors;
    final first = games.first;
    final preview = first.sorted.take(kDetailsAchievementPreview).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  l10n.achievementsTitle,
                  style: theme.textTheme.headlineSmall,
                ),
              ),
            ),
            TextButton(
              onPressed: () => openAchievementGame(
                context,
                first.game.provider,
                first.game.externalGameId,
              ),
              style: TextButton.styleFrom(foregroundColor: colors.textMed),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.seeAll),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right, size: 18),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: PfSpace.sm),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(PfSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final g in games) ...[
                  _ProgressRow(game: g.game),
                  const SizedBox(height: PfSpace.md),
                ],
                for (var i = 0; i < preview.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  AchievementTile.fromAchievement(preview[i]),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.game});

  final GameProgress game;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.pfColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(game.provider.icon, size: 16, color: colors.textMed),
            const SizedBox(width: PfSpace.sm),
            Expanded(
              child: Text(
                l10n.achievementsUnlockedOf(game.unlocked, game.total),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            Text(
              '${game.completionPct.round()}%',
              style: PfTypography.monoStyle(colors.textHi),
            ),
          ],
        ),
        const SizedBox(height: PfSpace.sm),
        AchievementProgressBar(fraction: game.fraction),
      ],
    );
  }
}
