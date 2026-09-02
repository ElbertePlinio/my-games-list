import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:picklog/core/utils/env.dart';
import 'package:picklog/core/utils/image_utils.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/utils/messages_extensions.dart';
import 'package:picklog/core/widgets/visibility_hero.dart';
import 'package:picklog/core/utils/website_category.dart';
import 'package:picklog/features/games/bloc/game_details_bloc.dart';
import 'package:picklog/features/games/bloc/game_details_state.dart';
import 'package:picklog/features/games/game_detail_model.dart';
import 'package:picklog/features/games/widgets/skeletons/game_details_skeleton.dart';
import 'package:picklog/features/games/widgets/video_thumbnail_card.dart';
import 'package:picklog/features/library/bloc/library_bloc.dart';
import 'package:picklog/features/library/bloc/library_event.dart';
import 'package:picklog/features/library/bloc/library_state.dart';
import 'package:picklog/features/library/library_entry_model.dart';
import 'package:picklog/features/library/widgets/add_to_library_bottom_sheet.dart';
import 'package:picklog/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Screen displaying detailed game information.
class GameDetailsScreen extends StatelessWidget {
  const GameDetailsScreen({
    super.key,
    required this.gameId,
    this.heroTagPrefix = '',
  });

  final int gameId;
  final String heroTagPrefix;

