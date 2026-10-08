import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/widgets/animated_state_switcher.dart';
import 'package:picklog/core/widgets/section_header.dart';
import 'package:picklog/core/widgets/state_views.dart';
import 'package:picklog/features/games/bloc/recommendations_bloc.dart';
import 'package:picklog/features/games/bloc/recommendations_event.dart';
import 'package:picklog/features/games/bloc/recommendations_state.dart';
import 'package:picklog/features/games/discovery_game_model.dart';
import 'package:picklog/features/games/widgets/discovery_game_tile.dart';
import 'package:picklog/features/games/widgets/game_rail.dart';
import 'package:picklog/features/games/widgets/skeletons/discovery_tile_skeleton.dart';

/// Personalized "Recommended for you" rail, derived from the user's library
/// genres (GET /games/recommendations). Shows a skeleton while loading, an
/// inline error with retry on failure, and hides when there is nothing yet.
class RecommendationsWidget extends StatelessWidget {
  const RecommendationsWidget({this.heroTagPrefix = 'rec-', super.key});

  final String heroTagPrefix;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecommendationsBloc, RecommendationsState>(
      builder: (context, state) {
        final Widget body;
        if (state.isLoading && !state.hasGames) {
          body = const DiscoveryRowSkeleton();
        } else if (state.status == RecommendationsStatus.failure &&
            !state.hasGames) {
          body = ErrorState(
            compact: true,
            message: context.l10n.failedToLoadGames,
            onRetry: () => context.read<RecommendationsBloc>().add(
              const RecommendationsLoadRequested(),
            ),
          );
        } else if (!state.hasGames) {
          return const SizedBox.shrink();
        } else {
          final count = state.games.length > 20 ? 20 : state.games.length;
          final showReasons = state.games
              .take(count)
              .any((g) => g.reason != null);
          body = GameRail(
            itemCount: count,
            extraHeight: showReasons
                ? RecommendationReasonLine.heightFor(
                    MediaQuery.textScalerOf(context),
                  )
                : 0,
            itemBuilder: (context, index) {
              final game = state.games[index];
              final tile = DiscoveryGameTile(
                game: game,
                isCompact: true,
                heroTagPrefix: heroTagPrefix,
              );
              if (!showReasons) return tile;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: tile),
                  RecommendationReasonLine(reason: game.reason),
                ],
              );
            },
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(
              title: context.l10n.recommendationsTitle,
              subtitle: context.l10n.recommendationsSubtitle,
            ),
            AnimatedStateSwitcher(stateKey: state.status, child: body),
          ],
        );
      },
    );
  }
}

/// One-line reason under a recommended game ("Because you liked X").
class RecommendationReasonLine extends StatelessWidget {
  const RecommendationReasonLine({required this.reason, super.key});

  final RecommendationReason? reason;

  /// Height of the line for the active text scale.
  static double heightFor(TextScaler scaler) => scaler.scale(18) + PfSpace.xs;

  @override
  Widget build(BuildContext context) {
    final colors = context.pfColors;
    final reason = this.reason;
    final height = heightFor(MediaQuery.textScalerOf(context));
    if (reason == null) return SizedBox(height: height);
    final icon = switch (reason.type) {
      RecommendationReasonType.similar => Icons.favorite_border,
      RecommendationReasonType.genre => Icons.category_outlined,
      RecommendationReasonType.popular => Icons.trending_up,
    };
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.only(top: PfSpace.xs),
        child: Row(
          children: [
            Icon(icon, size: 12, color: colors.textLow),
            const SizedBox(width: PfSpace.xs),
            Expanded(
              child: Text(
                reason.localizedLabel(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall!.copyWith(color: colors.textMed),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
