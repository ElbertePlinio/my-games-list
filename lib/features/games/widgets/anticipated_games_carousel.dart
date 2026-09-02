import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:picklog/core/utils/image_utils.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/widgets/skeleton_box.dart';
import 'package:picklog/core/widgets/visibility_hero.dart';
import 'package:picklog/features/games/anticipated_game_model.dart';
import 'package:picklog/features/games/bloc/anticipated_games_bloc.dart';
import 'package:picklog/features/games/bloc/anticipated_games_event.dart';
import 'package:picklog/features/games/bloc/anticipated_games_state.dart';

/// A carousel widget displaying the most anticipated upcoming games
class AnticipatedGamesCarousel extends StatelessWidget {
  const AnticipatedGamesCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnticipatedGamesBloc, AnticipatedGamesState>(
      builder: (context, state) {
        if (state.isLoading && !state.hasGames) {
          return const _CarouselLoading();
        }

        if (state.status == AnticipatedGamesStatus.failure && !state.hasGames) {
          return _CarouselError(
            message: state.errorMessage ?? context.l10n.failedToLoadGames,
            onRetry: () => context.read<AnticipatedGamesBloc>().add(
              const AnticipatedGamesLoadRequested(),
            ),
          );
        }

        if (!state.hasGames) {
          return const _CarouselEmpty();
        }

        return _CarouselContent(games: state.games);
      },
    );
  }
}

class _CarouselContent extends StatelessWidget {
  const _CarouselContent({required this.games});

  final List<AnticipatedGame> games;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              const Icon(Icons.local_fire_department, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                context.l10n.mostAnticipated,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        CarouselSlider.builder(
          itemCount: games.length,
          itemBuilder: (context, index, realIndex) {
            return _GameCard(game: games[index]);
          },
          options: CarouselOptions(
            height: 220,
            viewportFraction: 0.75,
            enlargeCenterPage: true,
            enlargeFactor: 0.2,
            enableInfiniteScroll: games.length > 2,
            autoPlay: games.length > 1,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.easeInOutCubic,
          ),
        ),
      ],
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.game});

  final AnticipatedGame game;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Use high-res cover URL
    final highResCoverUrl = game.coverUrl.isNotEmpty
        ? getHighResUrl(game.coverUrl, ImageSize.hd720)
        : game.coverUrl;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image with Hero animation
            VisibilityHero(
              tag: 'game-cover-${game.id}',
              child: _GameCoverImage(coverUrl: highResCoverUrl),
            ),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  stops: const [0.4, 1.0],
                ),
              ),
            ),

            // Countdown badge
            Positioned(
              top: 12,
              right: 12,
              child: _CountdownBadge(countdownText: game.countdownText),
            ),

            // Game info
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    game.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.whatshot,
                        color: Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${game.hypes} hypes',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                        ),
                      ),
                      if (game.platforms.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            game.platformNames,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Tap target with web hover/focus affordance, overlaid so the
            // ripple covers the whole card without altering the layout.
            Positioned.fill(
              child: Material(
                type: MaterialType.transparency,
                child: Semantics(
                  label: game.name,
                  button: true,
                  child: InkWell(
                    onTap: () {
                      context.pushNamed(
                        'gameDetails',
                        pathParameters: {'id': game.id.toString()},
                      );
                    },
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

class _GameCoverImage extends StatelessWidget {
  const _GameCoverImage({required this.coverUrl});

  final String coverUrl;

  @override
  Widget build(BuildContext context) {
    if (coverUrl.isEmpty) {
      return Container(
        color: Colors.grey[800],
        child: const Center(
          child: Icon(Icons.videogame_asset, size: 48, color: Colors.white38),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: coverUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey[800],
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[800],
        child: const Center(
          child: Icon(Icons.videogame_asset, size: 48, color: Colors.white38),
        ),
      ),
    );
  }
}

class _CountdownBadge extends StatelessWidget {
  const _CountdownBadge({required this.countdownText});

  final String countdownText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            countdownText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CarouselLoading extends StatelessWidget {
  const _CarouselLoading();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: context.l10n.loadingLabel,
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  context.l10n.mostAnticipated,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 220,
            child: Center(
              child: SizedBox(
                width: MediaQuery.sizeOf(context).width * 0.75,
                height: 180,
                child: const SkeletonBox(borderRadius: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CarouselError extends StatelessWidget {
  const _CarouselError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.failedToLoadGames,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(context.l10n.browseRetry),
            ),
          ],
        ),
      ),
    );
  }
}

class _CarouselEmpty extends StatelessWidget {
  const _CarouselEmpty();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.games_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.noUpcomingGames,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