  @override
  Widget build(BuildContext context) {
    // A shared-element Hero flight into/out of this screen renders in the root
    // navigator overlay and visibly paints over the app bar and bottom
    // navigation bar during the transition. Disable Hero participation for the
    // whole details screen so it simply slides in. The cover Hero tags are
    // kept intact, so a non-overlaying transition can be reintroduced later.
    return HeroMode(
      enabled: false,
      child: BlocBuilder<GameDetailsBloc, GameDetailsState>(
        builder: (context, state) {
          if (state.status == GameDetailsStatus.loading) {
            return const GameDetailsSkeleton();
          }

          if (state.status == GameDetailsStatus.failure) {
            return _ErrorScreen(message: state.errorMessage);
          }

          if (state.game == null) {
            return const GameDetailsSkeleton();
          }

          return _GameDetailsContent(
            game: state.game!,
            gameId: gameId,
            heroTagPrefix: heroTagPrefix,
          );
        },
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                l10n.errorLoadingData,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GameDetailsContent extends StatefulWidget {
  const _GameDetailsContent({
    required this.game,
    required this.gameId,
    this.heroTagPrefix = '',
  });

  final GameDetail game;
  final int gameId;
  final String heroTagPrefix;

  @override
  State<_GameDetailsContent> createState() => _GameDetailsContentState();
}

class _GameDetailsContentState extends State<_GameDetailsContent> {
  bool _isDescriptionExpanded = false;

  LibraryEntry? _findLibraryEntry(LibraryState libraryState) {
    try {
      return libraryState.entries.firstWhere(
        (entry) => entry.game.igdbId == widget.gameId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _shareGame() async {
    final shareUrl = '${Env.webBaseUrl}/games/${widget.gameId}';
    final shareText = context.l10n.shareGameMessage(widget.game.name, shareUrl);
    final box = context.findRenderObject() as RenderBox?;

    try {
      await Share.share(
        shareText,
        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
      );
    } catch (e) {
      debugPrint('Share failed: $e');
      // Fallback: copy to clipboard
      if (mounted) {
        await Clipboard.setData(ClipboardData(text: shareUrl));
        if (mounted) {
          context.showMessage(context.l10n.linkCopied);
        }
      }
    }
  }

  void _toggleFavorite(LibraryEntry entry) {
    context.read<LibraryBloc>().add(
      LibraryToggleFavoriteRequested(entryId: entry.id),
    );
  }

  Future<void> _openLibrarySheet(LibraryEntry? existingEntry) async {
    final libraryBloc = context.read<LibraryBloc>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      anchorPoint: Offset.zero,
      builder: (sheetContext) => BlocProvider.value(
        value: libraryBloc,
        child: AddToLibraryBottomSheet(
          gameId: widget.gameId,
          gameName: widget.game.name,
          platforms: widget.game.platforms,
          existingEntry: existingEntry,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final game = widget.game;

    // On web Flutter ignores decode caps (the browser decodes), so request a
    // smaller server size for the header instead of the full 1080p.
    const headerSize = kIsWeb ? ImageSize.hd720 : ImageSize.hd1080;
    final headerImageUrl = game.screenshots.isNotEmpty
        ? getHighResUrl(game.screenshots.first.url, headerSize)
        : (game.cover != null
              ? getHighResUrl(game.cover!.url, ImageSize.coverBig)
              : null);

    return BlocBuilder<LibraryBloc, LibraryState>(
      builder: (context, libraryState) {
        final libraryEntry = _findLibraryEntry(libraryState);
        final isInLibrary = libraryEntry != null;
        final isFavorite = libraryEntry?.isFavorite ?? false;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // Collapsible App Bar with Screenshot Background
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                // The header sits over a screenshot in both themes, so keep the
                // title and action icons white and rely on the scrim below for
                // contrast (the theme default would render a dark, unreadable
                // title over the image in light mode).
                foregroundColor: Colors.white,
                actions: [
                  // Favorite button (only if in library)
                  if (isInLibrary)
                    IconButton(
                      onPressed: () => _toggleFavorite(libraryEntry),
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.white,
                      ),
                      tooltip: isFavorite
                          ? context.l10n.removeFromFavorites
                          : context.l10n.addToFavorites,
                    ),
                  // Share button
                  IconButton(
                    onPressed: _shareGame,
                    icon: const Icon(Icons.share, color: Colors.white),
                    tooltip: context.l10n.share,
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  // Reserve room on the trailing edge so the collapsed title
                  // never slides under the action icons.
                  titlePadding: const EdgeInsetsDirectional.only(
                    start: 16,
                    bottom: 16,
                    end: 72,
                  ),
                  title: Text(
                    game.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 6,
                          color: Colors.black87,
                        ),
                        // Tight second shadow keeps the title crisp over bright
                        // screenshot regions when the bar is collapsed.
                        Shadow(blurRadius: 2, color: Colors.black),
                      ],
                    ),
                  ),
                  background: headerImageUrl != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Semantics(
                              image: true,
                              label: context.l10n.gameCoverLabel(game.name),
                              child: CachedNetworkImage(
                                imageUrl: headerImageUrl,
                                fit: BoxFit.cover,
                                // Decode at the width BoxFit.cover actually paints
                                // for this 16:9 (1080p) header: the larger of the
                                // screen width and the height-driven width, so it
                                // neither upscales (portrait) nor under-decodes
                                // (wide screens), while bounding source memory.
                                memCacheWidth:
                                    (math.max(
                                              MediaQuery.sizeOf(context).width,
                                              (300 +
                                                      MediaQuery.paddingOf(
                                                        context,
                                                      ).top) *
                                                  16 /
                                                  9,
                                            ) *
                                            MediaQuery.devicePixelRatioOf(
                                              context,
                                            ))
                                        .round(),
                                placeholder: (context, url) =>
                                    Container(color: Colors.grey[900]),
                                errorWidget: (context, url, error) =>
                                    Container(color: Colors.grey[900]),
                              ),
                            ),
                            // Scrim for legibility: darken the top (status-bar
                            // icons + collapsed title) and the bottom (expanded
                            // title) so the white text stays readable over any
                            // screenshot, in both light and dark themes.
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  stops: [0.0, 0.35, 0.6, 1.0],
                                  colors: [
                                    Color(0xB3000000),
                                    Colors.transparent,
                                    Colors.transparent,
                                    Color(0xCC000000),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : Container(color: Colors.grey[900]),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info Row: Cover, Developer, Rating
                      _InfoRow(
                        game: game,
                        gameId: widget.gameId,
                        heroTagPrefix: widget.heroTagPrefix,
                      ),

                      const SizedBox(height: 24),

                      // Genres & Platforms Tags
                      if (game.genres.isNotEmpty || game.platforms.isNotEmpty)
                        _TagsSection(game: game),

                      const SizedBox(height: 24),

                      // Description (Storyline + Summary)
                      if (game.storyline != null || game.summary != null)
                        _DescriptionSection(
                          game: game,
                          isExpanded: _isDescriptionExpanded,
                          onToggle: () {
                            setState(() {
                              _isDescriptionExpanded = !_isDescriptionExpanded;
                            });
                          },
                          l10n: l10n,
                        ),

                      const SizedBox(height: 24),

                      // Screenshots
                      if (game.screenshots.isNotEmpty)
                        _ScreenshotsSection(
                          screenshots: game.screenshots,
                          gameName: game.name,
                          l10n: l10n,
                        ),

                      const SizedBox(height: 24),

                      // Videos
                      if (game.videos.isNotEmpty)
                        _VideosSection(
                          videos: game.videos,
                          gameName: game.name,
                          l10n: l10n,
                        ),

                      const SizedBox(height: 24),

                      // Similar Games
                      if (game.similarGames.isNotEmpty)
                        _SimilarGamesSection(
                          similarGames: game.similarGames,
                          l10n: l10n,
                        ),

                      const SizedBox(height: 24),

                      // Where to Buy / Websites
                      if (game.websites.isNotEmpty)
                        _WebsitesSection(websites: game.websites, l10n: l10n),

                      // Extra space so the last content and the FAB clear the
                      // Android system navigation bar under edge-to-edge.
                      SizedBox(
                        height: 80 + MediaQuery.viewPaddingOf(context).bottom,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: _LibraryFab(
            isInLibrary: isInLibrary,
            status: libraryEntry?.status,
            onPressed: () => _openLibrarySheet(libraryEntry),
          ),
        );
      },
    );
  }
}

class _LibraryFab extends StatelessWidget {
  const _LibraryFab({
    required this.isInLibrary,
    required this.status,
    required this.onPressed,
  });

  final bool isInLibrary;
  final GameStatus? status;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: isInLibrary
          ? theme.colorScheme.secondaryContainer
          : theme.colorScheme.primaryContainer,
      foregroundColor: isInLibrary
          ? theme.colorScheme.onSecondaryContainer
          : theme.colorScheme.onPrimaryContainer,
      elevation: 4,
      icon: Icon(isInLibrary ? Icons.edit : Icons.add),
      label: Text(
        isInLibrary
            ? status!.localizedName(context)
            : context.l10n.addToLibraryShort,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.game,
    required this.gameId,
    this.heroTagPrefix = '',
  });

  final GameDetail game;
  final int gameId;
  final String heroTagPrefix;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cover Image with Hero animation
        if (game.hasCover)
          Hero(
            tag: '${heroTagPrefix}game-cover-$gameId',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Semantics(
                image: true,
                label: l10n.gameCoverLabel(game.name),
                child: CachedNetworkImage(
                  imageUrl: getHighResUrl(game.cover!.url, ImageSize.coverBig),
                  width: 100,
                  height: 140,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 100,
                    height: 140,
                    color: Colors.grey[800],
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 100,
                    height: 140,
                    color: Colors.grey[800],
                    child: const Icon(
                      Icons.videogame_asset,
                      color: Colors.white38,
                    ),
                  ),
                ),
              ),
            ),
          )
        else
          Container(
            width: 100,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.videogame_asset,
              size: 48,
              color: Colors.white38,
            ),
          ),

        const SizedBox(width: 16),

        // Developer & Rating
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Developer
              if (game.developer != null) ...[
                Text(
                  l10n.developer,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  game.developer!.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
              ],

              // Release Date
              if (game.firstReleaseDate != null) ...[
                Text(
                  DateFormat.yMMMd().format(game.firstReleaseDate!),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 12),
              ],

              // Rating
              if (game.totalRating != null) ...[
                Text(
                  l10n.rating,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    RatingBarIndicator(
                      rating: game.fiveStarRating,
                      itemBuilder: (context, _) =>
                          const Icon(Icons.star, color: Colors.amber),
                      itemCount: 5,
                      itemSize: 20,
                      unratedColor: Colors.grey[700],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      game.fiveStarRating.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TagsSection extends StatelessWidget {
  const _TagsSection({required this.game});

  final GameDetail game;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Genres
        if (game.genres.isNotEmpty) ...[
          Text(l10n.genres, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: game.genres.map((genre) {
              return Chip(
                label: Text(genre.name),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // Platforms
        if (game.platforms.isNotEmpty) ...[
          Text(l10n.platforms, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: game.platforms.map((platform) {
              return Chip(
                label: Text(platform.name),
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.secondaryContainer,
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  const _DescriptionSection({
    required this.game,
    required this.isExpanded,
    required this.onToggle,
    required this.l10n,
  });

  final GameDetail game;
  final bool isExpanded;
  final VoidCallback onToggle;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final fullText = [
      if (game.storyline != null) game.storyline!,
      if (game.summary != null) game.summary!,
    ].join('\n\n');

    const maxLines = 4;

    // Make the long-form storyline/summary selectable so web users can copy
    // descriptions. Wrapping only the content text keeps the toggle button and
    // the rest of the screen behaving normally.
    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (game.storyline != null) ...[
            Text(l10n.storyline, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(
              game.storyline!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              maxLines: isExpanded ? null : 3,
              overflow: isExpanded ? null : TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
          ],
          if (game.summary != null) ...[
            Text(l10n.summary, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(
              game.summary!,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: isExpanded ? null : maxLines,
              overflow: isExpanded ? null : TextOverflow.ellipsis,
            ),
          ],
          if (fullText.length > 200)
            TextButton(
              onPressed: onToggle,
              child: Text(isExpanded ? l10n.readLess : l10n.readMore),
            ),
        ],
      ),
    );
  }
}

class _ScreenshotsSection extends StatelessWidget {
  const _ScreenshotsSection({
    required this.screenshots,
    required this.gameName,
    required this.l10n,
  });

  final List<Screenshot> screenshots;
  final String gameName;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.screenshots, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: screenshots.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final screenshot = screenshots[index];
              final imageUrl = getHighResUrl(
                screenshot.url,
                ImageSize.screenshotMed,
              );

              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Semantics(
                  image: true,
                  label: l10n.screenshotLabel(gameName),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: 150,
                    fit: BoxFit.cover,
                    // Decode at the thumbnail height, not the full source.
                    memCacheHeight:
                        (150 * MediaQuery.devicePixelRatioOf(context)).round(),
                    placeholder: (context, url) => Container(
                      width: 267,
                      height: 150,
                      color: Colors.grey[800],
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 267,
                      height: 150,
                      color: Colors.grey[800],
                      child: const Icon(
                        Icons.videogame_asset,
                        color: Colors.white38,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _VideosSection extends StatelessWidget {
  const _VideosSection({
    required this.videos,
    required this.gameName,
    required this.l10n,
  });

  final List<Video> videos;
  final String gameName;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.videos, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 12),
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: videos.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final video = videos[index];
              return VideoThumbnailCard(
                videoId: video.videoId,
                title: gameName,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SimilarGamesSection extends StatelessWidget {
  const _SimilarGamesSection({required this.similarGames, required this.l10n});

  final List<SimilarGame> similarGames;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.similarGames, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: similarGames.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final game = similarGames[index];
              final coverUrl = game.cover != null
                  ? getHighResUrl(game.cover!.url, ImageSize.coverBig)
                  : null;

              return SizedBox(
                width: 100,
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        VisibilityHero(
                          tag: 'game-cover-${game.id}',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: coverUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: coverUrl,
                                    width: 100,
                                    height: 140,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      width: 100,
                                      height: 140,
                                      color: Colors.grey[800],
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                          width: 100,
                                          height: 140,
                                          color: Colors.grey[800],
                                          child: const Icon(
                                            Icons.videogame_asset,
                                            color: Colors.white38,
                                          ),
                                        ),
                                  )
                                : Container(
                                    width: 100,
                                    height: 140,
                                    color: Colors.grey[800],
                                    child: const Icon(
                                      Icons.videogame_asset,
                                      color: Colors.white38,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          game.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
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
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _WebsitesSection extends StatelessWidget {
  const _WebsitesSection({required this.websites, required this.l10n});

  final List<Website> websites;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    // Separate stores from other websites
    final stores = websites
        .where((w) => isStoreCategory(w.category, w.url))
        .toList();
    final otherSites = websites
        .where((w) => !isStoreCategory(w.category, w.url))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Where to Buy section
        if (stores.isNotEmpty) ...[
          Text(l10n.whereToBuy, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: stores.map((website) {
              return _WebsiteButton(website: website);
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // Other links
        if (otherSites.isNotEmpty) ...[
          Text(
            context.l10n.links,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: otherSites.map((website) {
              return _WebsiteButton(website: website);
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class _WebsiteButton extends StatelessWidget {
  const _WebsiteButton({required this.website});

  final Website website;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(getWebsiteIcon(website.category, website.url), size: 18),
      label: Text(getWebsiteName(website.category, website.url)),
      onPressed: () async {
        final uri = Uri.parse(website.url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
    );
  }
}
