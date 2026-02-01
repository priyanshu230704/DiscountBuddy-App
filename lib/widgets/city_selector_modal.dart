import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';

/// City Selector Modal - Bottom sheet with cities and coverage badges
class CitySelectorModal extends StatelessWidget {
  final String selectedCity;
  final Function(String) onCitySelected;

  const CitySelectorModal({
    super.key,
    required this.selectedCity,
    required this.onCitySelected,
  });

  @override
  Widget build(BuildContext context) {
    // Mock cities with coverage status
    final cities = [
      _CityData(name: 'London', isCovered: true, restaurantCount: 245),
      _CityData(name: 'Manchester', isCovered: true, restaurantCount: 89),
      _CityData(name: 'Birmingham', isCovered: true, restaurantCount: 67),
      _CityData(name: 'Liverpool', isCovered: true, restaurantCount: 54),
      _CityData(name: 'Leeds', isCovered: true, restaurantCount: 43),
      _CityData(name: 'Bristol', isCovered: true, restaurantCount: 38),
      _CityData(name: 'Edinburgh', isCovered: true, restaurantCount: 32),
      _CityData(name: 'Glasgow', isCovered: true, restaurantCount: 29),
      _CityData(name: 'Cardiff', isCovered: false, restaurantCount: 0),
      _CityData(name: 'Newcastle', isCovered: false, restaurantCount: 0),
      _CityData(name: 'Nottingham', isCovered: false, restaurantCount: 0),
      _CityData(name: 'Sheffield', isCovered: false, restaurantCount: 0),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: NeoTasteColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: NeoTasteColors.textDisabled,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Text(
                    'Select City',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: NeoTasteColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Cities List
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: cities.length,
                itemBuilder: (context, index) {
                  final city = cities[index];
                  final isSelected = city.name == selectedCity;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          onCitySelected(city.name);
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? NeoTasteColors.accent.withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? NeoTasteColors.accent
                                  : NeoTasteColors.textDisabled.withOpacity(0.2),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // City Name
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      city.name,
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: NeoTasteColors.textPrimary,
                                      ),
                                    ),
                                    if (city.isCovered) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        '${city.restaurantCount} restaurants',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: NeoTasteColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              // Coverage Badge
                              if (city.isCovered)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Covered',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: NeoTasteColors.textDisabled.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Coming Soon',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: NeoTasteColors.textSecondary,
                                    ),
                                  ),
                                ),
                              if (isSelected) ...[
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.check_circle,
                                  color: NeoTasteColors.accent,
                                  size: 24,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _CityData {
  final String name;
  final bool isCovered;
  final int restaurantCount;

  _CityData({
    required this.name,
    required this.isCovered,
    required this.restaurantCount,
  });
}
