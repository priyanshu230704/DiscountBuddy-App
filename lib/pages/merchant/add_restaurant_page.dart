import 'package:flutter/material.dart';
import 'package:discount_buddy/theme/app_colors.dart';
import 'package:discount_buddy/design/app_spacing.dart';
import 'package:discount_buddy/design/app_typography.dart';
import 'package:discount_buddy/components/inputs.dart';
import 'package:discount_buddy/components/buttons.dart';
import 'package:discount_buddy/components/app_app_bar.dart';
import '../../services/merchant_service.dart';
import 'merchant_menu_page.dart';

/// Add/Edit Restaurant Page for Merchants
class AddRestaurantPage extends StatefulWidget {
  final Map<String, dynamic>?
  restaurant; // If provided, edit mode; otherwise, create mode

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
  final _cityFocusNode = FocusNode();
  List<Map<String, dynamic>> _filteredCities = [];
  List<int> _selectedCategoryIds = [];
  int _priceRange = 2;
  bool _isLoading = false;
  bool _isLoadingData = true;
  final LayerLink _cityLayerLink = LayerLink();
  OverlayEntry? _cityOverlayEntry;
  final GlobalKey _cityFieldKey = GlobalKey();
  final Map<String, String> _openingHours = {
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
    _cityFocusNode.addListener(_onCityFocusChange);
  }

  void _onCityFocusChange() {
    if (_cityFocusNode.hasFocus) {
      _showOverlay();
    } else {
      _hideOverlay();
    }
  }

