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
import '../widgets/adaptive_navbar_scaffold.dart';

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
    // final theme = Theme.of(context);
    // final isDark = theme.brightness == Brightness.dark;

    // Prepare Pages List
    // We match the count and order defined in AdaptiveNavbarScaffold
    final List<Widget> pages = List.generate(
      isMerchant ? 3 : 4,
      (index) => _getPage(index),
    );
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AdaptiveNavbarScaffold(
      selectedIndex: _currentIndex,
      onDestinationSelected: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      isMerchant: isMerchant,
      pages: pages,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: isDark
          ? AppColors.textSecondaryDark
          : AppColors.textSecondaryLight,
    );
  }
}
