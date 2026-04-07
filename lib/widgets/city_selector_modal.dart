import 'package:discount_buddy/theme/app_colors.dart';

import 'package:discount_buddy/design/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:discount_buddy/services/city_service.dart';
import 'package:discount_buddy/models/city.dart';
import 'generic_bottom_sheet.dart';

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
    return GenericBottomSheet(
      title: 'Select City',
      child: FutureBuilder<List<City>>(
        future: CityService().getCities(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SizedBox(
              height: 300,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                    color: AppColors.primaryPurple,
                  ),
                ),
              ),
            );
          }

          if (snapshot.hasError) {
            return SizedBox(
              height: 300,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    "Failed to load cities\n${snapshot.error}",
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }

          final cities = snapshot.data ?? [];

          if (cities.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  "No cities found",
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            itemCount: cities.length,
            itemBuilder: (context, index) {
              final city = cities[index];

              final isCovered = city.restaurantsCount > 0;
              final restaurantCount = city.restaurantsCount;

              final isSelected = city.name == selectedCity;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryPurple.withValues(alpha: 0.04)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryPurple.withValues(alpha: 0.3)
                          : AppColors.textDisabled.withValues(alpha: 0.15),
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: [
                      if (!isSelected)
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        onCitySelected(city);
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Leading Icon
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryPurple
                                    : AppColors.background,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.location_city_rounded,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),

                            // City Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    city.name,
                                    style: AppTypography.title.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? AppColors.primaryPurple
                                          : AppColors.textPrimary,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (isCovered)
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.storefront_rounded,
                                          size: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          "$restaurantCount places",
                                          style: AppTypography.bodySmall.copyWith(
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    Text(
                                      "Coming Soon",
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textDisabled,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Trailing
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryPurple,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              )
                            else if (isCovered)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryPurple
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Active',
                                  style: AppTypography.caption.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryPurple,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
