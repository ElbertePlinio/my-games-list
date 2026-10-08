import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picklog/core/services/consent/consent_category.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/widgets/bottom_nav_bar.dart';
import 'package:picklog/features/consent/bloc/consent_cubit.dart';
import 'package:picklog/features/consent/bloc/consent_state.dart';
import 'package:picklog/features/consent/widgets/consent_customize_sheet.dart';

/// Wraps the whole app and shows a non-modal first-run consent banner pinned to
/// the bottom until the user makes an explicit choice.
///
/// Mounted in `MaterialApp.router`'s `builder`, so it overlays every route on
/// every platform — including Flutter Web, satisfying the "web tracking banner"
/// requirement. It is intentionally non-modal: the app stays usable while the
/// banner is up, and no optional data is collected because every category
/// defaults to denied until the user grants it.
///
/// The builder sits ABOVE the Router's Navigator, so the banner hosts its own
/// local [Navigator]. That gives the "Customize" action a Navigator-backed
/// context (the router's Navigator is not an ancestor here) and makes the
/// pushed bottom sheet render above the banner card instead of behind it.
class ConsentBanner extends StatelessWidget {
  const ConsentBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) => PageRouteBuilder<void>(
        settings: settings,
        opaque: true,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, _, _) => _ConsentOverlay(child: child),
      ),
    );
  }
}

class _ConsentOverlay extends StatefulWidget {
  const _ConsentOverlay({required this.child});

  final Widget child;

  @override
  State<_ConsentOverlay> createState() => _ConsentOverlayState();
}

class _ConsentOverlayState extends State<_ConsentOverlay> {
  /// Height the banner covers, measured from the bottom of the screen.
  double _bannerHeight = 0;

  void _onBannerSize(Size size) {
    if (!mounted || size.height == _bannerHeight) return;
    setState(() => _bannerHeight = size.height);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConsentCubit, ConsentState>(
      buildWhen: (previous, current) =>
          previous.hasAnswered != current.hasAnswered ||
          previous.isSaving != current.isSaving,
      builder: (context, state) {
        final visible = !state.hasAnswered;
        return Stack(
          children: [
            ConsentBannerInset(
              bottom: visible ? _bannerHeight : 0,
              child: widget.child,
            ),
            if (visible)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _SizeReporter(
                  onSize: _onBannerSize,
                  child: _ConsentBannerCard(isSaving: state.isSaving),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Height the first-run consent banner covers at the bottom of the screen,
/// or 0 when the banner is hidden.
class ConsentBannerInset extends InheritedWidget {
  const ConsentBannerInset({
    required this.bottom,
    required super.child,
    super.key,
  });

  final double bottom;

  /// The covered height for [context], or 0 outside a [ConsentBanner].
  static double bottomOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<ConsentBannerInset>()
          ?.bottom ??
      0;

  @override
  bool updateShouldNotify(ConsentBannerInset oldWidget) =>
      oldWidget.bottom != bottom;
}

/// Keeps [child] clear of the consent banner, so a screen without a bottom
/// navigation bar never hides its primary action behind it.
///
/// The banner height already includes the bottom system inset, so the inset
/// is removed from [child] to avoid counting it twice.
class ConsentBannerPadding extends StatelessWidget {
  const ConsentBannerPadding({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottom = ConsentBannerInset.bottomOf(context);
    if (bottom == 0) return child;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: MediaQuery.removePadding(
        context: context,
        removeBottom: true,
        child: child,
      ),
    );
  }
}

/// Reports the laid-out size of [child] after each frame where it changed.
class _SizeReporter extends SingleChildRenderObjectWidget {
  const _SizeReporter({required this.onSize, required super.child});

  final ValueChanged<Size> onSize;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSizeReporter(onSize);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderSizeReporter renderObject,
  ) {
    renderObject.onSize = onSize;
  }
}

class _RenderSizeReporter extends RenderProxyBox {
  _RenderSizeReporter(this.onSize);

  ValueChanged<Size> onSize;
  Size? _reported;

  @override
  void performLayout() {
    super.performLayout();
    if (size == _reported) return;
    _reported = size;
    final reported = size;
    WidgetsBinding.instance.addPostFrameCallback((_) => onSize(reported));
  }
}

class _ConsentBannerCard extends StatelessWidget {
  const _ConsentBannerCard({required this.isSaving});

  /// Disables every action while a choice is persisting so a fast second tap
  /// can't start an opposite operation that races the first write.
  final bool isSaving;

  /// Material 3 [NavigationBar] height. The compact banner floats this far
  /// above the bottom so it never covers the tappable bottom nav.
  static const double _navigationBarHeight = 80;

  /// Wide content cap so the banner reads as a centered card rather than a
  /// stretched mobile component on web/desktop viewports.
  static const double _maxContentWidth = 720;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.pfColors;
    final cubit = context.read<ConsentCubit>();
    final media = MediaQuery.of(context);
    // Same breakpoint the app shell uses: compact (< 600px) shows the bottom
    // NavigationBar, wide (>= 600px) shows the side NavigationRail.
    final isCompact = media.size.width < BottomNavBar.railBreakpoint;
    // On compact, clear the bottom NavigationBar (its own height already
    // includes the system inset) plus the system inset so the nav stays
    // tappable. SafeArea handles the inset on wide layouts.
    final bottomOffset = isCompact
        ? _navigationBarHeight + media.viewPadding.bottom
        : 0.0;

    // A floating card on the brand surface. Reject and accept share one
    // style so neither choice is pushed (no dark patterns).
    return SafeArea(
      top: false,
      bottom: !isCompact,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxContentWidth),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              PfSpace.md,
              0,
              PfSpace.md,
              PfSpace.md + bottomOffset,
            ),
            child: Material(
              key: const Key('consent_banner_card'),
              color: colors.surface2,
              shape: RoundedRectangleBorder(
                borderRadius: PfRadius.xlAll,
                side: BorderSide(color: colors.hairlineStrong),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: PfRadius.xlAll,
                  boxShadow: colors.shadowOverlay,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    PfSpace.lg + 4,
                    PfSpace.lg + 2,
                    PfSpace.lg,
                    PfSpace.md,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 18,
                            color: colors.textMed,
                          ),
                          const SizedBox(width: PfSpace.sm),
                          Expanded(
                            child: Text(
                              context.l10n.consentBannerTitle,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: PfSpace.xs + 2),
                      Text(
                        context.l10n.consentBannerBody,
                        style: theme.textTheme.bodyMedium!.copyWith(
                          color: colors.textMed,
                        ),
                      ),
                      const SizedBox(height: PfSpace.md),
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: PfSpace.sm,
                        runSpacing: PfSpace.xs,
                        children: [
                          TextButton(
                            onPressed: isSaving
                                ? null
                                : () => _openCustomize(context, cubit),
                            child: Text(context.l10n.consentCustomize),
                          ),
                          OutlinedButton(
                            onPressed: isSaving ? null : cubit.rejectAll,
                            child: Text(context.l10n.consentRejectAll),
                          ),
                          OutlinedButton(
                            onPressed: isSaving ? null : cubit.acceptAll,
                            child: Text(context.l10n.consentAcceptAll),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openCustomize(BuildContext context, ConsentCubit cubit) async {
    // [context] is under ConsentBanner's local Navigator, so the sheet pushes
    // onto that Navigator and renders above the banner card (the Router's
    // Navigator is not an ancestor of the builder, so it can't be used here).
    final choices = await showModalBottomSheet<Map<ConsentCategory, bool>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: const ConsentCustomizeSheet(),
      ),
    );

    if (choices != null) {
      await cubit.applyChoices(choices);
    }
  }
}
