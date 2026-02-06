import 'package:flutter/material.dart';
import 'package:discount_buddy/services/city_service.dart';
import 'package:discount_buddy/models/city.dart';
import 'generic_bottom_sheet.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GenericBottomSheet(
      title: 'Select City',
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
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
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
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: cities.length,
            itemBuilder: (context, index) {
              final city = cities[index];

              final isCovered = city.restaurantsCount > 0;
              final restaurantCount = city.restaurantsCount;

              final isSelected = city.name == selectedCity;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      onCitySelected(city);
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusXl,
                        ),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark
                                    ? AppColors.dividerDark
                                    : AppColors.dividerLight),
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
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                if (isCovered) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    "$restaurantCount restaurants",
                                    style: theme.textTheme.bodySmall,
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
                                color: AppColors.success,
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
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
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
                                color: isDark
                                    ? AppColors.surfaceVariantDark
                                    : AppColors.surfaceVariantLight,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Coming Soon',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                          if (isSelected) ...[
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.primary,
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
    );
  }
}
