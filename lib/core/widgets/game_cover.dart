import 'package:flutter/material.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/utils/image_utils.dart';
import 'package:picklog/core/widgets/pf_network_image.dart';
import 'package:picklog/core/widgets/visibility_hero.dart';

/// Rounded game cover with a themed placeholder and optional Hero.
///
/// Size it with [width]/[height] or with the parent's constraints. Source
/// covers in scrolling lists use [VisibilityHero] so only fully visible tiles
/// fly. Set [isHeroDestination] on detail screens to use a plain [Hero].
class GameCover extends StatelessWidget {
  const GameCover({
    this.url,
    this.heroTag,
    this.isHeroDestination = false,
    this.semanticLabel,
    this.width,
    this.height,
    this.borderRadius = PfRadius.md,
    this.imageSize = ImageSize.coverBig,
    this.memCacheWidth,
    super.key,
  });

  /// IGDB image URL (any size token). Null or empty shows the placeholder.
  final String? url;
  final Object? heroTag;
  final bool isHeroDestination;
  final String? semanticLabel;
  final double? width;
  final double? height;
  final double borderRadius;

  /// IGDB size token the URL is rewritten to.
  final String imageSize;
  final int? memCacheWidth;

  @override
  Widget build(BuildContext context) {
    final resolved = url == null || url!.isEmpty
        ? null
        : getHighResUrl(url!, imageSize);

    Widget image = resolved == null
        ? const CoverPlaceholder()
        : PfNetworkImage(
            url: resolved,
            memCacheWidth: memCacheWidth,
            placeholder: const CoverPlaceholder(showIcon: false),
            error: const CoverPlaceholder(),
          );

    image = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(width: width, height: height, child: image),
    );

    if (semanticLabel != null) {
      image = Semantics(image: true, label: semanticLabel, child: image);
    }

    if (heroTag != null) {
      image = isHeroDestination
          ? Hero(tag: heroTag!, child: image)
          : VisibilityHero(tag: heroTag!, child: image);
    }
    return image;
  }
}

/// Neutral cover placeholder in the surface tokens.
class CoverPlaceholder extends StatelessWidget {
  const CoverPlaceholder({this.showIcon = true, super.key});

  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final colors = context.pfColors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final shortest = constraints.biggest.shortestSide;
        final iconSize = shortest.isFinite
            ? (shortest * 0.32).clamp(16.0, 48.0)
            : 32.0;
        return DecoratedBox(
          decoration: BoxDecoration(color: colors.surface2),
          child: SizedBox.expand(
            child: showIcon
                ? Center(
                    child: Icon(
                      Icons.videogame_asset_outlined,
                      size: iconSize,
                      color: colors.textLow,
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}
