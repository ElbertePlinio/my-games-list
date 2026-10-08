import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:picklog/core/domain/models/app_failure.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/utils/env.dart';
import 'package:picklog/core/utils/error_l10n.dart';
import 'package:picklog/core/utils/image_utils.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/utils/messages_extensions.dart';
import 'package:picklog/core/utils/website_category.dart';
import 'package:picklog/core/widgets/animated_state_switcher.dart';
import 'package:picklog/core/widgets/favorite_button.dart';
import 'package:picklog/core/widgets/game_card.dart';
import 'package:picklog/core/widgets/game_cover.dart';
import 'package:picklog/core/widgets/pf_button.dart';
import 'package:picklog/core/widgets/pf_network_image.dart';
import 'package:picklog/core/widgets/press_scale.dart';
import 'package:picklog/core/widgets/score_badge.dart';
import 'package:picklog/core/widgets/section_header.dart';
import 'package:picklog/core/widgets/state_views.dart';
import 'package:picklog/features/games/bloc/game_details_bloc.dart';
import 'package:picklog/features/games/bloc/game_details_event.dart';
import 'package:picklog/features/games/bloc/game_details_state.dart';
import 'package:picklog/features/games/game_detail_model.dart';
import 'package:picklog/features/games/widgets/discovery_game_tile.dart';
import 'package:picklog/features/games/widgets/game_rail.dart';
import 'package:picklog/features/games/widgets/screenshot_lightbox.dart';
import 'package:picklog/features/games/widgets/skeletons/game_details_skeleton.dart';
import 'package:picklog/features/games/widgets/video_thumbnail_card.dart';
import 'package:picklog/features/library/bloc/library_bloc.dart';
import 'package:picklog/features/library/bloc/library_event.dart';
import 'package:picklog/features/library/bloc/library_state.dart';
import 'package:picklog/features/library/library_entry_model.dart';
import 'package:picklog/features/library/library_formatters.dart';
import 'package:picklog/features/library/widgets/add_to_library_bottom_sheet.dart';
import 'package:picklog/features/library/widgets/library_failure_listener.dart';
import 'package:picklog/features/library/widgets/library_status_pill.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Height of the screenshot header when expanded.
const double kDetailsHeaderHeight = 280;

/// Hero prefix for covers in the similar games rail.
const String _similarHeroPrefix = 'similar-';

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
    return BlocBuilder<GameDetailsBloc, GameDetailsState>(
      builder: (context, state) {
        final Widget child;
        if (state.status == GameDetailsStatus.failure) {
          child = _DetailsError(
            message: (state.errorKind ?? AppErrorKind.unknown).message(context),
            onRetry: () => context.read<GameDetailsBloc>().add(
              GameDetailsLoadRequested(gameId),
            ),
          );
        } else if (state.status == GameDetailsStatus.loading ||
            state.game == null) {
          child = const GameDetailsSkeleton();
        } else {
          child = _GameDetailsContent(
            game: state.game!,
            gameId: gameId,
            heroTagPrefix: heroTagPrefix,
          );
        }
        return AnimatedStateSwitcher(stateKey: state.status, child: child);
      },
    );
  }
}

class _DetailsError extends StatelessWidget {
  const _DetailsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ErrorState(message: message, onRetry: onRetry),
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
  final ScrollController _scrollController = ScrollController();

  /// The cover only joins a Hero flight while it is fully below the pinned
  /// app bar, so a flight never starts under (and paints over) the bar.
  bool _heroEnabled = true;

