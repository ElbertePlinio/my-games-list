import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:picklog/core/utils/app_router.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/widgets/game_card.dart';
import 'package:picklog/core/widgets/score_badge.dart';
import 'package:picklog/features/games/discovery_game_model.dart';

/// Hero tag for a game cover. Each surface passes its own [prefix] so the
/// same game in two rows never shares a tag.
String gameCoverHeroTag(String prefix, int gameId) =>
    '${prefix}game-cover-$gameId';

/// Opens game details and carries the source hero prefix so the cover flies.
void openGameDetails(
  BuildContext context,
  int gameId, {
  String heroPrefix = '',
}) {
  context.pushNamed(
    AppRouter.gameDetailsName,
    pathParameters: {'id': gameId.toString()},
    extra: heroPrefix.isEmpty ? null : heroPrefix,
  );
}

/// Portrait card for a discovery game (cover, score badge, name).
class DiscoveryGameTile extends StatelessWidget {
  const DiscoveryGameTile({
    required this.game,
    this.isCompact = false,
    this.heroTagPrefix = '',
    super.key,
  });

  final DiscoveryGame game;

  /// Kept for call sites that size tiles in rails; the card adapts to its
  /// parent either way.
  final bool isCompact;

  /// Namespaces the cover Hero tag so the same game shown in multiple rows
  /// (e.g. recommendations + trending) doesn't collide.
  final String heroTagPrefix;

  @override
  Widget build(BuildContext context) {
    final score = game.hasRating ? normalizeScore(game.totalRating) : null;
    return GameCard(
      title: game.name,
      coverUrl: game.coverUrl,
      score: score,
      heroTag: gameCoverHeroTag(heroTagPrefix, game.id),
      semanticLabel: score == null
          ? game.name
          : context.l10n.gameWithScoreLabel(game.name, score),
      onTap: () => openGameDetails(context, game.id, heroPrefix: heroTagPrefix),
    );
  }
}

/// List row variant of the discovery game tile.
class DiscoveryGameListTile extends StatelessWidget {
  const DiscoveryGameListTile({
    required this.game,
    this.heroTagPrefix = '',
    super.key,
  });

  final DiscoveryGame game;
  final String heroTagPrefix;

  @override
  Widget build(BuildContext context) {
    final score = game.hasRating ? normalizeScore(game.totalRating) : null;
    return GameTile(
      title: game.name,
      coverUrl: game.coverUrl,
      heroTag: gameCoverHeroTag(heroTagPrefix, game.id),
      semanticLabel: score == null
          ? game.name
          : context.l10n.gameWithScoreLabel(game.name, score),
      meta: [if (score != null) ScoreBadge(score: score)],
      trailing: const Padding(
        padding: EdgeInsets.only(right: 8),
        child: Icon(Icons.chevron_right),
      ),
      onTap: () => openGameDetails(context, game.id, heroPrefix: heroTagPrefix),
    );
  }
}
