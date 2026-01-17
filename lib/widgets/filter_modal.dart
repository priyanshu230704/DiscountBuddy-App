import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';

/// Filter Modal - Bottom sheet with day, time, and category filters
class FilterModal extends StatefulWidget {
  final Function(Map<String, dynamic>)? onApply;

  const FilterModal({super.key, this.onApply});

  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  String? _selectedDay;
  String? _selectedTime;
  String _selectedCategory = 'All';

  final List<String> _days = ['Today', 'Tomorrow', 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  final List<String> _times = ['0:00', '0:30', '1:00', '1:30', '2:00', '2:30', '3:00', '3:30', '4:00', '4:30', '5:00', '5:30', '6:00', '6:30', '7:00', '7:30', '8:00', '8:30', '9:00', '9:30', '10:00', '10:30', '11:00', '11:30', '12:00', '12:30', '13:00', '13:30', '14:00', '14:30', '15:00', '15:30', '16:00', '16:30', '17:00', '17:30', '18:00', '18:30', '19:00', '19:30', '20:00', '20:30', '21:00', '21:30', '22:00', '22:30', '23:00', '23:30'];
  
  final List<_CategoryData> _categories = [
    _CategoryData(name: 'All', emoji: ''),
    _CategoryData(name: 'Café', emoji: '☕'),
    _CategoryData(name: 'Drinks', emoji: '🥂'),
    _CategoryData(name: 'BBQ', emoji: '🔥'),
    _CategoryData(name: 'Desserts', emoji: '🍰'),
    _CategoryData(name: 'Breakfast', emoji: '🍳'),
    _CategoryData(name: 'Asian', emoji: '🍱'),
    _CategoryData(name: 'Burgers', emoji: '🍔'),
    _CategoryData(name: 'Pizza', emoji: '🍕'),
    _CategoryData(name: 'Fast Food', emoji: '🍟'),
    _CategoryData(name: 'Vegan', emoji: '🥦'),
    _CategoryData(name: 'Healthy', emoji: '🥗'),
    _CategoryData(name: 'Seafood', emoji: '🦐'),
    _CategoryData(name: 'Indian', emoji: '🍛'),
    _CategoryData(name: 'Sushi', emoji: '🍣'),
    _CategoryData(name: 'Italian', emoji: '🍅'),
    _CategoryData(name: 'Bowls', emoji: '🍲'),
    _CategoryData(name: 'Halal', emoji: '🕌'),
    _CategoryData(name: 'Pasta', emoji: '🍝'),
    _CategoryData(name: 'Sandwich', emoji: '🥪'),
    _CategoryData(name: 'Japanese', emoji: '🇯🇵'),
    _CategoryData(name: 'Mexican', emoji: '🌮'),
    _CategoryData(name: 'Vegetarian', emoji: '🫑'),
    _CategoryData(name: 'Mediterranean', emoji: '🫒'),
    _CategoryData(name: 'Spanish', emoji: '🥘'),
    _CategoryData(name: 'Curry', emoji: '🍛'),
  ];

  void _resetFilters() {
    setState(() {
      _selectedDay = null;
      _selectedTime = null;
      _selectedCategory = 'All';
    });
  }

  void _applyFilters() {
    final filters = {
      'day': _selectedDay,
      'time': _selectedTime,
      'category': _selectedCategory,
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
      constraints: BoxConstraints(
        maxHeight: maxHeight,
      ),
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
            
            // Title and Reset
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Text(
                    'Filter',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: NeoTasteColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _resetFilters,
                    child: Text(
                      'Reset',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: NeoTasteColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Divider
            Divider(
              height: 1,
              color: NeoTasteColors.textDisabled.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            
            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Day Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Day',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: NeoTasteColors.textPrimary,
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
                                    selectedColor: NeoTasteColors.accent,
                                    backgroundColor: NeoTasteColors.textDisabled.withOpacity(0.2),
                                    labelStyle: GoogleFonts.inter(
                                      color: isSelected
                                          ? NeoTasteColors.primary
                                          : NeoTasteColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
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
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: NeoTasteColors.textPrimary,
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
                                    selectedColor: NeoTasteColors.accent,
                                    backgroundColor: NeoTasteColors.textDisabled.withOpacity(0.2),
                                    labelStyle: GoogleFonts.inter(
                                      color: isSelected
                                          ? NeoTasteColors.primary
                                          : NeoTasteColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
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
                            'Category',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: NeoTasteColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _categories.map((category) {
                              final isSelected = _selectedCategory == category.name;
                              
                              return FilterChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (category.emoji.isNotEmpty) ...[
                                      Text(category.emoji),
                                      const SizedBox(width: 4),
                                    ],
                                    Text(category.name),
                                  ],
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedCategory = selected ? category.name : 'All';
                                  });
                                },
                                selectedColor: Colors.green, // Green for selected category
                                backgroundColor: NeoTasteColors.textDisabled.withOpacity(0.2),
                                labelStyle: GoogleFonts.inter(
                                  color: isSelected
                                      ? Colors.white
                                      : NeoTasteColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            
            // Apply Button (Fixed at bottom)
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              decoration: BoxDecoration(
                color: NeoTasteColors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, // Green apply button
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Apply',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryData {
  final String name;
  final String emoji;

  _CategoryData({required this.name, required this.emoji});
}