  /// True once the header has collapsed into the plain app bar, so the
  /// action icons switch from the on-image tone to the theme tone.
  bool _collapsed = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    final enabled = offset < kDetailsHeaderHeight - kToolbarHeight;
    final collapsed = offset > kDetailsHeaderHeight - kToolbarHeight - 24;
    if (enabled != _heroEnabled || collapsed != _collapsed) {
      setState(() {
        _heroEnabled = enabled;
        _collapsed = collapsed;
      });
    }
  }

  LibraryEntry? _findLibraryEntry(LibraryState libraryState) {
    for (final entry in libraryState.entries) {
      if (entry.game.igdbId == widget.gameId) return entry;
    }
    return null;
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
      showDragHandle: false,
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
    final game = widget.game;
    final l10n = context.l10n;

    return LibraryFailureListener(
      child: BlocBuilder<LibraryBloc, LibraryState>(
        builder: (context, libraryState) {
          final entry = _findLibraryEntry(libraryState);
          final width = MediaQuery.sizeOf(context).width;
          final twoPane = width >= PfBreakpoints.twoPane;

          final cover = HeroMode(
            enabled: _heroEnabled,
            child: GameCover(
              url: game.hasCover ? game.cover!.url : null,
              heroTag: gameCoverHeroTag(widget.heroTagPrefix, widget.gameId),
              isHeroDestination: true,
              semanticLabel: l10n.gameCoverLabel(game.name),
              borderRadius: PfRadius.md,
            ),
          );

          final action = _LibraryAction(
            entry: entry,
            onOpenSheet: () => _openLibrarySheet(entry),
          );

          final sections = _DetailSections(game: game);

          return Scaffold(
            body: CustomScrollView(
              controller: _scrollController,
              slivers: [
                _DetailsHeader(
                  game: game,
                  collapsed: _collapsed,
                  actions: [
                    if (entry != null)
                      FavoriteButton(
                        isFavorite: entry.isFavorite,
                        onImage: !_collapsed,
                        addLabel: l10n.addToFavorites,
                        removeLabel: l10n.removeFromFavorites,
                        onPressed: () => _toggleFavorite(entry),
                      ),
                    IconButton(
                      onPressed: _shareGame,
                      icon: const Icon(Icons.share_outlined),
                      tooltip: l10n.share,
                    ),
                    const SizedBox(width: PfSpace.xs),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: PfBreakpoints.content,
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          PfSpace.lg,
                          PfSpace.xl,
                          PfSpace.lg,
                          PfSpace.xxxl +
                              MediaQuery.viewPaddingOf(context).bottom,
                        ),
                        child: twoPane
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 288,
                                    child: _SidePane(
                                      game: game,
                                      cover: cover,
                                      action: action,
                                    ),
                                  ),
                                  const SizedBox(width: PfSpace.xxl),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        _TitleBlock(game: game),
                                        ...sections.main(context),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _CompactHeader(game: game, cover: cover),
                                  const SizedBox(height: PfSpace.xl),
                                  action,
                                  ...sections.tags(context),
                                  ...sections.main(context),
                                  ...sections.links(context),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Collapsible screenshot header with the game name in the collapsed bar.
class _DetailsHeader extends StatelessWidget {
  const _DetailsHeader({
    required this.game,
    required this.actions,
    required this.collapsed,
  });

  final GameDetail game;
  final List<Widget> actions;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final colors = context.pfColors;
    final iconColor = collapsed ? colors.textHi : PicklogColors.onImage;
    // On web Flutter ignores decode caps (the browser decodes), so request a
    // smaller server size for the header instead of the full 1080p.
    const headerSize = kIsWeb ? ImageSize.hd720 : ImageSize.hd1080;
    final headerUrl = game.screenshots.isNotEmpty
        ? getHighResUrl(game.screenshots.first.url, headerSize)
        : (game.hasCover
              ? getHighResUrl(game.cover!.url, ImageSize.coverBig)
              : null);
    final media = MediaQuery.of(context);
    final decodeWidth =
        (math.max(
                  media.size.width,
                  (kDetailsHeaderHeight + media.padding.top) * 16 / 9,
                ) *
                media.devicePixelRatio)
            .round();

    return SliverAppBar(
      expandedHeight: kDetailsHeaderHeight,
      pinned: true,
      stretch: true,
      backgroundColor: colors.surface,
      // Over the screenshot the icons stay light (the scrim keeps them
      // legible); once collapsed onto the surface they use the theme tone.
      foregroundColor: iconColor,
      iconTheme: IconThemeData(color: iconColor),
      actionsIconTheme: IconThemeData(color: iconColor),
      actions: actions,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final collapsedHeight = kToolbarHeight + media.padding.top;
          final collapsed = constraints.maxHeight <= collapsedHeight + 8;
          return FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            titlePadding: const EdgeInsetsDirectional.only(
              start: 56,
              bottom: 16,
              end: 112,
            ),
            title: AnimatedOpacity(
              opacity: collapsed ? 1 : 0,
              duration: PfMotion.of(context, PfMotion.fast),
              child: Text(
                game.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge!.copyWith(color: colors.textHi),
              ),
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (headerUrl != null)
                  Semantics(
                    image: true,
                    label: context.l10n.gameCoverLabel(game.name),
                    child: PfNetworkImage(
                      url: headerUrl,
                      memCacheWidth: decodeWidth,
                      placeholder: const CoverPlaceholder(showIcon: false),
                      error: const CoverPlaceholder(showIcon: false),
                    ),
                  )
                else
                  const CoverPlaceholder(showIcon: false),
                // Scrim: darken the top for the status bar and icons, and
                // fade into the page surface at the bottom.
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.35, 0.7, 1.0],
                      colors: [
                        PicklogColors.imageScrim.withValues(alpha: 0.7),
                        PicklogColors.imageScrim.withValues(alpha: 0.0),
                        colors.surface.withValues(alpha: 0.0),
                        colors.surface,
                      ],
                    ),
                  ),
                ),
                if (collapsed) ColoredBox(color: colors.surface),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Phone header: cover beside the title block.
class _CompactHeader extends StatelessWidget {
  const _CompactHeader({required this.game, required this.cover});

  final GameDetail game;
  final Widget cover;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 112, height: 112 / kCoverAspectRatio, child: cover),
        const SizedBox(width: PfSpace.lg),
        Expanded(child: _TitleBlock(game: game, compact: true)),
      ],
    );
  }
}

/// Eyebrow (genre · year), title, developer, release date and score.
class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.game, this.compact = false});

  final GameDetail game;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.pfColors;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final score = normalizeScore(game.totalRating);

    final eyebrowParts = [
      if (game.genres.isNotEmpty) game.genres.first.name,
      if (game.firstReleaseDate != null) '${game.firstReleaseDate!.year}',
    ];

    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (eyebrowParts.isNotEmpty) ...[
            Eyebrow(eyebrowParts.join(' · ')),
            const SizedBox(height: PfSpace.sm),
          ],
          Text(
            game.name,
            style: compact
                ? theme.textTheme.headlineLarge
                : theme.textTheme.displayMedium,
          ),
          const SizedBox(height: PfSpace.md),
          Wrap(
            spacing: PfSpace.xl,
            runSpacing: PfSpace.md,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (game.developer != null)
                _Fact(label: l10n.developer, value: game.developer!.name),
              if (game.firstReleaseDate != null)
                _Fact(
                  label: l10n.releaseDate,
                  value: DateFormat.yMMMd(
                    locale,
                  ).format(game.firstReleaseDate!),
                ),
              if (score != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScoreRing(
                      score: score,
                      size: 44,
                      semanticLabel: l10n.gameWithScoreLabel(game.name, score),
                    ),
                    const SizedBox(width: PfSpace.sm),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: Text(
                        l10n.igdbScore,
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: colors.textMed,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Eyebrow(label, muted: true),
        const SizedBox(height: 2),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

/// Wide layout left column: large cover, library action, tags and links.
class _SidePane extends StatelessWidget {
  const _SidePane({
    required this.game,
    required this.cover,
    required this.action,
  });

  final GameDetail game;
  final Widget cover;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final sections = _DetailSections(game: game);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(aspectRatio: kCoverAspectRatio, child: cover),
        const SizedBox(height: PfSpace.xl),
        action,
        ...sections.tags(context),
        ...sections.links(context),
      ],
    );
  }
}

