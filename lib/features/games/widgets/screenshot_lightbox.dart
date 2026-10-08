import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/pf_typography.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/utils/image_utils.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/widgets/game_cover.dart';
import 'package:picklog/core/widgets/pf_network_image.dart';

/// Full-screen screenshot viewer: swipe between shots, pinch to zoom, arrow
/// keys and Escape on desktop and web.
class ScreenshotLightbox extends StatefulWidget {
  const ScreenshotLightbox({
    required this.urls,
    this.initialIndex = 0,
    this.semanticLabel,
    super.key,
  });

  /// IGDB screenshot URLs (any size token).
  final List<String> urls;
  final int initialIndex;
  final String? semanticLabel;

  /// Opens the viewer over the current screen.
  static Future<void> show(
    BuildContext context, {
    required List<String> urls,
    int initialIndex = 0,
    String? semanticLabel,
  }) {
    final reduced = PfMotion.reduced(context);
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: PicklogColors.imageScrim.withValues(alpha: 0.94),
      transitionDuration: reduced ? Duration.zero : PfMotion.fast,
      pageBuilder: (_, _, _) => ScreenshotLightbox(
        urls: urls,
        initialIndex: initialIndex,
        semanticLabel: semanticLabel,
      ),
      transitionBuilder: (_, animation, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: PfMotion.forge),
        child: child,
      ),
    );
  }

  @override
  State<ScreenshotLightbox> createState() => _ScreenshotLightboxState();
}

class _ScreenshotLightboxState extends State<ScreenshotLightbox> {
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int delta) {
    final target = (_index + delta).clamp(0, widget.urls.length - 1);
    if (target == _index) return;
    final duration = PfMotion.of(context, PfMotion.standard);
    if (duration == Duration.zero) {
      _controller.jumpToPage(target);
    } else {
      _controller.animateToPage(
        target,
        duration: duration,
        curve: PfMotion.forge,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const dark = PicklogColors.dark;
    final total = widget.urls.length;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _go(-1),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () => _go(1),
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).maybePop(),
      },
      child: Focus(
        autofocus: true,
        child: Material(
          type: MaterialType.transparency,
          child: SafeArea(
            child: Stack(
              children: [
                PageView.builder(
                  controller: _controller,
                  itemCount: total,
                  onPageChanged: (index) => setState(() => _index = index),
                  itemBuilder: (context, index) => Semantics(
                    image: true,
                    label: widget.semanticLabel,
                    child: InteractiveViewer(
                      maxScale: 4,
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: PfNetworkImage(
                            url: getHighResUrl(
                              widget.urls[index],
                              ImageSize.hd1080,
                            ),
                            fit: BoxFit.contain,
                            placeholder: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            error: const CoverPlaceholder(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: PfSpace.sm,
                  left: PfSpace.lg,
                  right: PfSpace.sm,
                  child: Row(
                    children: [
                      Text(
                        l10n.lightboxPosition(_index + 1, total),
                        style: PfTypography.monoStyle(dark.textHi),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: l10n.lightboxClose,
                        color: dark.textHi,
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ],
                  ),
                ),
                if (total > 1 &&
                    MediaQuery.sizeOf(context).width >=
                        PfBreakpoints.compact) ...[
                  Positioned(
                    left: PfSpace.sm,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton(
                        tooltip: l10n.lightboxPrevious,
                        color: dark.textHi,
                        onPressed: _index > 0 ? () => _go(-1) : null,
                        icon: const Icon(Icons.chevron_left, size: 32),
                      ),
                    ),
                  ),
                  Positioned(
                    right: PfSpace.sm,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton(
                        tooltip: l10n.lightboxNext,
                        color: dark.textHi,
                        onPressed: _index < total - 1 ? () => _go(1) : null,
                        icon: const Icon(Icons.chevron_right, size: 32),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
