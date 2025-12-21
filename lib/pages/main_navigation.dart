import 'package:flutter/material.dart';
import '../widgets/animated_bottom_nav_bar.dart';
import '../providers/theme_provider.dart';
import 'home/home_page.dart';
import 'browse_page.dart';
import 'events/events_page.dart';
import 'more/live_page.dart';
import 'more/more_page.dart';

/// Main navigation with bottom navigation bar (Tastecard style)
class MainNavigation extends StatefulWidget {
  final ThemeProvider? themeProvider;
  
  const MainNavigation({super.key, this.themeProvider});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  List<Widget> get _pages => [
    const HomePage(),
    const BrowsePage(),
    const EventsPage(),
    const LivePage(),
    MorePage(themeProvider: widget.themeProvider),
  ];

  List<BottomNavItem> get _navItems => [
    const BottomNavItem(
      icon: Icons.home,
      label: 'Home',
    ),
    const BottomNavItem(
      icon: Icons.view_list,
      label: 'Browse',
    ),
    const BottomNavItem(
      imageAsset: 'assets/png/event.png',
      label: 'Events',
    ),
    const BottomNavItem(
      icon: Icons.local_fire_department,
      label: 'Live',
    ),
    const BottomNavItem(
      icon: Icons.more_horiz,
      label: 'More',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: AnimatedBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: _navItems,
        selectedColor: const Color(0xFF3E25F6),
      ),
    );
  }
}

