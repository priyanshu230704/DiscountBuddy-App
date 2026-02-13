import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'default_navbar.dart';

/// A reusable scaffold that adapts its navigation based on screen size.
///
/// * Mobile (<600): Bottom Navigation Bar (Native on iOS, Material 3 on Android)
/// * Tablet (600-1024): Navigation Rail
/// * Desktop (>1024): Navigation Drawer (Sidebar)
class AdaptiveNavbarScaffold extends StatelessWidget {
  /// The list of pages to display for each tab.
  final List<Widget> pages;

  /// Whether to show merchant navigation destinations.
  final bool isMerchant;

  /// The current selected index.
  final int selectedIndex;

  /// Callback when a navigation item is selected.
  final ValueChanged<int> onDestinationSelected;

  /// Color of the selected item.
  final Color? selectedItemColor;

  /// Color of the unselected item.
  final Color? unselectedItemColor;

  static const List<AdaptiveNavigationDestination> _merchantDestinations = [
    AdaptiveNavigationDestination(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      label: 'Dashboard',
    ),
    AdaptiveNavigationDestination(
      icon: Icons.local_offer_outlined,
      selectedIcon: Icons.local_offer,
      label: 'Deals',
    ),
    AdaptiveNavigationDestination(
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: 'Profile',
    ),
  ];

  static const List<AdaptiveNavigationDestination> _customerDestinations = [
    AdaptiveNavigationDestination(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: 'Home',
    ),
    AdaptiveNavigationDestination(
      icon: Icons.near_me_outlined,
      selectedIcon: Icons.near_me,
      label: 'Nearby',
    ),
    AdaptiveNavigationDestination(
      icon: Icons.event_note_outlined,
      selectedIcon: Icons.event_note,
      label: 'Bookings',
    ),
    AdaptiveNavigationDestination(
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: 'Profile',
    ),
  ];

  const AdaptiveNavbarScaffold({
    super.key,
    required this.pages,
    this.isMerchant = false,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.selectedItemColor,
    this.unselectedItemColor,
  });

  List<AdaptiveNavigationDestination> get destinations =>
      isMerchant ? _merchantDestinations : _customerDestinations;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1024) {
          // Desktop: Permanent Sidebar/Drawer
          return AdaptiveScaffold(
            body: Row(
              children: [
                _buildDrawer(context),
                Expanded(
                  child: IndexedStack(index: selectedIndex, children: pages),
                ),
              ],
            ),
          );
        } else if (constraints.maxWidth > 600) {
          // Tablet: Navigation Rail
          return AdaptiveScaffold(
            body: Row(
              children: [
                _buildRail(context),
                Expanded(
                  child: IndexedStack(index: selectedIndex, children: pages),
                ),
              ],
            ),
          );
        } else {
          // Mobile: Bottom Navigation

          if (!Platform.isIOS) {
            // Use custom floating navbar for Android/other platforms
            return DefaultNavbar(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              isMerchant: isMerchant,
              pages: pages,
            );
          }

          // Create platform-specific destinations
          // For iOS 26+ Native Bar, we MUST use SF Symbol strings
          final nativeDestinations = Platform.isIOS
              ? destinations.map((d) {
                  return AdaptiveNavigationDestination(
                    icon: _getSFSymbol(d.icon),
                    selectedIcon: _getSFSymbol(
                      d.selectedIcon ?? d.icon,
                      filled: true,
                    ),
                    label: d.label,
                  );
                }).toList()
              : destinations;

          return AdaptiveScaffold(
            minimizeBehavior: TabBarMinimizeBehavior.never,
            body: IndexedStack(index: selectedIndex, children: pages),
            bottomNavigationBar: AdaptiveBottomNavigationBar(
              items: nativeDestinations, // Pass SF strings for Native Bar
              selectedIndex: selectedIndex,
              onTap: onDestinationSelected,
              useNativeBottomBar: true, // Native iOS 26+ Liquid Glass
              // Explicitly provide Android bar (uses IconData from this.destinations)
              bottomNavigationBar: _buildAndroidBar(context),
              // Explicitly provide Cupertino bar (uses IconData from this.destinations)
              cupertinoTabBar: _buildCupertinoBar(context),
              selectedItemColor: selectedItemColor,
              unselectedItemColor: unselectedItemColor,
            ),
          );
        }
      },
    );
  }

  String _getSFSymbol(dynamic icon, {bool filled = false}) {
    if (icon is IconData) {
      if (icon == Icons.dashboard_outlined || icon == Icons.dashboard)
        return filled ? 'square.grid.2x2.fill' : 'square.grid.2x2';
      if (icon == Icons.local_offer_outlined || icon == Icons.local_offer)
        return filled ? 'tag.fill' : 'tag';
      if (icon == Icons.person_outline || icon == Icons.person)
        return filled ? 'person.fill' : 'person';
      if (icon == Icons.home_outlined || icon == Icons.home)
        return filled ? 'house.fill' : 'house';
      if (icon == Icons.near_me_outlined || icon == Icons.near_me)
        return filled ? 'location.fill' : 'location';
      if (icon == Icons.event_note_outlined || icon == Icons.event_note)
        return filled ? 'calendar.badge.clock.fill' : 'calendar.badge.clock';
    }
    return 'circle';
  }

  // Build Material 3 NavigationBar
  Widget _buildAndroidBar(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      indicatorColor:
          selectedItemColor?.withOpacity(0.2) ??
          Theme.of(context).colorScheme.secondaryContainer,
      destinations: destinations.map((d) {
        return NavigationDestination(
          icon: _getIcon(d.icon),
          selectedIcon: _getIcon(d.selectedIcon ?? d.icon),
          label: d.label,
        );
      }).toList(),
    );
  }

  // Build CupertinoTabBar
  CupertinoTabBar _buildCupertinoBar(BuildContext context) {
    return CupertinoTabBar(
      currentIndex: selectedIndex,
      onTap: onDestinationSelected,
      activeColor: selectedItemColor ?? CupertinoColors.activeBlue,
      inactiveColor: unselectedItemColor ?? CupertinoColors.systemGrey,
      items: destinations.map((d) {
        return BottomNavigationBarItem(
          icon: _getIcon(d.icon),
          activeIcon: _getIcon(d.selectedIcon ?? d.icon),
          label: d.label,
        );
      }).toList(),
    );
  }

  Widget _getIcon(dynamic icon) {
    if (icon is IconData) {
      return Icon(icon);
    } else if (icon is String) {
      // Simple fallback for SF Symbols names if used in Rail/Drawer
      return const Icon(Icons.circle_outlined);
    }
    return const Icon(Icons.circle_outlined);
  }

  Widget _buildRail(BuildContext context) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: destinations
          .map(
            (d) => NavigationRailDestination(
              icon: _getIcon(d.icon),
              selectedIcon: _getIcon(d.selectedIcon ?? d.icon),
              label: Text(d.label),
            ),
          )
          .toList(),
      labelType: NavigationRailLabelType.all,
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return NavigationDrawer(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      children: [
        const SizedBox(height: 16),
        ...destinations.map(
          (d) => NavigationDrawerDestination(
            icon: _getIcon(d.icon),
            selectedIcon: _getIcon(d.selectedIcon ?? d.icon),
            label: Text(d.label),
          ),
        ),
      ],
    );
  }
}
