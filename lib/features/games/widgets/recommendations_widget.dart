import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/features/games/bloc/recommendations_bloc.dart';
import 'package:picklog/features/games/bloc/recommendations_state.dart';
import 'package:picklog/features/games/discovery_game_model.dart';
import 'package:picklog/features/games/widgets/discovery_game_tile.dart';
import 'package:picklog/features/games/widgets/skeletons/discovery_tile_skeleton.dart';

const double _rowHeight = 200;
const double _tileAspectRatio = 0.7;

/// Personalized "Recommended for You" row, derived from the user's library
/// genres (GET /games/recommendations). Shows a skeleton while loading (the
/// common path thanks to the popular fallback) and hides on empty/error.
class RecommendationsWidget extends StatelessWidget {
  const RecommendationsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecommendationsBloc, RecommendationsState>(
      builder: (context, state) {
        if (state.isLoading && !state.hasGames) {
          return const _Section(child: DiscoveryRowSkeleton());
        }
        if (!state.hasGames) {
          return const SizedBox.shrink();
        }
        return _Section(child: _GamesRow(games: state.games));
      },
    );
  }
}

/// Shared header (icon + title) + a row body, matching the discovery sections.
class _Section extends StatelessWidget {
  const _Section({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              ExcludeSemantics(
                child: Icon(
                  Icons.auto_awesome,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.recommendationsTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        child,
      ],
    );
  }
}

class _GamesRow extends StatelessWidget {
  const _GamesRow({required this.games});

  final List<DiscoveryGame> games;

  @override
  Widget build(BuildContext context) {
    final count = games.length > 20 ? 20 : games.length;
    return SizedBox(
      height: _rowHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: count,
        itemBuilder: (context, index) {
          final game = games[index];
          return Padding(
            padding: EdgeInsets.only(right: index < count - 1 ? 12 : 0),
            child: AspectRatio(
              aspectRatio: _tileAspectRatio,
              child: DiscoveryGameTile(
                game: game,
                isCompact: true,
                heroTagPrefix: 'rec-',
              ),
            ),
          );
        },
      ),
    );
  }
}
