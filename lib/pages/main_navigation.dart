import 'dart:ui';
import 'package:discount_buddy/providers/theme_provider.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../providers/auth_provider.dart';
import 'home/home_page.dart';
import 'nearby/nearby_page.dart';
import 'bookings/bookings_page.dart';
import 'profile_page.dart';
import 'merchant/merchant_deals_page.dart';
import 'merchant/merchant_dashboard_page.dart';

/// Main navigation with new floating bottom navigation bar
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key, required ThemeProvider themeProvider});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final AuthProvider _authProvider = AuthProvider();
  final Map<int, Widget> _pageCache = {};

  Widget _getPage(int index) {
    if (_pageCache.containsKey(index)) {
      return _pageCache[index]!;
    }

    Widget page;
    if (_authProvider.isMerchant) {
      switch (index) {
        case 0:
          page = const MerchantDashboardPage();
          break;
        case 1:
          page = const MerchantDealsPage();
          break;
        case 2:
          page = const ProfilePage();
          break;
        default:
          page = const ProfilePage();
      }
    } else {
      switch (index) {
        case 0:
          page = const HomePage();
          break;
        case 1:
          page = const NearbyPage();
          break;
        case 2:
          page = const BookingsPage();
          break;
        case 3:
          page = const ProfilePage();
          break;
        default:
          page = const HomePage();
      }
    }

    _pageCache[index] = page;
    return page;
  }

  @override
  Widget build(BuildContext context) {
    final isMerchant = _authProvider.isMerchant;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBody: true, // Important for floating nav bar
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(isMerchant ? 3 : 4, (index) {
          if (index == _currentIndex || _pageCache.containsKey(index)) {
            return _getPage(index);
          }
          return const SizedBox.shrink();
        }),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32), // Floating pill shape
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.cardBackground.withOpacity(0.8)
                    : AppColors.cardBackground.withOpacity(0.9),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: isDark
                      ? AppColors.white.withOpacity(0.1)
                      : AppColors.white.withOpacity(0.5),
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
    final isSelected = _currentIndex == index;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
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
                        ? AppColors.textSecondary
                        : AppColors.textSecondary),
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