  void _showOverlay() {
    if (_cityOverlayEntry != null) return;

    _cityOverlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_cityOverlayEntry!);
    setState(() {});
  }

  void _hideOverlay() {
    _cityOverlayEntry?.remove();
    _cityOverlayEntry = null;
    if (mounted) {
      setState(() {});
    }
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox? renderBox =
        _cityFieldKey.currentContext?.findRenderObject() as RenderBox?;
    var size = renderBox?.size ?? Size.zero;

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned(
            width: size.width,
            child: CompositedTransformFollower(
              link: _cityLayerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              offset: const Offset(0, 4.0),
              child: Material(
                elevation: 0,
                borderRadius: BorderRadius.circular(12),
                shadowColor: Colors.black.withValues(alpha: 0.3),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 250),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.textDisabled.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_filteredCities.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.search_off,
                                color: AppColors.textDisabled,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _cityController.text.isEmpty
                                    ? 'Loading cities...'
                                    : 'No cities found for "${_cityController.text}"',
                                textAlign: TextAlign.center,
                                style: AppTypography.bodySmall,
                              ),
                            ],
                          ),
                        )
                      else
                        Flexible(
                          child: ListView.separated(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: _filteredCities.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              color: AppColors.textDisabled.withValues(
                                alpha: 0.1,
                              ),
                            ),
                            itemBuilder: (context, index) {
                              final city = _filteredCities[index];
                              final cityName =
                                  city['name'] as String? ?? 'Unknown';
                              return ListTile(
                                leading: const Icon(
                                  Icons.location_city,
                                  size: 20,
                                  color: AppColors.accent,
                                ),
                                title: Text(
                                  cityName,
                                  style: AppTypography.body.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                onTap: () {
                                  setState(() {
                                    _cityController.text = cityName;
                                    _selectedCityId = city['id'] as int;
                                    _selectedCityName = cityName;
                                  });
                                  _cityFocusNode.unfocus();
                                  _hideOverlay();
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
    _cityFocusNode.removeListener(_onCityFocusChange);
    _cityFocusNode.dispose();
    _hideOverlay();
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
        'city_id': _selectedCityId,
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
      restaurantData.removeWhere(
        (key, value) =>
            (value == null ||
                value == '' ||
                (value is List && value.isEmpty)) &&
            key != 'city_id' &&
            key != 'categories' &&
            key != 'price_range',
      );

      if (widget.restaurant != null) {
        // Update existing restaurant
        final restaurantId = widget.restaurant!['id'];
        if (restaurantId is int) {
          await _merchantService.updateRestaurant(restaurantId, restaurantData);
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
              backgroundColor: AppColors.primaryPurple,
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
              backgroundColor: AppColors.primaryPurple,
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
      backgroundColor: AppColors.background,
      appBar: AppAppBar(
        titleText:
            widget.restaurant != null ? 'Edit restaurant' : 'Add restaurant',
        actions: widget.restaurant != null
            ? [
                IconButton(
                  icon: const Icon(Icons.menu_book),
                  tooltip: 'Manage menu',
                  onPressed: () {
                    final restaurantId = widget.restaurant!['id'];
                    final id = restaurantId is int
                        ? restaurantId
                        : int.parse(restaurantId.toString());
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MerchantMenuPage(
                          restaurantId: id,
                          restaurantName: widget.restaurant!['name'],
                        ),
                      ),
                    );
                  },
                ),
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
                        if (context.mounted) {
                          Navigator.pop(context, true);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to delete: ${e.toString()}',
                              ),
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
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basic Information
                    _buildSectionTitle('Basic Information'),
                    AppTextField(
                      controller: _nameController,
                      label: 'Restaurant name *',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Restaurant name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      controller: _slugController,
                      label: 'Slug (auto-generated if empty)',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      controller: _descriptionController,
                      label: 'Description',
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    _buildSectionTitle('Location'),
                    CompositedTransformTarget(
                      link: _cityLayerLink,
                      child: AppTextField(
                        key: _cityFieldKey,
                        controller: _cityController,
                        focusNode: _cityFocusNode,
                        label: 'City *',
                        readOnly: true,
                        onTap: () {
                          if (!_cityFocusNode.hasFocus) {
                            _cityFocusNode.requestFocus();
                          } else {
                            _showOverlay();
                          }
                        },
                        onChanged: (_) {},
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'City is required';
                          }
                          if (_selectedCityId == null) {
                            return 'Please select a city from the dropdown';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      controller: _addressController,
                      label: 'Address *',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Address is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      controller: _postcodeController,
                      label: 'Postcode',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _latitudeController,
                            label: 'Latitude',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: AppTextField(
                            controller: _longitudeController,
                            label: 'Longitude',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Contact Information
                    _buildSectionTitle('Contact Information'),
                    AppTextField(
                      controller: _phoneController,
                      label: 'Phone number',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      controller: _emailController,
                      label: 'Email',
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
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      controller: _websiteController,
                      label: 'Website URL',
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Categories
                    _buildSectionTitle('Categories'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((category) {
                        final categoryId = category['id'] as int;
                        final isSelected = _selectedCategoryIds.contains(
                          categoryId,
                        );
                        return FilterChip(
                          label: Text(category['name'] as String),
                          selected: isSelected,
                          selectedColor: AppColors.primary.withValues(
                            alpha: 0.1,
                          ),
                          checkmarkColor: AppColors.primary,
                          labelStyle: AppTypography.body.copyWith(
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textDisabled.withValues(
                                      alpha: 0.3,
                                    ),
                            ),
                          ),
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
                    const SizedBox(height: AppSpacing.xxl),

                    // Price Range
                    _buildSectionTitle('Price Range'),
                    RadioGroup<int>(
                      groupValue: _priceRange,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _priceRange = value;
                          });
                        }
                      },
                      child: Row(
                        children: [
                          Expanded(
                            child: RadioListTile<int>(
                              title: const Text('£'),
                              value: 1,
                              activeColor: AppColors.primary,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<int>(
                              title: const Text('££'),
                              value: 2,
                              activeColor: AppColors.primary,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<int>(
                              title: const Text('£££'),
                              value: 3,
                              activeColor: AppColors.primary,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<int>(
                              title: const Text('££££'),
                              value: 4,
                              activeColor: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Opening Hours
                    _buildSectionTitle('Opening Hours (Optional)'),
                    ..._openingHours.entries.map((entry) {
                      final controller = TextEditingController(
                        text: entry.value,
                      );
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.md,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 100,
                              child: Text(
                                entry.key[0].toUpperCase() +
                                    entry.key.substring(1),
                                style: AppTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: AppTextField(
                                controller: controller,
                                label: 'e.g., 10:00-22:00',
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
                    const SizedBox(height: AppSpacing.xxxl),

                    // Save Button
                    PrimaryButton(
                      label: widget.restaurant != null
                          ? 'Update restaurant'
                          : 'Create restaurant',
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _saveRestaurant,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(
        title,
        style: AppTypography.title,
      ),
    );
  }
}