/// Add button, or the "In your library" card when the game is tracked.
class _LibraryAction extends StatelessWidget {
  const _LibraryAction({required this.entry, required this.onOpenSheet});

  final LibraryEntry? entry;
  final VoidCallback onOpenSheet;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final entry = this.entry;
    if (entry == null) {
      return PfButton(
        label: l10n.addToLibrary,
        icon: Icons.add,
        onPressed: onOpenSheet,
        size: PfButtonSize.lg,
        expand: true,
      );
    }

    final theme = Theme.of(context);
    final colors = context.pfColors;
    return Container(
      padding: const EdgeInsets.all(PfSpace.lg),
      decoration: BoxDecoration(
        color: colors.surface1,
        borderRadius: PfRadius.cardAll,
        border: Border.all(color: colors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow(l10n.inYourLibrary, muted: true),
          const SizedBox(height: PfSpace.md),
          Wrap(
            spacing: PfSpace.sm,
            runSpacing: PfSpace.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              LibraryStatusPill(status: entry.status),
              if (entry.score != null)
                ScoreBadge(
                  score: entry.score,
                  large: true,
                  semanticLabel: '${l10n.yourScore} ${entry.score}',
                ),
              Text(
                [
                  if (entry.platform != null) entry.platform!.displayName,
                  formatPlaytime(context, entry.playtimeMinutes),
                ].join(' · '),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: PfSpace.lg),
          PfButton(
            label: l10n.editEntry,
            icon: Icons.edit_outlined,
            variant: PfButtonVariant.secondary,
            onPressed: onOpenSheet,
            expand: true,
          ),
        ],
      ),
    );
  }
}

