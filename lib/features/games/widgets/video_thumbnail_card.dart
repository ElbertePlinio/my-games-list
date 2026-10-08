import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/utils/app_router.dart';
import 'package:picklog/core/widgets/game_cover.dart';
import 'package:picklog/core/widgets/pf_network_image.dart';
import 'package:picklog/core/widgets/press_scale.dart';

/// A card displaying a YouTube video thumbnail with a play button overlay.
class VideoThumbnailCard extends StatelessWidget {
  const VideoThumbnailCard({
    super.key,
    required this.videoId,
    this.title,
    this.width = 200,
    this.height = 112,
  });

  final String videoId;
  final String? title;
  final double width;
  final double height;

  /// Returns the YouTube thumbnail URL for this video.
  String get thumbnailUrl =>
      'https://img.youtube.com/vi/$videoId/mqdefault.jpg';

  @override
  Widget build(BuildContext context) {
    final colors = context.pfColors;
    const dark = PicklogColors.dark;

    return PressScale(
      semanticLabel: title,
      onTap: () => context.pushNamed(
        AppRouter.videoPlayerName,
        pathParameters: {'videoId': videoId},
        queryParameters: title != null ? {'title': title!} : {},
      ),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: PfRadius.mdAll,
          border: Border.all(color: colors.hairline),
          color: colors.surface2,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PfNetworkImage(
              url: thumbnailUrl,
              placeholder: const CoverPlaceholder(showIcon: false),
              error: const CoverPlaceholder(),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: PicklogColors.imageScrim.withValues(alpha: 0.25),
              ),
            ),
            Center(
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: PicklogColors.imageScrim.withValues(alpha: 0.72),
                  shape: BoxShape.circle,
                  border: Border.all(color: dark.hairlineStrong),
                ),
                child: Icon(Icons.play_arrow_rounded, color: dark.textHi),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
