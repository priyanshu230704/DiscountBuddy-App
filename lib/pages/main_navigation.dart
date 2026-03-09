import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:discount_buddy/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import 'home/home_page.dart';
import 'nearby/nearby_page.dart';
import 'bookings/bookings_page.dart';
import 'profile_page.dart';
import 'merchant/merchant_deals_page.dart';
import 'merchant/merchant_dashboard_page.dart';

/// Main navigation with new floating bottom navigation bar
class MainNavigation extends StatefulWidget {
  final int initialIndex;
  final double? initialLatitude;
  final double? initialLongitude;

  const MainNavigation({
    super.key,
    this.initialIndex = 0,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _currentIndex;
  final AuthProvider _authProvider = AuthProvider();
  final Map<int, Widget> _pageCache = {};
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

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
          page = NearbyPage(
            initialLatitude: widget.initialLatitude,
            initialLongitude: widget.initialLongitude,
          );
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

    return Scaffold(
      extendBody: true, // Important for floating nav bar
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (notification.direction == ScrollDirection.forward) {
            if (!_isVisible) setState(() => _isVisible = true);
          } else if (notification.direction == ScrollDirection.reverse) {
            if (_isVisible) setState(() => _isVisible = false);
          }
          return false; // let it bubble
        },
        child: IndexedStack(
          index: _currentIndex,
          children: List.generate(isMerchant ? 3 : 4, (index) {
            if (index == _currentIndex || _pageCache.containsKey(index)) {
              return _getPage(index);
            }
            return const SizedBox.shrink();
          }),
        ),
      ),
      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        offset: _isVisible ? Offset.zero : const Offset(0, 1.5),
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom > 0
                ? MediaQuery.of(context).padding.bottom - 10
                : 0,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SizedBox(
            height: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
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
                        icon: Icons.search_outlined,
                        selectedIcon: Icons.search,
                        label: 'Search',
                        index: 1,
                      ),
                      _buildNavItem(
                        context,
                        icon: Icons.calendar_today_outlined,
                        selectedIcon: Icons.calendar_today,
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

    final Gradient activeGradient = AppColors.purpleGradient;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: isSelected
          ? AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: activeGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                    spreadRadius: 0,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(selectedIcon, color: Colors.white, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isDark
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF6B7280),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
    );
  }
}