/// Builds the optional sections with spacing only between present ones, so
/// absent data never leaves a gap.
class _DetailSections {
  const _DetailSections({required this.game});

  final GameDetail game;

  static const Widget _gap = SizedBox(height: PfSpace.xl);

  List<Widget> tags(BuildContext context) {
    if (game.genres.isEmpty && game.platforms.isEmpty) return const [];
    return [_gap, _TagsSection(game: game)];
  }

  List<Widget> main(BuildContext context) => [
    if (game.storyline != null || game.summary != null) ...[
      _gap,
      _DescriptionSection(game: game),
    ],
    if (game.screenshots.isNotEmpty) ...[
      _gap,
      _ScreenshotsSection(screenshots: game.screenshots, gameName: game.name),
    ],
    if (game.videos.isNotEmpty) ...[
      _gap,
      _VideosSection(videos: game.videos, gameName: game.name),
    ],
    if (game.similarGames.isNotEmpty) ...[
      _gap,
      _SimilarGamesSection(similarGames: game.similarGames),
    ],
  ];

  List<Widget> links(BuildContext context) {
    if (game.websites.isEmpty) return const [];
    return [_gap, _WebsitesSection(websites: game.websites)];
  }
}

/// Section title inside the details body (no outer padding).
class _BodyTitle extends StatelessWidget {
  const _BodyTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: PfSpace.md),
      child: Semantics(
        header: true,
        child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
      ),
    );
  }
}

class _TagsSection extends StatelessWidget {
  const _TagsSection({required this.game});

  final GameDetail game;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget group(String label, List<String> values) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Eyebrow(label, muted: true),
        const SizedBox(height: PfSpace.sm),
        Wrap(
          spacing: PfSpace.sm,
          runSpacing: PfSpace.sm,
          children: [for (final v in values) Chip(label: Text(v))],
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (game.genres.isNotEmpty)
          group(l10n.genres, [for (final g in game.genres) g.name]),
        if (game.genres.isNotEmpty && game.platforms.isNotEmpty)
          const SizedBox(height: PfSpace.lg),
        if (game.platforms.isNotEmpty)
          group(l10n.platforms, [for (final p in game.platforms) p.name]),
      ],
    );
  }
}

class _DescriptionSection extends StatefulWidget {
  const _DescriptionSection({required this.game});

  final GameDetail game;

  @override
  State<_DescriptionSection> createState() => _DescriptionSectionState();
}

class _DescriptionSectionState extends State<_DescriptionSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.pfColors;
    final l10n = context.l10n;
    final game = widget.game;
    final fullText = [
      if (game.storyline != null) game.storyline!,
      if (game.summary != null) game.summary!,
    ].join('\n\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BodyTitle(l10n.detailsAbout),
        // Selectable so web users can copy descriptions; the toggle stays a
        // normal button outside the selection area.
        SelectionArea(
          child: AnimatedSize(
            duration: PfMotion.of(context, PfMotion.standard),
            curve: PfMotion.forge,
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (game.storyline != null) ...[
                  Eyebrow(l10n.storyline, muted: true),
                  const SizedBox(height: PfSpace.xs + 2),
                  Text(
                    game.storyline!,
                    style: theme.textTheme.bodyLarge,
                    maxLines: _expanded ? null : 3,
                    overflow: _expanded ? null : TextOverflow.ellipsis,
                  ),
                  if (game.summary != null) const SizedBox(height: PfSpace.lg),
                ],
                if (game.summary != null) ...[
                  Eyebrow(l10n.summary, muted: true),
                  const SizedBox(height: PfSpace.xs + 2),
                  Text(
                    game.summary!,
                    style: theme.textTheme.bodyLarge!.copyWith(
                      color: colors.textMed,
                    ),
                    maxLines: _expanded ? null : 4,
                    overflow: _expanded ? null : TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
        if (fullText.length > 200)
          Padding(
            padding: const EdgeInsets.only(top: PfSpace.xs),
            child: TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                foregroundColor: colors.emberFg,
              ),
              child: Text(_expanded ? l10n.readLess : l10n.readMore),
            ),
          ),
      ],
    );
  }
}

