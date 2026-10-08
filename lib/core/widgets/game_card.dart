import 'package:flutter/material.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/widgets/game_cover.dart';
import 'package:picklog/core/widgets/press_scale.dart';
import 'package:picklog/core/widgets/score_badge.dart';

/// Cover ratio used by every game card (IGDB covers are 3:4).
const double kCoverAspectRatio = 3 / 4;

/// Height of a horizontal card rail for a given card width (cover plus a
/// two-line title). Pass the text scaler so large text never clips.
double gameCardRailHeight(
  double cardWidth, [
  TextScaler textScaler = TextScaler.noScaling,
]) => cardWidth / kCoverAspectRatio + GameCard.captionHeightFor(textScaler);

/// Grid child aspect ratio for [GameCard] cells.
const double kGameCardGridAspectRatio = 0.62;

/// Portrait game card for grids and horizontal rails.
///
/// Cover on top (rounded 10, with the [ScoreBadge] on it), title and an
/// optional meta line below. Presses scale the card slightly.
class GameCard extends StatelessWidget {
  const GameCard({
    required this.title,
    required this.onTap,
    this.coverUrl,
    this.score,
    this.heroTag,
    this.subtitle,
    this.overlay,
    this.semanticLabel,
    super.key,
  });

  /// Space reserved under the cover for the title and meta line at 1x text.
  static const double captionHeight = 46;

  /// Caption height for the active text scale.
  static double captionHeightFor(TextScaler scaler) =>
      PfSpace.sm + scaler.scale(captionHeight - PfSpace.sm);

  final String title;
  final VoidCallback? onTap;
  final String? coverUrl;

  /// 0-100 score shown on the cover. Null hides it.
  final int? score;
  final Object? heroTag;
  final String? subtitle;

  /// Optional widget pinned to the cover's top-left (for example a countdown).
  final Widget? overlay;
  final String? semanticLabel;

  /// Title and optional meta line as one paragraph.
  TextSpan _captionSpan(TextTheme textTheme) => TextSpan(
    text: title,
    style: textTheme.titleSmall,
    children: [
      if (subtitle != null)
        TextSpan(text: '\n$subtitle', style: textTheme.bodySmall),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      semanticLabel: semanticLabel ?? title,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _CardCover(
                coverUrl: coverUrl,
                heroTag: heroTag,
                score: score,
                overlay: overlay,
              ),
            ),
            SizedBox(
              height: captionHeightFor(MediaQuery.textScalerOf(context)),
              child: Padding(
                padding: const EdgeInsets.only(top: PfSpace.sm),
                // One paragraph (not a Column) so an unusually tall font
                // clips quietly instead of overflowing the fixed caption.
                child: Text.rich(
                  _captionSpan(Theme.of(context).textTheme),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rounded cover with the hairline border, score badge and overlay slot.
class _CardCover extends StatelessWidget {
  const _CardCover({
    required this.coverUrl,
    required this.heroTag,
    required this.score,
    required this.overlay,
  });

  final String? coverUrl;
  final Object? heroTag;
  final int? score;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    final colors = context.pfColors;

    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: PfRadius.mdAll,
        border: Border.all(color: colors.hairline),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          GameCover(url: coverUrl, heroTag: heroTag),
          if (score != null)
            Positioned(
              top: PfSpace.sm,
              right: PfSpace.sm,
              child: ScoreBadge(score: score, onImage: true),
            ),
          if (overlay != null)
            Positioned(top: PfSpace.sm, left: PfSpace.sm, child: overlay!),
        ],
      ),
    );
  }
}

/// Horizontal game row for lists: cover, title, meta lines and a trailing
/// slot (score, favorite, chevron).
class GameTile extends StatelessWidget {
  const GameTile({
    required this.title,
    required this.onTap,
    this.coverUrl,
    this.heroTag,
    this.meta = const [],
    this.trailing,
    this.semanticLabel,
    this.coverWidth = 56,
    super.key,
  });

  final String title;
  final VoidCallback? onTap;
  final String? coverUrl;
  final Object? heroTag;

  /// Widgets under the title (pills, meta text). Wrapped when space is short.
  final List<Widget> meta;
  final Widget? trailing;
  final String? semanticLabel;
  final double coverWidth;

  @override
  Widget build(BuildContext context) {
    final colors = context.pfColors;

    return Semantics(
      container: true,
      child: Material(
        color: colors.surface1,
        shape: RoundedRectangleBorder(
          borderRadius: PfRadius.cardAll,
          side: BorderSide(color: colors.hairline),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            Expanded(
              child: PressScale(
                onTap: onTap,
                scale: 0.985,
                semanticLabel: semanticLabel ?? title,
                child: ExcludeSemantics(
                  child: _TileBody(
                    title: title,
                    coverUrl: coverUrl,
                    heroTag: heroTag,
                    meta: meta,
                    coverWidth: coverWidth,
                  ),
                ),
              ),
            ),
            if (trailing != null)
              Padding(
                padding: const EdgeInsets.only(right: PfSpace.xs),
                child: trailing!,
              ),
          ],
        ),
      ),
    );
  }
}

/// Cover, title and wrapped meta line inside a [GameTile].
class _TileBody extends StatelessWidget {
  const _TileBody({
    required this.title,
    required this.coverUrl,
    required this.heroTag,
    required this.meta,
    required this.coverWidth,
  });

  final String title;
  final String? coverUrl;
  final Object? heroTag;
  final List<Widget> meta;
  final double coverWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(PfSpace.md),
      child: Row(
        children: [
          GameCover(
            url: coverUrl,
            heroTag: heroTag,
            width: coverWidth,
            height: coverWidth / kCoverAspectRatio,
            borderRadius: PfRadius.sm + 2,
          ),
          const SizedBox(width: PfSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: PfSpace.xs + 2),
                  Wrap(
                    spacing: PfSpace.sm,
                    runSpacing: PfSpace.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: meta,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
