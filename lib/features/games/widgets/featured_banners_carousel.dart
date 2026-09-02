import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:picklog/core/utils/app_router.dart';
import 'package:picklog/core/utils/image_utils.dart';
import 'package:picklog/core/widgets/skeleton_box.dart';
import 'package:picklog/features/games/bloc/featured_banners_bloc.dart';
import 'package:picklog/features/games/bloc/featured_banners_state.dart';
import 'package:picklog/features/games/featured_banner_model.dart';

/// Hero carousel of editorial featured banners at the top of the home feed.
///
/// Banners are optional editorial content, so the section hides itself entirely
/// when there is nothing to show (empty/error) rather than rendering an error.
class FeaturedBannersCarousel extends StatelessWidget {
  const FeaturedBannersCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FeaturedBannersBloc, FeaturedBannersState>(
      builder: (context, state) {
        if (state.isLoading && !state.hasBanners) {
          return const _BannersLoading();
        }
        if (!state.hasBanners) {
          return const SizedBox.shrink();
        }
        return _BannersContent(banners: state.banners);
      },
    );
  }
}

class _BannersContent extends StatelessWidget {
  const _BannersContent({required this.banners});

  final List<FeaturedBanner> banners;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: CarouselSlider.builder(
        itemCount: banners.length,
        itemBuilder: (context, index, realIndex) {
          return _BannerCard(banner: banners[index]);
        },
        options: CarouselOptions(
          height: 180,
          viewportFraction: 0.92,
          enlargeCenterPage: true,
          enlargeFactor: 0.15,
          enableInfiniteScroll: banners.length > 1,
          autoPlay: banners.length > 1,
          autoPlayInterval: const Duration(seconds: 6),
          autoPlayAnimationDuration: const Duration(milliseconds: 800),
          autoPlayCurve: Curves.easeInOutCubic,
        ),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
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
            CachedNetworkImage(
              imageUrl: getHighResUrl(banner.imageUrl, ImageSize.hd720),
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.grey[800]),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[800],
                child: const Icon(Icons.videogame_asset, size: 48),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.75),
                  ],
                  stops: const [0.35, 1.0],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    banner.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (banner.subtitle != null &&
                      banner.subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      banner.subtitle!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Tap target with web hover/focus affordance, overlaid so the
            // ripple covers the whole banner without altering the layout.
            Positioned.fill(
              child: Material(
                type: MaterialType.transparency,
                child: Semantics(
                  label: banner.title,
                  button: banner.game != null,
                  child: InkWell(
                    // Banners may have no linked game — don't offer a dead tap.
                    onTap: banner.game == null ? null : () => _onTap(context),
                    mouseCursor: banner.game == null
                        ? SystemMouseCursors.basic
                        : SystemMouseCursors.click,
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

class _BannersLoading extends StatelessWidget {
  const _BannersLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: SkeletonBox(height: 180, borderRadius: 16),
    );
  }
}