class _ScreenshotsSection extends StatelessWidget {
  const _ScreenshotsSection({
    required this.screenshots,
    required this.gameName,
  });

  final List<Screenshot> screenshots;
  final String gameName;

  static const double _height = 150;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.pfColors;
    final urls = [for (final s in screenshots) s.url];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BodyTitle(l10n.screenshots),
        SizedBox(
          height: _height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: screenshots.length,
            separatorBuilder: (_, _) => const SizedBox(width: PfSpace.md),
            itemBuilder: (context, index) {
              return PressScale(
                semanticLabel: l10n.screenshotLabel(gameName),
                onTap: () => ScreenshotLightbox.show(
                  context,
                  urls: urls,
                  initialIndex: index,
                  semanticLabel: l10n.screenshotLabel(gameName),
                ),
                child: Container(
                  width: _height * 16 / 9,
                  decoration: BoxDecoration(
                    borderRadius: PfRadius.mdAll,
                    border: Border.all(color: colors.hairline),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: PfNetworkImage(
                    url: getHighResUrl(
                      screenshots[index].url,
                      ImageSize.screenshotMed,
                    ),
                    // Decode at the thumbnail height, not the full source.
                    memCacheHeight:
                        (_height * MediaQuery.devicePixelRatioOf(context))
                            .round(),
                    placeholder: const CoverPlaceholder(showIcon: false),
                    error: const CoverPlaceholder(),
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
  const _VideosSection({required this.videos, required this.gameName});

  final List<Video> videos;
  final String gameName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BodyTitle(context.l10n.videos),
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: videos.length,
            separatorBuilder: (_, _) => const SizedBox(width: PfSpace.md),
            itemBuilder: (context, index) => VideoThumbnailCard(
              videoId: videos[index].videoId,
              title: gameName,
            ),
          ),
        ),
      ],
    );
  }
}

class _SimilarGamesSection extends StatelessWidget {
  const _SimilarGamesSection({required this.similarGames});

  final List<SimilarGame> similarGames;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BodyTitle(context.l10n.similarGames),
        SizedBox(
          height: railHeight(context),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: similarGames.length,
            separatorBuilder: (_, _) => const SizedBox(width: PfSpace.md),
            itemBuilder: (context, index) {
              final game = similarGames[index];
              return SizedBox(
                width: kRailCardWidth,
                child: GameCard(
                  title: game.name,
                  coverUrl: game.cover?.url,
                  heroTag: gameCoverHeroTag(_similarHeroPrefix, game.id),
                  onTap: () => openGameDetails(
                    context,
                    game.id,
                    heroPrefix: _similarHeroPrefix,
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

class _WebsitesSection extends StatelessWidget {
  const _WebsitesSection({required this.websites});

  final List<Website> websites;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stores = websites
        .where((w) => isStoreCategory(w.category, w.url))
        .toList();
    final otherSites = websites
        .where((w) => !isStoreCategory(w.category, w.url))
        .toList();

    Widget group(String label, List<Website> sites) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Eyebrow(label, muted: true),
        const SizedBox(height: PfSpace.sm),
        Wrap(
          spacing: PfSpace.sm,
          runSpacing: PfSpace.sm,
          children: [for (final w in sites) _WebsiteButton(website: w)],
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (stores.isNotEmpty) group(l10n.whereToBuy, stores),
        if (stores.isNotEmpty && otherSites.isNotEmpty)
          const SizedBox(height: PfSpace.lg),
        if (otherSites.isNotEmpty) group(l10n.links, otherSites),
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
      avatar: Icon(getWebsiteIcon(website.category, website.url), size: 16),
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
