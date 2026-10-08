import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/pf_typography.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/utils/app_router.dart';
import 'package:picklog/core/utils/image_utils.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/widgets/game_cover.dart';
import 'package:picklog/core/widgets/pf_page_indicator.dart';
import 'package:picklog/core/widgets/press_scale.dart';
import 'package:picklog/core/widgets/section_header.dart';
import 'package:picklog/core/widgets/skeleton_box.dart';
import 'package:picklog/core/widgets/state_views.dart';
import 'package:picklog/features/games/anticipated_game_model.dart';
import 'package:picklog/features/games/bloc/anticipated_games_bloc.dart';
import 'package:picklog/features/games/bloc/anticipated_games_event.dart';
import 'package:picklog/features/games/bloc/anticipated_games_state.dart';
import 'package:picklog/features/games/discovery_game_model.dart';
import 'package:picklog/features/games/widgets/discovery_game_tile.dart';

const double _carouselHeight = 232;

/// Localized countdown to [game]'s release ("12d 4h 30m", or "Out now").
String anticipatedCountdownLabel(BuildContext context, AnticipatedGame game) {
  final l10n = context.l10n;
  if (game.isReleased) return l10n.countdownReleased;
  final duration = game.timeUntilRelease;
  final days = duration.inDays;
  final hours = duration.inHours % 24;
  final minutes = duration.inMinutes % 60;
  if (days > 0) return l10n.countdownDaysHoursMinutes(days, hours, minutes);
  if (hours > 0) return l10n.countdownHoursMinutes(hours, minutes);
  return l10n.countdownMinutes(minutes);
}

/// A carousel of the most anticipated upcoming games with live countdowns.
class AnticipatedGamesCarousel extends StatelessWidget {
  const AnticipatedGamesCarousel({
    this.heroTagPrefix = 'anticipated-',
    super.key,
  });

  final String heroTagPrefix;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnticipatedGamesBloc, AnticipatedGamesState>(
      builder: (context, state) {
        final l10n = context.l10n;
        final hasContent = state.hasGames;

        final Widget body;
        if (state.isLoading && !state.hasGames) {
          body = const _CarouselLoading();
        } else if (state.status == AnticipatedGamesStatus.failure &&
            !state.hasGames) {
          body = ErrorState(
            compact: true,
            message: l10n.failedToLoadGames,
            onRetry: () => context.read<AnticipatedGamesBloc>().add(
              const AnticipatedGamesLoadRequested(),
            ),
          );
        } else if (!state.hasGames) {
          body = EmptyState(
            compact: true,
            icon: Icons.event_outlined,
            title: l10n.noUpcomingGames,
          );
        } else {
          body = _CarouselContent(
            games: state.games,
            heroTagPrefix: heroTagPrefix,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(
              title: l10n.mostAnticipated,
              seeAllLabel: l10n.seeAll,
              onSeeAll: hasContent
                  ? () => context.pushNamed(
                      AppRouter.discoveryName,
                      pathParameters: {
                        'type': DiscoveryType.upcoming.queryParam,
                      },
                    )
                  : null,
            ),
            body,
          ],
        );
      },
    );
  }
}

class _CarouselContent extends StatefulWidget {
  const _CarouselContent({required this.games, required this.heroTagPrefix});

  final List<AnticipatedGame> games;
  final String heroTagPrefix;

  @override
  State<_CarouselContent> createState() => _CarouselContentState();
}

