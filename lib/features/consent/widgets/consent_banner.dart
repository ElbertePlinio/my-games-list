import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picklog/core/services/consent/consent_category.dart';
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

class _ConsentOverlay extends StatelessWidget {
  const _ConsentOverlay({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConsentCubit, ConsentState>(
      buildWhen: (previous, current) =>
          previous.hasAnswered != current.hasAnswered ||
          previous.isSaving != current.isSaving,
      builder: (context, state) {
        return Stack(
          children: [
            child,
            if (!state.hasAnswered)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _ConsentBannerCard(isSaving: state.isSaving),
              ),
          ],
        );
      },
    );
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
    final colors = Theme.of(context).colorScheme;
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

    return Material(
      color: colors.surfaceContainerHigh,
      elevation: 8,
      child: SafeArea(
        top: false,
        bottom: !isCompact,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 12 + bottomOffset),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.consentBannerTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.consentBannerBody,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      TextButton(
                        onPressed: isSaving
                            ? null
                            : () => _openCustomize(context, cubit),
                        child: Text(context.l10n.consentCustomize),
                      ),
                      FilledButton.tonal(
                        onPressed: isSaving ? null : cubit.rejectAll,
                        child: Text(context.l10n.consentRejectAll),
                      ),
                      FilledButton.tonal(
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
    );
  }

  Future<void> _openCustomize(BuildContext context, ConsentCubit cubit) async {
    // [context] is under ConsentBanner's local Navigator, so the sheet pushes
    // onto that Navigator and renders above the banner card (the Router's
    // Navigator is not an ancestor of the builder, so it can't be used here).
    final choices = await showModalBottomSheet<Map<ConsentCategory, bool>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
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
