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

  /// Arrow buttons show only on wide screens with more than one shot.
  bool _showArrows(BuildContext context) =>
      widget.urls.length > 1 &&
      MediaQuery.sizeOf(context).width >= PfBreakpoints.compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
                  itemBuilder: (context, index) => _LightboxPage(
                    url: widget.urls[index],
                    semanticLabel: widget.semanticLabel,
                  ),
                ),
                Positioned(
                  top: PfSpace.sm,
                  left: PfSpace.lg,
                  right: PfSpace.sm,
                  child: _LightboxTopBar(
                    position: l10n.lightboxPosition(_index + 1, total),
                  ),
                ),
                if (_showArrows(context)) ...[
                  _arrow(
                    left: PfSpace.sm,
                    tooltip: l10n.lightboxPrevious,
                    icon: Icons.chevron_left,
                    onPressed: _index > 0 ? () => _go(-1) : null,
                  ),
                  _arrow(
                    right: PfSpace.sm,
                    tooltip: l10n.lightboxNext,
                    icon: Icons.chevron_right,
                    onPressed: _index < total - 1 ? () => _go(1) : null,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Previous or next button, centred on one side edge.
  Widget _arrow({
    required String tooltip,
    required IconData icon,
    required VoidCallback? onPressed,
    double? left,
    double? right,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: 0,
      bottom: 0,
      child: Center(
        child: IconButton(
          tooltip: tooltip,
          color: PicklogColors.dark.textHi,
          onPressed: onPressed,
          icon: Icon(icon, size: 32),
        ),
      ),
    );
  }
}

/// One zoomable screenshot.
class _LightboxPage extends StatelessWidget {
  const _LightboxPage({required this.url, required this.semanticLabel});

  final String url;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: semanticLabel,
      child: InteractiveViewer(
        maxScale: 4,
        child: Center(
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: PfNetworkImage(
              url: getHighResUrl(url, ImageSize.hd1080),
              fit: BoxFit.contain,
              placeholder: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: const CoverPlaceholder(),
            ),
          ),
        ),
      ),
    );
  }
}

/// Position counter and close button.
class _LightboxTopBar extends StatelessWidget {
  const _LightboxTopBar({required this.position});

  final String position;

  @override
  Widget build(BuildContext context) {
    const dark = PicklogColors.dark;
    return Row(
      children: [
        Text(position, style: PfTypography.monoStyle(dark.textHi)),
        const Spacer(),
        IconButton(
          tooltip: context.l10n.lightboxClose,
          color: dark.textHi,
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }
}
