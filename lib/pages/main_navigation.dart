import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
  DateTime? _lastBackPressTime;


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
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;

          // If current tab is not Home/Dashboard, redirect to Home/Dashboard
          if (_currentIndex != 0) {
            setState(() {
              _currentIndex = 0;
            });
            return;
          }

          // Double tap to exit logic for Home/Dashboard
          final now = DateTime.now();
          const backPressInterval = Duration(seconds: 2);

          if (_lastBackPressTime == null ||
              now.difference(_lastBackPressTime!) > backPressInterval) {
            _lastBackPressTime = now;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Press back again to exit',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: AppColors.primaryPurple,
                behavior: SnackBarBehavior.floating,
                duration: backPressInterval,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          } else {
            // Quit the app
            SystemNavigator.pop();
          }
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
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          top: 12,
          bottom: MediaQuery.of(context).padding.bottom > 0
              ? MediaQuery.of(context).padding.bottom + 4
              : 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                    svgPath: 'assets/svg/user.svg',
                    label: 'Profile',
                    index: 2,
                  ),
                ]
              : [
                  _buildNavItem(
                    context,
                    svgPath: 'assets/svg/home.svg',
                    label: 'Home',
                    index: 0,
                  ),
                  _buildNavItem(
                    context,
                    svgPath: 'assets/svg/search.svg',
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
                    svgPath: 'assets/svg/user.svg',
                    label: 'Profile',
                    index: 3,
                  ),
                ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    IconData? icon,
    IconData? selectedIcon,
    String? svgPath,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryPurple.withValues(alpha: 0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: svgPath != null
                  ? SvgPicture.asset(
                      svgPath,
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(
                        isSelected
                            ? AppColors.primaryPurple
                            : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                        BlendMode.srcIn,
                      ),
                    )
                  : Icon(
                      isSelected ? selectedIcon : icon,
                      size: 26,
                      color: isSelected
                          ? AppColors.primaryPurple
                          : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                    ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppColors.primaryPurple
                    : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 10,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
