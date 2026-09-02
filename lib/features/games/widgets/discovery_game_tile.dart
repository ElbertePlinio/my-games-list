import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:picklog/core/utils/app_router.dart';
import 'package:picklog/core/utils/image_utils.dart';
import 'package:picklog/core/widgets/visibility_hero.dart';
import 'package:picklog/features/games/discovery_game_model.dart';

/// A tile widget displaying a discovery game with cover, name, and rating
class DiscoveryGameTile extends StatelessWidget {
  const DiscoveryGameTile({
    required this.game,
    this.isCompact = false,
    this.heroTagPrefix = '',
    super.key,
  });

  final DiscoveryGame game;
  final bool isCompact;

  /// Namespaces the cover Hero tag so the same game shown in multiple rows
  /// (e.g. recommendations + trending) doesn't collide.
  final String heroTagPrefix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final coverUrl = game.coverUrl != null && game.coverUrl!.isNotEmpty
        ? getHighResUrl(game.coverUrl!, ImageSize.coverBig)
        : null;

    return Container(
      width: isCompact ? 130 : null,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Cover image
            if (coverUrl != null)
              VisibilityHero(
                tag: '${heroTagPrefix}game-cover-${game.id}',
                child: CachedNetworkImage(
                  imageUrl: coverUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (context, url) => Container(
                    color: isDark ? Colors.grey[800] : Colors.grey[300],
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: isDark ? Colors.grey[800] : Colors.grey[300],
                    child: const Icon(Icons.videogame_asset, size: 40),
                  ),
                ),
              )
            else
              Container(
                color: isDark ? Colors.grey[800] : Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.videogame_asset, size: 40),
                ),
              ),

            // Gradient overlay for text readability
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
            ),

            // Rating badge (top right)
            if (game.hasRating)
              Positioned(
                top: 8,
                right: 8,
                child: _RatingBadge(rating: game.totalRating!),
              ),

            // Game name (bottom)
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Text(
                game.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Tap target with web hover/focus affordance, overlaid so the
            // ripple covers the whole tile without altering the layout.
            Positioned.fill(
              child: Material(
                type: MaterialType.transparency,
                child: Semantics(
                  label: game.name,
                  button: true,
                  child: InkWell(
                    onTap: () => context.pushNamed(
                      AppRouter.gameDetailsName,
                      pathParameters: {'id': game.id.toString()},
                      extra: heroTagPrefix.isEmpty ? null : heroTagPrefix,
                    ),
                    mouseCursor: SystemMouseCursors.click,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A circular rating badge showing the rating as a percentage
class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    final color = _getRatingColor(rating);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '${rating.round()}%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 75) return Colors.green;
    if (rating >= 50) return Colors.orange;
    return Colors.red;
  }
}

/// A list tile variant of the discovery game tile for list view mode
class DiscoveryGameListTile extends StatelessWidget {
  const DiscoveryGameListTile({required this.game, super.key});

  final DiscoveryGame game;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final coverUrl = game.coverUrl != null && game.coverUrl!.isNotEmpty
        ? getHighResUrl(game.coverUrl!, ImageSize.coverBig)
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.pushNamed(
          AppRouter.gameDetailsName,
          pathParameters: {'id': game.id.toString()},
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Cover image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 60,
                  height: 80,
                  child: coverUrl != null
                      ? VisibilityHero(
                          tag: 'game-cover-${game.id}',
                          child: CachedNetworkImage(
                            imageUrl: coverUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: isDark
                                  ? Colors.grey[800]
                                  : Colors.grey[300],
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: isDark
                                  ? Colors.grey[800]
                                  : Colors.grey[300],
                              child: const Icon(Icons.videogame_asset),
                            ),
                          ),
                        )
                      : Container(
                          color: isDark ? Colors.grey[800] : Colors.grey[300],
                          child: const Icon(Icons.videogame_asset),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              // Game info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (game.hasRating) ...[
                      const SizedBox(height: 8),
                      _RatingBadge(rating: game.totalRating!),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
