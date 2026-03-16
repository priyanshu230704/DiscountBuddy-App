import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _authProvider.addListener(_onAuthStateChanged);
  }

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  void _onAuthStateChanged() {
    if (!mounted) return;
    if (!_authProvider.isAuthenticated) {
      // User logged out or session expired, forcibly return to login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
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
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(isMerchant ? 3 : 4, (index) {
          if (index == _currentIndex || _pageCache.containsKey(index)) {
            return _getPage(index);
          }
          return const SizedBox.shrink();
        }),
      ),
      bottomNavigationBar: Container(
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
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        items: isMerchant
            ? const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  activeIcon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.local_offer_outlined),
                  activeIcon: Icon(Icons.local_offer),
                  label: 'Deals',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ]
            : const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search_outlined),
                  activeIcon: Icon(Icons.search),
                  label: 'Search',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today_outlined),
                  activeIcon: Icon(Icons.calendar_today),
                  label: 'Bookings',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
        ),
      ),
    );
  }
}
