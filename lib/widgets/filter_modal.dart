import 'package:discount_buddy/theme/app_colors.dart';
import 'package:discount_buddy/theme/app_fonts.dart';
import 'package:flutter/material.dart';
import 'generic_bottom_sheet.dart';
import '../services/restaurant_service.dart';

/// Filter Modal - Bottom sheet with day, time, and category filters
class FilterModal extends StatefulWidget {
  final Function(Map<String, dynamic>)? onApply;

  const FilterModal({super.key, this.onApply});

  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  final RestaurantService _restaurantService = RestaurantService();
  String? _selectedDay;
  String? _selectedTime;
  int? _selectedCuisineId;
  String _selectedCuisineName = 'All';
  List<Map<String, dynamic>> _cuisines = [];
  bool _isLoadingCuisines = true;
  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];
  final List<String> _times = [
    'Morning',
    'Lunch',
    'Afternoon',
    'Evening',
    'Night'
  ];

  @override
  void initState() {
    super.initState();
    _loadCuisines();
  }

  Future<void> _loadCuisines() async {
    try {
      final cuisines = await _restaurantService.getCuisines();
      if (mounted) {
        setState(() {
          _cuisines = cuisines;
          _isLoadingCuisines = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCuisines = false;
        });
      }
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedDay = null;
      _selectedTime = null;
      _selectedCuisineId = null;
      _selectedCuisineName = 'All';
    });
  }

  void _applyFilters() {
    final filters = {
      'day': _selectedDay,
      'time': _selectedTime,
      'cuisine_id': _selectedCuisineId,
      'cuisine_name': _selectedCuisineName,
    };

    if (widget.onApply != null) {
      widget.onApply!(filters);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.85; // 85% of screen height

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        gradient: AppColors.backgroundGradient,
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: GenericBottomSheet(
        backgroundColor: Colors.transparent,
        title: 'Filter',
        showCloseButton: false, // We use headerAction for Reset
        headerAction: TextButton(
          onPressed: _resetFilters,
          child: Text(
            'Reset',
            style: AppFonts.bodyStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        footer: Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          decoration: BoxDecoration(
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Apply',
                    style: AppFonts.bodyStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Divider(
                height: 1,
                color: AppColors.textDisabled.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 24),

              // Day Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Day',
                      style: AppFonts.bodyStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _days.length,
                        itemBuilder: (context, index) {
                          final day = _days[index];
                          final isSelected = _selectedDay == day;

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(day),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedDay = selected ? day : null;
                                });
                              },
                              selectedColor: AppColors.primaryPurple,
                              backgroundColor: AppColors.textDisabled
                                  .withValues(alpha: 0.2),
                              labelStyle: AppFonts.bodyStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Time Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Time',
                      style: AppFonts.bodyStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _times.length,
                        itemBuilder: (context, index) {
                          final time = _times[index];
                          final isSelected = _selectedTime == time;

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(time),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedTime = selected ? time : null;
                                });
                              },
                              selectedColor: AppColors.primaryPurple,
                              backgroundColor: AppColors.textDisabled
                                  .withValues(alpha: 0.2),
                              labelStyle: AppFonts.bodyStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Category Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cuisine',
                      style: AppFonts.bodyStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_isLoadingCuisines)
                      const Center(child: CircularProgressIndicator())
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          // "All" option
                          FilterChip(
                            label: const Text('All'),
                            selected: _selectedCuisineId == null,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCuisineId = null;
                                _selectedCuisineName = 'All';
                              });
                            },
                            selectedColor: AppColors.primaryPurple,
                            backgroundColor: AppColors.textDisabled.withValues(
                              alpha: 0.2,
                            ),
                            labelStyle: AppFonts.bodyStyle(
                              color: _selectedCuisineId == null
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          ..._cuisines.map((cuisine) {
                            final id = cuisine['id'];
                            final name = cuisine['name'] as String;
                            final isSelected = _selectedCuisineId == id;

                            return FilterChip(
                              label: Text(name),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedCuisineId = selected ? id : null;
                                  _selectedCuisineName =
                                      selected ? name : 'All';
                                });
                              },
                              selectedColor: AppColors.primaryPurple,
                              backgroundColor: AppColors.textDisabled
                                  .withValues(alpha: 0.2),
                              labelStyle: AppFonts.bodyStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
    );
  }
}


