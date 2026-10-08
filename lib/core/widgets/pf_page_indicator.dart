import 'package:flutter/material.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/picklog_colors.dart';

/// Dot page indicator: the active page is a short pill in the text tone.
///
/// It stays neutral so the screen's single ember accent stays the CTA.
class PfPageIndicator extends StatelessWidget {
  const PfPageIndicator({
    required this.count,
    required this.index,
    this.semanticLabel,
    super.key,
  });

  final int count;
  final int index;

  /// Spoken position, for example "Page 2 of 5".
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox.shrink();
    final colors = context.pfColors;
    final duration = PfMotion.of(context, PfMotion.standard);

    return Semantics(
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: duration,
              curve: PfMotion.forge,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 6,
              width: i == index ? 20 : 6,
              decoration: BoxDecoration(
                color: i == index ? colors.textHi : colors.hairlineStrong,
                borderRadius: PfRadius.pillAll,
              ),
            ),
        ],
      ),
    );
  }
}
