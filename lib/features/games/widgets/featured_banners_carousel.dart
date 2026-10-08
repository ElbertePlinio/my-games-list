import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/utils/app_router.dart';
import 'package:picklog/core/utils/image_utils.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/widgets/game_cover.dart';
import 'package:picklog/core/widgets/pf_network_image.dart';
import 'package:picklog/core/widgets/pf_page_indicator.dart';
import 'package:picklog/core/widgets/press_scale.dart';
import 'package:picklog/core/widgets/section_header.dart';
import 'package:picklog/core/widgets/skeleton_box.dart';
import 'package:picklog/core/widgets/state_views.dart';
import 'package:picklog/features/games/bloc/featured_banners_bloc.dart';
import 'package:picklog/features/games/bloc/featured_banners_event.dart';
import 'package:picklog/features/games/bloc/featured_banners_state.dart';
import 'package:picklog/features/games/featured_banner_model.dart';

/// Banner height for the available width (taller on wide screens).
double featuredBannerHeight(double width) =>
    (width * 0.42).clamp(180.0, 320.0).toDouble();

/// Hero carousel of editorial featured banners at the top of the home feed.
///
/// Hides when there is nothing curated. A failed load shows an inline retry
/// instead of silently disappearing.
class FeaturedBannersCarousel extends StatelessWidget {
  const FeaturedBannersCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FeaturedBannersBloc, FeaturedBannersState>(
      builder: (context, state) {
        if (state.isLoading && !state.hasBanners) {
          return const _BannersLoading();
        }
        if (state.status == FeaturedBannersStatus.failure &&
            !state.hasBanners) {
          return Padding(
            padding: const EdgeInsets.only(top: PfSpace.lg),
            child: ErrorState(
              compact: true,
              message: context.l10n.featuredError,
              onRetry: () => context.read<FeaturedBannersBloc>().add(
                const FeaturedBannersLoadRequested(),
              ),
            ),
          );
        }
        if (!state.hasBanners) {
          return const SizedBox.shrink();
        }
        return _BannersContent(banners: state.banners);
      },
    );
  }
}

class _BannersContent extends StatefulWidget {
  const _BannersContent({required this.banners});

  final List<FeaturedBanner> banners;

  @override
  State<_BannersContent> createState() => _BannersContentState();
}

class _BannersContentState extends State<_BannersContent> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final banners = widget.banners;
    final width = MediaQuery.sizeOf(context).width;
    final reduced = PfMotion.reduced(context);
    final wide = width >= PfBreakpoints.twoPane;

    return Padding(
      padding: const EdgeInsets.only(top: PfSpace.sm),
      child: Column(
        children: [
          CarouselSlider.builder(
            itemCount: banners.length,
            itemBuilder: (context, index, realIndex) =>
                _BannerCard(banner: banners[index]),
            options: CarouselOptions(
              height: featuredBannerHeight(width),
              viewportFraction: wide ? 0.72 : 0.92,
              enlargeCenterPage: true,
              enlargeFactor: 0.12,
              enableInfiniteScroll: banners.length > 1,
              autoPlay: banners.length > 1 && !reduced,
              autoPlayInterval: const Duration(seconds: 6),
              autoPlayAnimationDuration: PfMotion.reveal,
              autoPlayCurve: PfMotion.forge,
              onPageChanged: (index, _) => setState(() => _index = index),
            ),
          ),
          const SizedBox(height: PfSpace.md),
          PfPageIndicator(
            count: banners.length,
            index: _index,
            semanticLabel: context.l10n.pageIndicatorLabel(
              _index + 1,
              banners.length,
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.banner});

  final FeaturedBanner banner;

  void _onTap(BuildContext context) {
    final game = banner.game;
    if (game == null) return;
    context.pushNamed(
      AppRouter.gameDetailsName,
      pathParameters: {'id': game.igdbId.toString()},
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pfColors;

    return PressScale(
      onTap: banner.game == null ? null : () => _onTap(context),
      semanticLabel: banner.title,
      scale: 0.985,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: PfSpace.xs),
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
              PfNetworkImage(
                url: getHighResUrl(banner.imageUrl, ImageSize.hd720),
                placeholder: const CoverPlaceholder(showIcon: false),
                error: const CoverPlaceholder(),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      PicklogColors.imageScrim.withValues(alpha: 0),
                      PicklogColors.imageScrim.withValues(alpha: 0.82),
                    ],
                    stops: const [0.3, 1.0],
                  ),
                ),
              ),
              Positioned(
                left: PfSpace.lg + 4,
                right: PfSpace.lg + 4,
                bottom: PfSpace.lg + 2,
                child: ExcludeSemantics(child: _BannerCaption(banner: banner)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Eyebrow, title and optional subtitle over the banner scrim.
class _BannerCaption extends StatelessWidget {
  const _BannerCaption({required this.banner});

  final FeaturedBanner banner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSubtitle = banner.subtitle != null && banner.subtitle!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Eyebrow(
          context.l10n.featuredEyebrow,
          color: PicklogColors.onImage.withValues(alpha: 0.72),
        ),
        const SizedBox(height: PfSpace.xs + 2),
        Text(
          banner.title,
          style: theme.textTheme.headlineMedium!.copyWith(
            color: PicklogColors.onImage,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (hasSubtitle) ...[
          const SizedBox(height: PfSpace.xs),
          Text(
            banner.subtitle!,
            style: theme.textTheme.bodyMedium!.copyWith(
              color: PicklogColors.dark.textMed,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

class _BannersLoading extends StatelessWidget {
  const _BannersLoading();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PfSpace.xl,
        PfSpace.sm,
        PfSpace.xl,
        PfSpace.xl + 6,
      ),
      child: SkeletonBox(
        height: featuredBannerHeight(width),
        borderRadius: PfRadius.xl,
      ),
    );
  }
}