class _CarouselContentState extends State<_CarouselContent> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final games = widget.games;
    final width = MediaQuery.sizeOf(context).width;
    final fraction = (300 / width).clamp(0.28, 0.78).toDouble();
    final reduced = PfMotion.reduced(context);

    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: games.length,
          itemBuilder: (context, index, realIndex) => _GameCard(
            game: games[index],
            heroTagPrefix: widget.heroTagPrefix,
          ),
          options: CarouselOptions(
            height: _carouselHeight,
            viewportFraction: fraction,
            enlargeCenterPage: true,
            enlargeFactor: 0.16,
            enableInfiniteScroll: games.length > 2,
            autoPlay: games.length > 1 && !reduced,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: PfMotion.reveal,
            autoPlayCurve: PfMotion.forge,
            onPageChanged: (index, _) => setState(() => _index = index),
          ),
        ),
        const SizedBox(height: PfSpace.md),
        PfPageIndicator(
          count: games.length,
          index: _index,
          semanticLabel: context.l10n.pageIndicatorLabel(
            _index + 1,
            games.length,
          ),
        ),
      ],
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.game, required this.heroTagPrefix});

  final AnticipatedGame game;
  final String heroTagPrefix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.pfColors;
    const dark = PicklogColors.dark;

    return PressScale(
      onTap: () => openGameDetails(context, game.id, heroPrefix: heroTagPrefix),
      semanticLabel: game.name,
      scale: 0.985,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: PfSpace.xs,
          vertical: PfSpace.sm,
        ),
        decoration: BoxDecoration(
          borderRadius: PfRadius.xlAll,
          border: Border.all(color: colors.hairline),
          boxShadow: colors.shadowRaised,
        ),
        child: ClipRRect(
          borderRadius: PfRadius.xlAll,
          child: Stack(
            fit: StackFit.expand,
            children: [
              GameCover(
                url: game.coverUrl,
                imageSize: ImageSize.hd720,
                borderRadius: 0,
                heroTag: gameCoverHeroTag(heroTagPrefix, game.id),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      PicklogColors.imageScrim.withValues(alpha: 0),
                      PicklogColors.imageScrim.withValues(alpha: 0.85),
                    ],
                    stops: const [0.35, 1.0],
                  ),
                ),
              ),
              Positioned(
                top: PfSpace.md,
                right: PfSpace.md,
                child: _CountdownBadge(
                  label: anticipatedCountdownLabel(context, game),
                ),
              ),
              Positioned(
                left: PfSpace.md + 2,
                right: PfSpace.md + 2,
                bottom: PfSpace.md + 2,
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        game.name,
                        style: theme.textTheme.titleLarge!.copyWith(
                          color: PicklogColors.onImage,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: PfSpace.xs),
                      Row(
                        children: [
                          Icon(
                            Icons.local_fire_department_outlined,
                            color: dark.textMed,
                            size: 14,
                          ),
                          const SizedBox(width: PfSpace.xs),
                          Text(
                            context.l10n.anticipatedHypes(game.hypes),
                            style: theme.textTheme.labelSmall!.copyWith(
                              color: dark.textHi,
                            ),
                          ),
                          if (game.platforms.isNotEmpty) ...[
                            const SizedBox(width: PfSpace.sm),
                            Expanded(
                              child: Text(
                                game.platformNames,
                                style: theme.textTheme.labelSmall!.copyWith(
                                  color: dark.textMed,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountdownBadge extends StatelessWidget {
  const _CountdownBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    const dark = PicklogColors.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: PicklogColors.imageScrim.withValues(alpha: 0.72),
        borderRadius: PfRadius.pillAll,
        border: Border.all(color: dark.hairlineStrong),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, color: dark.textHi, size: 12),
          const SizedBox(width: PfSpace.xs),
          Text(label, style: PfTypography.monoStyle(dark.textHi, size: 11)),
        ],
      ),
    );
  }
}

class _CarouselLoading extends StatelessWidget {
  const _CarouselLoading();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final fraction = (300 / width).clamp(0.28, 0.78).toDouble();
    return Semantics(
      label: context.l10n.loadingLabel,
      liveRegion: true,
      child: SizedBox(
        height: _carouselHeight + PfSpace.md + 6,
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: width * fraction,
            height: _carouselHeight - PfSpace.lg,
            child: const SkeletonBox(borderRadius: PfRadius.xl),
          ),
        ),
      ),
    );
  }
}
