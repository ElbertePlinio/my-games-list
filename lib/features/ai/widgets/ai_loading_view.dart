import 'dart:async';

import 'package:flutter/material.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/widgets/skeleton_box.dart';

/// Loading state for AI results: shimmering placeholder cards under a short
/// status line that rotates every few seconds.
///
/// The placeholders match [AiPickCardFrame] so nothing jumps when results
/// arrive. Under reduced motion the shimmer stops and the line swaps without
/// a fade.
class AiLoadingView extends StatefulWidget {
  const AiLoadingView({
    required this.lines,
    this.cardCount = 3,
    this.interval = const Duration(milliseconds: 2200),
    super.key,
  });

  final List<String> lines;
  final int cardCount;
  final Duration interval;

  @override
  State<AiLoadingView> createState() => _AiLoadingViewState();
}

class _AiLoadingViewState extends State<AiLoadingView> {
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    if (widget.lines.length > 1) {
      _timer = Timer.periodic(widget.interval, (_) {
        if (mounted) setState(() => _index++);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.pfColors;
    final line = widget.lines.isEmpty
        ? context.l10n.loadingLabel
        : widget.lines[_index % widget.lines.length];

    return Semantics(
      liveRegion: true,
      label: context.l10n.loadingLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                size: 18,
                color: colors.textMed,
              ),
              const SizedBox(width: PfSpace.sm),
              Expanded(
                child: AnimatedSwitcher(
                  duration: PfMotion.of(context, PfMotion.standard),
                  switchInCurve: PfMotion.forge,
                  switchOutCurve: PfMotion.out,
                  layoutBuilder: (current, previous) => Stack(
                    alignment: AlignmentDirectional.centerStart,
                    children: [...previous, ?current],
                  ),
                  child: Text(
                    line,
                    key: ValueKey(line),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: colors.textMed,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: PfSpace.lg),
          for (var i = 0; i < widget.cardCount; i++) ...[
            if (i > 0) const SizedBox(height: PfSpace.md),
            const ExcludeSemantics(child: AiPickCardSkeleton()),
          ],
        ],
      ),
    );
  }
}

/// Cover width used by AI pick cards and their skeletons.
const double kAiPickCoverWidth = 76;

/// Shared frame for AI result cards: a surface card with a hairline.
class AiPickCardFrame extends StatelessWidget {
  const AiPickCardFrame({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.pfColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface1,
        borderRadius: PfRadius.cardAll,
        border: Border.all(color: colors.hairline),
      ),
      child: Padding(padding: const EdgeInsets.all(PfSpace.md), child: child),
    );
  }
}

/// Placeholder in the shape of an AI pick card.
class AiPickCardSkeleton extends StatelessWidget {
  const AiPickCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AiPickCardFrame(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(
            width: kAiPickCoverWidth,
            height: kAiPickCoverWidth * 4 / 3,
            borderRadius: PfRadius.sm + 2,
          ),
          const SizedBox(width: PfSpace.md),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: w * 0.6, height: 16),
                    const SizedBox(height: PfSpace.md),
                    SkeletonBox(width: w, height: 12),
                    const SizedBox(height: PfSpace.xs + 2),
                    SkeletonBox(width: w * 0.85, height: 12),
                    const SizedBox(height: PfSpace.lg),
                    const SkeletonBox(
                      width: 120,
                      height: 32,
                      borderRadius: PfRadius.pill,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
