import 'package:flutter/material.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/widgets/brand_mark.dart';
import 'package:picklog/core/widgets/pf_button.dart';
import 'package:picklog/core/widgets/pf_page_indicator.dart';
import 'package:picklog/core/widgets/section_header.dart';
import 'package:picklog/features/onboarding/onboarding_page_data.dart';
import 'package:picklog/features/onboarding/onboarding_service.dart';

/// First-run welcome flow: a few swipeable intro pages shown once per install.
///
/// The screen owns only presentation and the "mark completed" side effect.
/// Where to go afterwards depends on auth state, which the router knows, so the
/// destination is delegated through [onCompleted] instead of being hard-wired
/// here.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    required this.onboardingService,
    required this.onCompleted,
    super.key,
  });

  final OnboardingService onboardingService;

  /// Called after the flag is persisted; the router navigates to the resolved
  /// post-onboarding destination (home when authenticated, otherwise sign in).
  final VoidCallback onCompleted;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isFinishing = false;

  static const List<OnboardingPageData> _pages = [
    OnboardingPageData(
      icon: Icons.sports_esports_outlined,
      eyebrow: _trackEyebrow,
      title: _trackTitle,
      subtitle: _trackSubtitle,
    ),
    OnboardingPageData(
      icon: Icons.explore_outlined,
      eyebrow: _discoverEyebrow,
      title: _discoverTitle,
      subtitle: _discoverSubtitle,
    ),
    OnboardingPageData(
      icon: Icons.favorite_outline,
      eyebrow: _shareEyebrow,
      title: _shareTitle,
      subtitle: _shareSubtitle,
    ),
  ];

  // Top-level selectors keep [_pages] a `const` list (closures over `context`
  // are resolved later, per build).
  static String _trackEyebrow(BuildContext c) => c.l10n.onboardingTrackEyebrow;
  static String _trackTitle(BuildContext c) => c.l10n.onboardingTrackTitle;
  static String _trackSubtitle(BuildContext c) =>
      c.l10n.onboardingTrackSubtitle;
  static String _discoverEyebrow(BuildContext c) =>
      c.l10n.onboardingDiscoverEyebrow;
  static String _discoverTitle(BuildContext c) =>
      c.l10n.onboardingDiscoverTitle;
  static String _discoverSubtitle(BuildContext c) =>
      c.l10n.onboardingDiscoverSubtitle;
  static String _shareEyebrow(BuildContext c) => c.l10n.onboardingShareEyebrow;
  static String _shareTitle(BuildContext c) => c.l10n.onboardingShareTitle;
  static String _shareSubtitle(BuildContext c) =>
      c.l10n.onboardingShareSubtitle;

  bool get _isLastPage => _currentPage == _pages.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNextPressed() {
    if (_isLastPage) {
      _finish();
      return;
    }
    final duration = PfMotion.of(context, PfMotion.slow);
    if (duration == Duration.zero) {
      _pageController.jumpToPage(_currentPage + 1);
    } else {
      _pageController.nextPage(duration: duration, curve: PfMotion.forge);
    }
  }

  Future<void> _finish() async {
    // Guard against double taps racing the persist + navigation.
    if (_isFinishing) return;
    _isFinishing = true;

    await widget.onboardingService.markCompleted();
    if (!mounted) return;
    widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    PfSpace.xl,
                    PfSpace.sm,
                    PfSpace.sm,
                    0,
                  ),
                  child: Row(
                    children: [
                      const Wordmark(markSize: 28),
                      const Spacer(),
                      TextButton(
                        onPressed: _finish,
                        child: Text(context.l10n.onboardingSkip),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (index) =>
                        setState(() => _currentPage = index),
                    itemBuilder: (context, index) =>
                        _OnboardingPageView(data: _pages[index]),
                  ),
                ),
                PfPageIndicator(
                  count: _pages.length,
                  index: _currentPage,
                  semanticLabel: context.l10n.pageIndicatorLabel(
                    _currentPage + 1,
                    _pages.length,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    PfSpace.xl,
                    PfSpace.xl,
                    PfSpace.xl,
                    PfSpace.xxl,
                  ),
                  child: PfButton(
                    label: _isLastPage
                        ? context.l10n.onboardingGetStarted
                        : context.l10n.onboardingNext,
                    onPressed: _onNextPressed,
                    size: PfButtonSize.lg,
                    expand: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingPageView extends StatelessWidget {
  const _OnboardingPageView({required this.data});

  final OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.pfColors;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: PfSpace.xl),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.sizeOf(context).height * 0.55,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: _BracketVisual(icon: data.icon)),
            const SizedBox(height: PfSpace.xxl),
            Eyebrow(data.eyebrow(context)),
            const SizedBox(height: PfSpace.sm),
            Text(data.title(context), style: theme.textTheme.displaySmall),
            const SizedBox(height: PfSpace.md),
            Text(
              data.subtitle(context),
              style: theme.textTheme.bodyLarge!.copyWith(color: colors.textMed),
            ),
          ],
        ),
      ),
    );
  }
}

/// Large framed visual in the mark's language: corner brackets, a centred
/// icon and one ember dot.
class _BracketVisual extends StatelessWidget {
  const _BracketVisual({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.pfColors;
    return ExcludeSemantics(
      child: Container(
        width: 184,
        height: 184,
        decoration: BoxDecoration(
          color: colors.surface1,
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: colors.hairline),
          boxShadow: colors.glowSoft,
        ),
        child: CustomPaint(
          painter: _BracketsPainter(ink: colors.textHi, dot: colors.ember),
          child: Center(child: Icon(icon, size: 64, color: colors.textHi)),
        ),
      ),
    );
  }
}

class _BracketsPainter extends CustomPainter {
  const _BracketsPainter({required this.ink, required this.dot});

  final Color ink;
  final Color dot;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 128;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.square
      ..color = ink.withValues(alpha: 0.85);
    Path path(List<Offset> points) {
      final p = Path()..moveTo(points.first.dx * s, points.first.dy * s);
      for (final o in points.skip(1)) {
        p.lineTo(o.dx * s, o.dy * s);
      }
      return p;
    }

    canvas.drawPath(
      path(const [Offset(26, 44), Offset(26, 26), Offset(44, 26)]),
      paint,
    );
    canvas.drawPath(
      path(const [Offset(26, 84), Offset(26, 102), Offset(44, 102)]),
      paint,
    );
    canvas.drawPath(
      path(const [Offset(84, 102), Offset(102, 102), Offset(102, 84)]),
      paint,
    );
    canvas.drawCircle(Offset(94 * s, 34 * s), 6 * s, Paint()..color = dot);
  }

  @override
  bool shouldRepaint(_BracketsPainter oldDelegate) =>
      oldDelegate.ink != ink || oldDelegate.dot != dot;
}
