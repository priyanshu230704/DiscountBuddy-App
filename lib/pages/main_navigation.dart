import 'package:flutter/material.dart';
import '../providers/theme_provider.dart';
import '../providers/theme_provider.dart' as theme;
import '../providers/auth_provider.dart';
import 'home/home_page.dart';
import 'nearby/nearby_page.dart';
import 'bookings/bookings_page.dart';
import 'profile_page.dart';
import 'merchant/merchant_restaurants_page.dart';
import 'merchant/merchant_deals_page.dart';

/// Main navigation with bottom navigation bar (NeoTaste style)
class MainNavigation extends StatefulWidget {
  final ThemeProvider? themeProvider;

  const MainNavigation({super.key, this.themeProvider});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final AuthProvider _authProvider = AuthProvider();
  final Map<int, Widget> _pageCache = {};

  Widget _getPage(int index) {
    // Return cached page if exists
    if (_pageCache.containsKey(index)) {
      return _pageCache[index]!;
    }

    // Create page lazily
    Widget page;
    if (_authProvider.isMerchant) {
      switch (index) {
        case 0:
          page = const MerchantRestaurantsPage();
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

    // Cache the page
    _pageCache[index] = page;
    return page;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(_authProvider.isMerchant ? 3 : 4, (index) {
          // Lazy load: only build if it's the current index or already cached
          if (index == _currentIndex || _pageCache.containsKey(index)) {
            return _getPage(index);
          }
          return const SizedBox.shrink();
        }),
      ),
      bottomNavigationBar: _NeoTasteBottomNavBar(
        currentIndex: _currentIndex,
        isMerchant: _authProvider.isMerchant,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

/// NeoTaste-style bottom navigation bar with rounded design and yellow underline
class _NeoTasteBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool isMerchant;

  const _NeoTasteBottomNavBar({
    required this.currentIndex,
    required this.onTap,
    this.isMerchant = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.NeoTasteColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: isMerchant
                ? [
                    _buildNavItem(
                      context,
                      icon: Icons.restaurant_outlined,
                      selectedIcon: Icons.restaurant,
                      label: 'Restaurants',
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
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
  }) {
    final isSelected = currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected
                ? Colors.green.withOpacity(0.1)
                : Colors.transparent,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                size: 24,
                color: isSelected
                    ? Colors.green
                    : theme.NeoTasteColors.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? Colors.green
                      : theme.NeoTasteColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
