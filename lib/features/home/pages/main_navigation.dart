import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'dart:math' as math;

import 'package:discount_buddy/core/theme/app_colors.dart';
import 'package:discount_buddy/features/auth/data/auth_provider.dart';
import 'package:discount_buddy/routes/app_routes.dart';
import 'package:discount_buddy/features/home/pages/home_page.dart';
import 'package:discount_buddy/features/nearby/pages/nearby_page.dart';
import 'package:discount_buddy/features/bookings/pages/bookings_page.dart';
import 'package:discount_buddy/features/profile/pages/profile_page.dart' show ProfilePage;
import 'package:discount_buddy/features/merchant/pages/merchant_restaurants_page.dart';
import 'package:discount_buddy/features/merchant/pages/merchant_dashboard_page.dart';
import 'package:discount_buddy/features/auth/widgets/login_required_sheet.dart';

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
  State<MainNavigation> createState() => MainNavigationState();
}

class MainNavigationState extends State<MainNavigation> {
  static MainNavigationState? of(BuildContext context) {
    return context.findAncestorStateOfType<MainNavigationState>();
  }

  void changeIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
  late int _currentIndex;
  final AuthProvider _authProvider = AuthProvider();
  final Map<int, Widget> _pageCache = {};
  DateTime? _lastPressedAt;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _authProvider.addListener(_onAuthStateChanged);
    
    // Check initial state in case we were built while already logged out
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _onAuthStateChanged();
      }
    });
  }

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  void _onAuthStateChanged() {
    if (!mounted) return;
    if (!_authProvider.isAuthenticated && !_authProvider.isGuestMode) {
      // User logged out or session expired, forcibly return to login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Get.offAllNamed(AppRoutes.login);
        }
      });
    }
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
          page = const MerchantRestaurantsPage();
          break;
        case 2:
          page = const MerchantRestaurantsPage(selectMenuMode: true);
          break;
        case 3:
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
    final bottomViewPadding = MediaQuery.viewPaddingOf(context).bottom;
    // Keep a little breathing room above the home indicator, but avoid the huge gap.
    final bottomNavInset = math.max(6.0, bottomViewPadding * 0.35);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;

          if (_currentIndex != 0) {
            setState(() {
              _currentIndex = 0;
            });
            return;
          }

          final now = DateTime.now();
          if (_lastPressedAt == null ||
              now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
            _lastPressedAt = now;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Press back again to exit'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                duration: const Duration(seconds: 2),
              ),
            );
            return;
          }

          SystemNavigator.pop();
        },
        child: Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: List.generate(4, (index) {
              if (index == _currentIndex || _pageCache.containsKey(index)) {
                return _getPage(index);
              }
              return const SizedBox.shrink();
            }),
          ),
          bottomNavigationBar: MediaQuery.removeViewPadding(
            context: context,
            removeBottom: true,
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomNavInset),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: BottomNavigationBar(
                  elevation: 0,
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: AppColors.surface,
                  selectedItemColor: AppColors.primary,
                  unselectedItemColor: const Color(0xFF9CA3AF),
                  selectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                  currentIndex: _currentIndex,
                  onTap: (index) {
                    if (_authProvider.isGuestMode &&
                        (index == 2 || index == 3)) {
                      LoginRequiredSheet.show(
                        context,
                        isClosable: false,
                        onBackToHome: () {
                          Navigator.pop(context);
                          setState(() {
                            _currentIndex = 0;
                          });
                        },
                      );
                      return;
                    }
                    setState(() {
                      _currentIndex = index;
                    });
                    if (index == 3) {
                      ProfilePage.onTabActivated.add(null);
                    }
                  },
                  items: isMerchant
                      ? [
                          BottomNavigationBarItem(
                            icon: SvgPicture.asset(
                              'assets/svg/dashboard.svg',
                              width: 24,
                              height: 24,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFF9CA3AF),
                                BlendMode.srcIn,
                              ),
                            ),
                            activeIcon: SvgPicture.asset(
                              'assets/svg/dashboard.svg',
                              width: 24,
                              height: 24,
                              colorFilter: const ColorFilter.mode(
                                AppColors.primary,
                                BlendMode.srcIn,
                              ),
                            ),
                            label: 'Dashboard',
                          ),
                          BottomNavigationBarItem(
                            icon: SvgPicture.asset(
                              'assets/svg/restaurant.svg',
                              width: 24,
                              height: 24,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFF9CA3AF),
                                BlendMode.srcIn,
                              ),
                            ),
                            activeIcon: SvgPicture.asset(
                              'assets/svg/restaurant.svg',
                              width: 24,
                              height: 24,
                              colorFilter: const ColorFilter.mode(
                                AppColors.primary,
                                BlendMode.srcIn,
                              ),
                            ),
                            label: 'Restaurants',
                          ),
                          BottomNavigationBarItem(
                            icon: SvgPicture.asset(
                              'assets/svg/tray_701965.svg',
                              width: 24,
                              height: 24,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFF9CA3AF),
                                BlendMode.srcIn,
                              ),
                            ),
                            activeIcon: SvgPicture.asset(
                              'assets/svg/tray_701965.svg',
                              width: 24,
                              height: 24,
                              colorFilter: const ColorFilter.mode(
                                AppColors.primary,
                                BlendMode.srcIn,
                              ),
                            ),
                            label: 'Menu',
                          ),
                          BottomNavigationBarItem(
                            icon: SvgPicture.asset(
                              'assets/svg/profile.svg',
                              width: 24,
                              height: 24,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFF9CA3AF),
                                BlendMode.srcIn,
                              ),
                            ),
                            activeIcon: SvgPicture.asset(
                              'assets/svg/profile.svg',
                              width: 24,
                              height: 24,
                              colorFilter: const ColorFilter.mode(
                                AppColors.primary,
                                BlendMode.srcIn,
                              ),
                            ),
                            label: 'Profile',
                          ),
                        ]
                      : [
                          const BottomNavigationBarItem(
                            icon: Icon(Icons.home_outlined),
                            activeIcon: Icon(Icons.home),
                            label: 'Home',
                          ),
                          const BottomNavigationBarItem(
                            icon: Icon(Icons.search_outlined),
                            activeIcon: Icon(Icons.search),
                            label: 'Search',
                          ),
                          const BottomNavigationBarItem(
                            icon: Icon(Icons.calendar_today_outlined),
                            activeIcon: Icon(Icons.calendar_today),
                            label: 'Bookings',
                          ),
                          BottomNavigationBarItem(
                            icon: SvgPicture.asset(
                              'assets/svg/profile.svg',
                              width: 24,
                              height: 24,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFF9CA3AF),
                                BlendMode.srcIn,
                              ),
                            ),
                            activeIcon: SvgPicture.asset(
                              'assets/svg/profile.svg',
                              width: 24,
                              height: 24,
                              colorFilter: const ColorFilter.mode(
                                AppColors.primary,
                                BlendMode.srcIn,
                              ),
                            ),
                            label: 'Profile',
                          ),
                        ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
