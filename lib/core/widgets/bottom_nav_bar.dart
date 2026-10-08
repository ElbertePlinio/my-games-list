import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:picklog/core/theme/pf_tokens.dart';
import 'package:picklog/core/theme/picklog_colors.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/core/widgets/brand_mark.dart';

/// Adaptive primary navigation for the app shell.
///
/// - Below 600: Material 3 bottom [NavigationBar].
/// - 600 to 1199: compact [NavigationRail] with the mark on top.
/// - 1200 and up: extended rail with the wordmark.
///
/// The selected indicator is an ember tint from the theme. Integrates with
/// GoRouter's StatefulShellRoute so each tab keeps its own stack.
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  /// Width at/above which the side rail replaces the bottom bar.
  static const double railBreakpoint = PfBreakpoints.compact;

  /// Width at/above which the rail extends and shows the wordmark.
  static const double extendedBreakpoint = PfBreakpoints.expanded;

  // Single source of destination icons so the bar and rail stay in sync.
  // Labels are resolved from localizations at build time (see [build]).
  static const List<_NavDestination> _destinations = [
    _NavDestination(icon: Icons.home_outlined, selectedIcon: Icons.home),
    _NavDestination(icon: Icons.explore_outlined, selectedIcon: Icons.explore),
    _NavDestination(
      icon: Icons.sports_esports_outlined,
      selectedIcon: Icons.sports_esports,
    ),
    _NavDestination(icon: Icons.person_outline, selectedIcon: Icons.person),
  ];

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.pfColors;
    final labels = [
      l10n.navHome,
      l10n.navBrowse,
      l10n.navLibrary,
      l10n.navProfile,
    ];
    final width = MediaQuery.sizeOf(context).width;

    if (width >= railBreakpoint) {
      final extended = width >= extendedBreakpoint;
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _onDestinationSelected,
              extended: extended,
              minExtendedWidth: 232,
              labelType: extended
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              groupAlignment: -0.85,
              leading: Padding(
                padding: const EdgeInsets.fromLTRB(
                  PfSpace.sm,
                  PfSpace.lg,
                  PfSpace.sm,
                  PfSpace.xl,
                ),
                child: extended
                    ? const Wordmark(markSize: 32)
                    : BrandMark(size: 36, semanticLabel: l10n.appTitle),
              ),
              destinations: [
                for (var i = 0; i < _destinations.length; i++)
                  NavigationRailDestination(
                    icon: Icon(_destinations[i].icon),
                    selectedIcon: Icon(_destinations[i].selectedIcon),
                    label: Text(labels[i]),
                  ),
              ],
            ),
            VerticalDivider(width: 1, thickness: 1, color: colors.hairline),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.hairline)),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _onDestinationSelected,
          animationDuration: PfMotion.of(context, PfMotion.slow),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            for (var i = 0; i < _destinations.length; i++)
              NavigationDestination(
                icon: Icon(_destinations[i].icon),
                selectedIcon: Icon(_destinations[i].selectedIcon),
                label: labels[i],
              ),
          ],
        ),
      ),
    );
  }
}

class _NavDestination {
  const _NavDestination({required this.icon, required this.selectedIcon});

  final IconData icon;
  final IconData selectedIcon;
}
