import 'dart:ui';
import 'package:flutter/material.dart';

class AnimatedBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavItem> items;
  final Color? selectedColor;
  final bool hideBottomNav;

  const AnimatedBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.selectedColor,
    this.hideBottomNav = false,
  });

  @override
  State<AnimatedBottomNavBar> createState() => _AnimatedBottomNavBarState();
}

class _AnimatedBottomNavBarState extends State<AnimatedBottomNavBar> {
  final selectedColor = const Color(0xFF3E25F6);
  final unselectedColor = const Color.fromARGB(185, 255, 255, 255);

  @override
  Widget build(BuildContext context) {
    if (widget.hideBottomNav) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.zero,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Theme(
            data: Theme.of(context).copyWith(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              focusColor: Colors.transparent,
            ),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: const Color(0xFF111216),
              elevation: 0,
              selectedItemColor: widget.selectedColor ?? selectedColor,
              unselectedItemColor: unselectedColor,
              showSelectedLabels: true,
              showUnselectedLabels: true,
              selectedLabelStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w400,
              ),
              currentIndex: widget.currentIndex,
              onTap: widget.onTap,
              items: widget.items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isSelected = widget.currentIndex == index;

                return BottomNavigationBarItem(
                  icon: _buildNavItem(
                    icon: item.icon,
                    imageAsset: item.imageAsset,
                    isSelected: isSelected,
                    index: index,
                  ),
                  label: item.label,
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  // Custom Nav Item Builder with Top Indicator Line and Glow Effect
  Widget _buildNavItem({
    IconData? icon,
    String? imageAsset,
    required bool isSelected,
    required int index,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = screenWidth / widget.items.length;

    return Stack(
      clipBehavior: Clip.none, // Allow overflow for top line
      alignment: Alignment.center,
      children: [
        // Top indicator line (positioned at the very top edge of navbar)
        if (isSelected)
          Positioned(
            top: -10,
            child: Container(
              width: itemWidth,
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.selectedColor ?? selectedColor,
                    widget.selectedColor ?? selectedColor,
                  ],
                ),
                borderRadius: BorderRadius.circular(0),
              ),
            ),
          ),
        // Vertical glow effect background
        if (isSelected)
          Positioned(
            top: -12,
            child: Container(
              width: itemWidth,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    (widget.selectedColor ?? selectedColor).withOpacity(0.3),
                    (widget.selectedColor ?? selectedColor).withOpacity(0.2),
                    (widget.selectedColor ?? selectedColor).withOpacity(0.1),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
          ),
        // Icon or Image
        if (imageAsset != null)
          Image.asset(
            imageAsset,
            width: isSelected ? 24 : 22,
            height: isSelected ? 24 : 22,
            color: isSelected
                ? (widget.selectedColor ?? selectedColor)
                : unselectedColor,
            colorBlendMode: BlendMode.srcIn,
          )
        else if (icon != null)
          Icon(
            icon,
            size: isSelected ? 24 : 22,
            color: isSelected
                ? (widget.selectedColor ?? selectedColor)
                : unselectedColor,
          ),
      ],
    );
  }
}

class BottomNavItem {
  final IconData? icon;
  final String? imageAsset;
  final String label;

  const BottomNavItem({
    this.icon,
    this.imageAsset,
    required this.label,
  }) : assert(icon != null || imageAsset != null, 'Either icon or imageAsset must be provided');
}
