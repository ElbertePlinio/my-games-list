import 'package:flutter/material.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/widgets/game_cover.dart';

/// 2x2 grid of up to four covers. Missing slots show a placeholder; an empty
/// collection shows one large placeholder.
class CollectionMosaic extends StatelessWidget {
  const CollectionMosaic({
    required this.coverUrls,
    this.borderRadius = PfRadius.md,
    this.gap = 2,
    super.key,
  });

  final List<String> coverUrls;
  final double borderRadius;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final colors = context.pfColors;
    final urls = coverUrls.take(4).toList();
    Widget content;
    if (urls.isEmpty) {
      content = DecoratedBox(
        decoration: BoxDecoration(color: colors.surface2),
        child: Center(
          child: Icon(
            Icons.collections_bookmark_outlined,
            color: colors.textLow,
            size: 32,
          ),
        ),
      );
    } else {
      Widget cell(int i) => i < urls.length
          ? GameCover(url: urls[i], borderRadius: 0)
          : const CoverPlaceholder(showIcon: false);
      content = Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: cell(0)),
                SizedBox(width: gap),
                Expanded(child: cell(1)),
              ],
            ),
          ),
          SizedBox(height: gap),
          Expanded(
            child: Row(
              children: [
                Expanded(child: cell(2)),
                SizedBox(width: gap),
                Expanded(child: cell(3)),
              ],
            ),
          ),
        ],
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: colors.hairline),
        ),
        child: ColoredBox(color: colors.surface1, child: content),
      ),
    );
  }
}
