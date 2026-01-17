import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/auth/auth_text_field.dart';
import '../../services/merchant_service.dart';

/// Add/Edit Restaurant Page for Merchants
class AddRestaurantPage extends StatefulWidget {
  final Map<String, dynamic>? restaurant; // If provided, edit mode; otherwise, create mode

  const AddRestaurantPage({super.key, this.restaurant});

  @override
  State<AddRestaurantPage> createState() => _AddRestaurantPageState();
}

class _AddRestaurantPageState extends State<AddRestaurantPage> {
  final MerchantService _merchantService = MerchantService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _postcodeController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();

  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _categories = [];
  int? _selectedCityId;
  String _selectedCityName = '';
  final _cityController = TextEditingController();
  List<Map<String, dynamic>> _filteredCities = [];
  List<int> _selectedCategoryIds = [];
  int _priceRange = 2;
  bool _isLoading = false;
  bool _isLoadingData = true;
  bool _showCitySuggestions = false;
  Map<String, String> _openingHours = {
    'monday': '',
    'tuesday': '',
    'wednesday': '',
    'thursday': '',
    'friday': '',
    'saturday': '',
    'sunday': '',
  };

  @override
  void initState() {
    super.initState();
    _loadReferenceData();
    if (widget.restaurant != null) {
      _loadRestaurantData();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _postcodeController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _loadReferenceData() async {
    try {
      final results = await Future.wait([
        _merchantService.getCities(),
        _merchantService.getCategories(),
      ]);

      if (mounted) {
        setState(() {
          _cities = results[0];
          _categories = results[1];
          _filteredCities = _cities;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load reference data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _loadRestaurantData() {
    final restaurant = widget.restaurant!;
    _nameController.text = restaurant['name'] as String? ?? '';
    _slugController.text = restaurant['slug'] as String? ?? '';
    _descriptionController.text = restaurant['description'] as String? ?? '';
    _addressController.text = restaurant['address'] as String? ?? '';
    _postcodeController.text = restaurant['postcode'] as String? ?? '';
    _latitudeController.text = restaurant['latitude']?.toString() ?? '';
    _longitudeController.text = restaurant['longitude']?.toString() ?? '';
    _phoneController.text = restaurant['phone'] as String? ?? '';
    _emailController.text = restaurant['email'] as String? ?? '';
    _websiteController.text = restaurant['website'] as String? ?? '';
    _priceRange = restaurant['price_range'] as int? ?? 2;
    
    // Load city
    if (restaurant['city'] != null) {
      final city = restaurant['city'] as Map<String, dynamic>;
      _selectedCityId = city['id'] as int?;
      _selectedCityName = city['name'] as String? ?? '';
      _cityController.text = _selectedCityName;
    }
    
    // Load categories
    if (restaurant['categories'] != null) {
      final categories = restaurant['categories'] as List;
      _selectedCategoryIds = categories.map((c) {
        if (c is Map) return c['id'] as int;
        return c as int;
      }).toList();
    }
    
    // Load opening hours
    if (restaurant['opening_hours'] != null) {
      final hours = restaurant['opening_hours'] as Map<String, dynamic>;
      hours.forEach((key, value) {
        if (_openingHours.containsKey(key.toLowerCase())) {
          _openingHours[key.toLowerCase()] = value.toString();
        }
      });
    }
  }

  String _generateSlug(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  Future<void> _saveRestaurant() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Build opening hours object (only include non-empty values)
      final openingHours = <String, String>{};
      _openingHours.forEach((key, value) {
        if (value.isNotEmpty) {
          openingHours[key] = value;
        }
      });

      final restaurantData = {
        'name': _nameController.text.trim(),
        'slug': _slugController.text.trim().isEmpty
            ? _generateSlug(_nameController.text.trim())
            : _slugController.text.trim(),
        'description': _descriptionController.text.trim(),
        'city': _selectedCityId,
        'address': _addressController.text.trim(),
        'postcode': _postcodeController.text.trim(),
        'latitude': _latitudeController.text.trim(),
        'longitude': _longitudeController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'website': _websiteController.text.trim(),
        'categories': _selectedCategoryIds,
        'price_range': _priceRange,
        if (openingHours.isNotEmpty) 'opening_hours': openingHours,
      };

      // Remove empty optional fields
      restaurantData.removeWhere((key, value) =>
          (value == null || value == '' || (value is List && value.isEmpty)) &&
          key != 'city' &&
          key != 'categories' &&
          key != 'price_range');

      if (widget.restaurant != null) {
        // Update existing restaurant
        final restaurantId = widget.restaurant!['id'];
        if (restaurantId is int) {
          await _merchantService.updateRestaurant(
            restaurantId,
            restaurantData,
          );
        } else {
          await _merchantService.updateRestaurant(
            int.parse(restaurantId.toString()),
            restaurantData,
          );
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Restaurant updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        // Create new restaurant
        await _merchantService.createRestaurant(restaurantData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Restaurant created successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save restaurant: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoTasteColors.background,
      appBar: AppBar(
        title: Text(
          widget.restaurant != null ? 'Edit Restaurant' : 'Add Restaurant',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: NeoTasteColors.white,
        elevation: 0,
        actions: widget.restaurant != null
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Restaurant'),
                        content: const Text(
                          'Are you sure you want to delete this restaurant?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      try {
                        final restaurantId = widget.restaurant!['id'];
                        final id = restaurantId is int
                            ? restaurantId
                            : int.parse(restaurantId.toString());
                        await _merchantService.deleteRestaurant(id);
                        if (mounted) {
                          Navigator.pop(context, true);
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to delete: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                ),
              ]
            : null,
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basic Information
                    _buildSectionTitle('Basic Information'),
                    AuthTextField(
                      controller: _nameController,
                      placeholder: 'Restaurant Name *',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Restaurant name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: _slugController,
                      placeholder: 'Slug (auto-generated if empty)',
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: _descriptionController,
                      placeholder: 'Description',
                    ),
                    const SizedBox(height: 24),

                    // Location
                    _buildSectionTitle('Location'),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AuthTextField(
                          controller: _cityController,
                          placeholder: 'Search City *',
                          onChanged: (value) {
                            setState(() {
                              if (value.isEmpty) {
                                _filteredCities = _cities;
                                _selectedCityId = null;
                                _selectedCityName = '';
                                _showCitySuggestions = false;
                              } else {
                                _filteredCities = _cities.where((city) {
                                  final cityName = (city['name'] as String? ?? '').toLowerCase();
                                  return cityName.contains(value.toLowerCase());
                                }).toList();
                                _showCitySuggestions = _filteredCities.isNotEmpty;
                                // Clear selection if text doesn't match selected city
                                if (_selectedCityName.toLowerCase() != value.toLowerCase()) {
                                  _selectedCityId = null;
                                }
                              }
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'City is required';
                            }
                            return null;
                          },
                        ),
                        if (_showCitySuggestions && _filteredCities.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            constraints: const BoxConstraints(maxHeight: 200),
                            decoration: BoxDecoration(
                              color: NeoTasteColors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: NeoTasteColors.textDisabled.withOpacity(0.3),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _filteredCities.length > 5 ? 5 : _filteredCities.length,
                              itemBuilder: (context, index) {
                                final city = _filteredCities[index];
                                final cityId = city['id'] as int;
                                final cityName = city['name'] as String;
                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedCityId = cityId;
                                      _selectedCityName = cityName;
                                      _cityController.text = cityName;
                                      _showCitySuggestions = false;
                                    });
                                    // Remove focus from text field
                                    FocusScope.of(context).unfocus();
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: Text(
                                      cityName,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: NeoTasteColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: _addressController,
                      placeholder: 'Address *',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Address is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: _postcodeController,
                      placeholder: 'Postcode',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: AuthTextField(
                            controller: _latitudeController,
                            placeholder: 'Latitude',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AuthTextField(
                            controller: _longitudeController,
                            placeholder: 'Longitude',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Contact Information
                    _buildSectionTitle('Contact Information'),
                    AuthTextField(
                      controller: _phoneController,
                      placeholder: 'Phone Number',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: _emailController,
                      placeholder: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value != null &&
                            value.isNotEmpty &&
                            !value.contains('@')) {
                          return 'Invalid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: _websiteController,
                      placeholder: 'Website URL',
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 24),

                    // Categories
                    _buildSectionTitle('Categories'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((category) {
                        final categoryId = category['id'] as int;
                        final isSelected =
                            _selectedCategoryIds.contains(categoryId);
                        return FilterChip(
                          label: Text(category['name'] as String),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedCategoryIds.add(categoryId);
                              } else {
                                _selectedCategoryIds.remove(categoryId);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Price Range
                    _buildSectionTitle('Price Range'),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<int>(
                            title: const Text('£'),
                            value: 1,
                            groupValue: _priceRange,
                            onChanged: (value) {
                              setState(() {
                                _priceRange = value!;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<int>(
                            title: const Text('££'),
                            value: 2,
                            groupValue: _priceRange,
                            onChanged: (value) {
                              setState(() {
                                _priceRange = value!;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<int>(
                            title: const Text('£££'),
                            value: 3,
                            groupValue: _priceRange,
                            onChanged: (value) {
                              setState(() {
                                _priceRange = value!;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<int>(
                            title: const Text('££££'),
                            value: 4,
                            groupValue: _priceRange,
                            onChanged: (value) {
                              setState(() {
                                _priceRange = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Opening Hours
                    _buildSectionTitle('Opening Hours (Optional)'),
                    ..._openingHours.entries.map((entry) {
                      final controller = TextEditingController(text: entry.value);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 100,
                              child: Text(
                                entry.key[0].toUpperCase() +
                                    entry.key.substring(1),
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: AuthTextField(
                                controller: controller,
                                placeholder: 'e.g., 10:00-22:00',
                                onChanged: (value) {
                                  setState(() {
                                    _openingHours[entry.key] = value;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveRestaurant,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: NeoTasteColors.accent,
                          foregroundColor: NeoTasteColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    NeoTasteColors.primary,
                                  ),
                                ),
                              )
                            : Text(
                                widget.restaurant != null
                                    ? 'Update Restaurant'
                                    : 'Create Restaurant',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: NeoTasteColors.textPrimary,
        ),
      ),
    );
  }
}
