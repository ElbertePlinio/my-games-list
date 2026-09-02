import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';

/// Adaptive primary navigation for the app shell.
///
/// Features:
/// - Four destinations: Home, Browse, Library, Profile
/// - Compact (< 600px): Material 3 bottom [NavigationBar]
/// - Medium/expanded (>= 600px, e.g. web/desktop/tablet): side [NavigationRail]
/// - Integrates with GoRouter's StatefulShellRoute for state preservation
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  /// Width at/above which the side rail replaces the bottom bar.
  static const double railBreakpoint = 600;

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
    final labels = [
      l10n.navHome,
      l10n.navBrowse,
      l10n.navLibrary,
      l10n.navProfile,
    ];
    final isWide = MediaQuery.sizeOf(context).width >= railBreakpoint;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _onDestinationSelected,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (var i = 0; i < _destinations.length; i++)
                  NavigationRailDestination(
                    icon: Icon(_destinations[i].icon),
                    selectedIcon: Icon(_destinations[i].selectedIcon),
                    label: Text(labels[i]),
                  ),
              ],
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
        animationDuration: const Duration(milliseconds: 400),
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
    );
  }
}

class _NavDestination {
  const _NavDestination({required this.icon, required this.selectedIcon});

  final IconData icon;
  final IconData selectedIcon;
}
