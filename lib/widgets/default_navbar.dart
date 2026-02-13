import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class DefaultNavbar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool isMerchant;
  final List<Widget> pages;

  const DefaultNavbar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.isMerchant,
    required this.pages,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: selectedIndex, children: pages),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceDark.withOpacity(0.8)
                    : AppColors.surfaceLight.withOpacity(0.9),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.white.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: isMerchant
                    ? [
                        _buildNavItem(
                          context,
                          icon: Icons.dashboard_outlined,
                          selectedIcon: Icons.dashboard,
                          label: 'Dashboard',
                          index: 0,
                        ),
                        _buildNavItem(
                          context,
                          icon: Icons.local_offer_outlined,
                          selectedIcon: Icons.local_offer,
                          label: 'Deals',
                          index: 1,
                        ),
                        _buildNavItem(
                          context,
                          icon: Icons.person_outline,
                          selectedIcon: Icons.person,
                          label: 'Profile',
                          index: 2,
                        ),
                      ]
                    : [
                        _buildNavItem(
                          context,
                          icon: Icons.home_outlined,
                          selectedIcon: Icons.home,
                          label: 'Home',
                          index: 0,
                        ),
                        _buildNavItem(
                          context,
                          icon: Icons.near_me_outlined,
                          selectedIcon: Icons.near_me,
                          label: 'Nearby',
                          index: 1,
                        ),
                        _buildNavItem(
                          context,
                          icon: Icons.event_note_outlined,
                          selectedIcon: Icons.event_note,
                          label: 'Bookings',
                          index: 2,
                        ),
                        _buildNavItem(
                          context,
                          icon: Icons.person_outline,
                          selectedIcon: Icons.person,
                          label: 'Profile',
                          index: 3,
                        ),
                      ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
  }) {
    final isSelected = selectedIndex == index;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => onDestinationSelected(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: -2,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              )
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              size: 24,
              color: isSelected
                  ? AppColors.primary
                  : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
