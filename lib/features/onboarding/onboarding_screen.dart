import 'package:flutter/material.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
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
      title: _trackTitle,
      subtitle: _trackSubtitle,
    ),
    OnboardingPageData(
      icon: Icons.explore_outlined,
      title: _discoverTitle,
      subtitle: _discoverSubtitle,
    ),
    OnboardingPageData(
      icon: Icons.favorite_outline,
      title: _shareTitle,
      subtitle: _shareSubtitle,
    ),
  ];

  // Top-level selectors keep [_pages] a `const` list (closures over `context`
  // are resolved later, per build).
  static String _trackTitle(BuildContext c) => c.l10n.onboardingTrackTitle;
  static String _trackSubtitle(BuildContext c) =>
      c.l10n.onboardingTrackSubtitle;
  static String _discoverTitle(BuildContext c) =>
      c.l10n.onboardingDiscoverTitle;
  static String _discoverSubtitle(BuildContext c) =>
      c.l10n.onboardingDiscoverSubtitle;
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
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(context.l10n.onboardingSkip),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) =>
                    _OnboardingPageView(data: _pages[index]),
              ),
            ),
            _PageIndicator(count: _pages.length, currentIndex: _currentPage),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _onNextPressed,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    _isLastPage
                        ? context.l10n.onboardingGetStarted
                        : context.l10n.onboardingNext,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(data.icon, size: 120, color: theme.colorScheme.primary),
          const SizedBox(height: 40),
          Text(
            data.title(context),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            data.subtitle(context),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.count, required this.currentIndex});

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: isActive ? 24 : 8,
          decoration: BoxDecoration(
            color: isActive
                ? colorScheme.primary
                : colorScheme.primary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
