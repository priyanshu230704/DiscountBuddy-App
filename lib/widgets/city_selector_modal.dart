import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';
import 'package:discount_buddy/services/city_service.dart';
import 'package:discount_buddy/models/city.dart';


class CitySelectorModal extends StatelessWidget {
  final String selectedCity;
  final Function(City) onCitySelected;

  const CitySelectorModal({
    super.key,
    required this.selectedCity,
    required this.onCitySelected,
  });

  @override
  Widget build(BuildContext context) {
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

            Flexible(
              child: FutureBuilder<List<City>>(
                future: CityService().getCities(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          "Failed to load cities\n${snapshot.error}",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    );
                  }

                  final cities = snapshot.data ?? [];

                  if (cities.isEmpty) {
                    return Center(
                      child: Text(
                        "No cities found",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: NeoTasteColors.textSecondary,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: cities.length,
                    itemBuilder: (context, index) {
                      final city = cities[index];

                      final isCovered = (city.restaurantsCount ?? 0) > 0;
                      final restaurantCount = city.restaurantsCount ?? 0;

                      final isSelected = city.name == selectedCity;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              onCitySelected(city);
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
                                      : NeoTasteColors.textDisabled.withOpacity(
                                          0.2,
                                        ),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // City Name
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          city.name,
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: NeoTasteColors.textPrimary,
                                          ),
                                        ),
                                        if (isCovered) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            "$restaurantCount restaurants",
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color:
                                                  NeoTasteColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  // Coverage Badge
                                  if (isCovered)
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
                                        color: NeoTasteColors.textDisabled
                                            .withOpacity(0.3),
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
