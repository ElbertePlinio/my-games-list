import 'package:flutter/material.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/picklog_colors.dart';

/// Heart toggle with a short pop when it turns on.
///
/// The filled heart uses the high-contrast neutral, so ember stays for the
/// one primary action on screen. The pop is skipped under reduced motion.
/// Set [onImage] when the button sits on a photo.
class FavoriteButton extends StatefulWidget {
  const FavoriteButton({
    required this.isFavorite,
    required this.onPressed,
    required this.addLabel,
    required this.removeLabel,
    this.onImage = false,
    this.size = 22,
    super.key,
  });

  final bool isFavorite;
  final VoidCallback? onPressed;

  /// Tooltip and semantics when not a favorite yet.
  final String addLabel;

  /// Tooltip and semantics when already a favorite.
  final String removeLabel;
  final bool onImage;
  final double size;

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: PfMotion.slow,
  );

  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 1.3,
      ).chain(CurveTween(curve: PfMotion.forge)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.3,
        end: 1.0,
      ).chain(CurveTween(curve: PfMotion.curve)),
      weight: 65,
    ),
  ]).animate(_controller);

  @override
  void didUpdateWidget(covariant FavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFavorite &&
        !oldWidget.isFavorite &&
        !PfMotion.reduced(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pfColors;
    final idleColor = widget.onImage ? PicklogColors.onImage : colors.textMed;
    final filledColor = widget.onImage ? PicklogColors.onImage : colors.textHi;
    final label = widget.isFavorite ? widget.removeLabel : widget.addLabel;

    return IconButton(
      tooltip: label,
      onPressed: widget.onPressed,
      icon: ScaleTransition(
        scale: _scale,
        child: Icon(
          widget.isFavorite ? Icons.favorite : Icons.favorite_border,
          size: widget.size,
          color: widget.isFavorite ? filledColor : idleColor,
          semanticLabel: label,
        ),
      ),
    );
  }
}
