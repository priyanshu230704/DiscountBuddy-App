import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../design/app_spacing.dart';
import '../../design/app_typography.dart';
import '../../components/inputs.dart';
import '../../components/buttons.dart';
import '../../components/app_app_bar.dart';
import '../../services/merchant_service.dart';
import 'merchant_menu_page.dart';

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
    RenderBox? renderBox = _cityFieldKey.currentContext?.findRenderObject() as RenderBox?;
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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
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
                              color: AppColors.textDisabled.withValues(alpha: 0.1),
                            ),
                            itemBuilder: (context, index) {
                              final city = _filteredCities[index];
                              final cityName = city['name'] as String? ?? 'Unknown';
                              return ListTile(
                                leading: const Icon(
                                  Icons.location_city_rounded,
                                  size: 20,
                                  color: AppColors.merchantIndigo,
                                ),
                                title: Text(
                                  cityName,
                                  style: AppTypography.body.copyWith(
                                    fontWeight: FontWeight.w600,
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
            backgroundColor: AppColors.error,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill out all required fields.'),
          backgroundColor: AppColors.error,
        ),
      );
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
              backgroundColor: AppColors.success,
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
              backgroundColor: AppColors.success,
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
            backgroundColor: AppColors.error,
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
        titleText: widget.restaurant != null ? 'Edit Restaurant' : 'Add Restaurant',
        backgroundColor: AppColors.surface,
        actions: widget.restaurant != null
            ? [
                IconButton(
                  icon: const Icon(Icons.restaurant_menu_rounded, color: AppColors.merchantIndigo),
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
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: AppColors.surface,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        title: Text('Delete Restaurant?', style: AppTypography.title),
                        content: Text(
                          'Are you sure you want to delete this restaurant? This action cannot be undone.',
                          style: AppTypography.body,
                        ),
                        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(
                              'Cancel',
                              style: AppTypography.body.copyWith(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      try {
                        final restaurantId = widget.restaurant!['id'];
                        final id = restaurantId is int ? restaurantId : int.parse(restaurantId.toString());
                        await _merchantService.deleteRestaurant(id);
                        if (context.mounted) {
                          Navigator.pop(context, true);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to delete: ${e.toString()}'),
                              backgroundColor: AppColors.error,
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
          ? const Center(child: CircularProgressIndicator(color: AppColors.merchantIndigo))
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionHeader('Basic Information', Icons.storefront_rounded),
                    const SizedBox(height: AppSpacing.md),
                    _buildFormSection(
                      children: [
                        AppTextField(
                          controller: _nameController,
                          label: 'Restaurant Name *',
                          hintText: 'e.g. Burger King',
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
                          label: 'Slug URL (Optional)',
                          hintText: 'e.g. burger-king (Auto-generated if empty)',
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppTextField(
                          controller: _descriptionController,
                          label: 'Description',
                          hintText: 'Tell customers about your restaurant...',
                          maxLines: 3,
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xl),
                    _buildSectionHeader('Location', Icons.location_on_rounded),
                    const SizedBox(height: AppSpacing.md),
                    _buildFormSection(
                      children: [
                        CompositedTransformTarget(
                          link: _cityLayerLink,
                          child: AppTextField(
                            key: _cityFieldKey,
                            controller: _cityController,
                            focusNode: _cityFocusNode,
                            label: 'City *',
                            readOnly: true,
                            hintText: 'Select a city',
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
                          label: 'Full Address *',
                          hintText: 'e.g. 123 High Street',
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
                          hintText: 'e.g. W1D 1AA',
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                controller: _latitudeController,
                                label: 'Latitude',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(
                              child: AppTextField(
                                controller: _longitudeController,
                                label: 'Longitude',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xl),
                    _buildSectionHeader('Contact Information', Icons.contact_phone_rounded),
                    const SizedBox(height: AppSpacing.md),
                    _buildFormSection(
                      children: [
                        AppTextField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          keyboardType: TextInputType.phone,
                          hintText: 'e.g. +44 20 7123 4567',
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppTextField(
                          controller: _emailController,
                          label: 'Email Address',
                          keyboardType: TextInputType.emailAddress,
                          hintText: 'e.g. contact@restaurant.com',
                          validator: (value) {
                            if (value != null && value.isNotEmpty && !value.contains('@')) {
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
                          hintText: 'e.g. https://www.restaurant.com',
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xl),
                    _buildSectionHeader('Categories', Icons.category_rounded),
                    const SizedBox(height: AppSpacing.md),
                    _buildFormSection(
                      children: [
                        Text(
                          'Select the types of cuisine and offerings that best describe your restaurant.',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _categories.map((category) {
                            final categoryId = category['id'] as int;
                            final isSelected = _selectedCategoryIds.contains(categoryId);
                            return FilterChip(
                              label: Text(category['name'] as String),
                              selected: isSelected,
                              showCheckmark: false,
                              selectedColor: AppColors.merchantIndigo,
                              backgroundColor: AppColors.background,
                              labelStyle: AppTypography.body.copyWith(
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? AppColors.white : AppColors.textPrimary,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.merchantIndigo
                                      : AppColors.cardBorder,
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
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xl),
                    _buildSectionHeader('Price Range', Icons.attach_money_rounded),
                    const SizedBox(height: AppSpacing.md),
                    _buildFormSection(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      children: [
                        Row(
                          children: [
                            _buildPriceTier(1, '£', 'Cheap Eats'),
                            _buildPriceTier(2, '££', 'Moderate'),
                            _buildPriceTier(3, '£££', 'Expensive'),
                            _buildPriceTier(4, '££££', 'Fine Dining'),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xl),
                    _buildSectionHeader('Opening Hours (Optional)', Icons.access_time_rounded),
                    const SizedBox(height: AppSpacing.md),
                    _buildFormSection(
                      padding: const EdgeInsets.only(top: 8, bottom: 8, left: 24, right: 24),
                      children: _openingHours.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md, top: AppSpacing.sm),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 85,
                                child: Text(
                                  entry.key[0].toUpperCase() + entry.key.substring(1),
                                  style: AppTypography.bodySmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                               ),
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final currentVal = entry.value;
                                    TimeOfDay? start;
                                    TimeOfDay? end;
                                    
                                    if (currentVal.contains('-')) {
                                      final parts = currentVal.split('-');
                                      final startParts = parts[0].split(':');
                                      final endParts = parts[1].split(':');
                                      if (startParts.length == 2) {
                                        start = TimeOfDay(hour: int.parse(startParts[0]), minute: int.parse(startParts[1]));
                                      }
                                      if (endParts.length == 2) {
                                        end = TimeOfDay(hour: int.parse(endParts[0]), minute: int.parse(endParts[1]));
                                      }
                                    }

                                    final TimeOfDay? pickedStart = await showTimePicker(
                                      context: context,
                                      initialTime: start ?? const TimeOfDay(hour: 9, minute: 0),
                                      helpText: 'Opening Time for ${entry.key}',
                                    );

                                    if (pickedStart != null) {
                                      if (context.mounted) {
                                        final TimeOfDay? pickedEnd = await showTimePicker(
                                          context: context,
                                          initialTime: end ?? const TimeOfDay(hour: 22, minute: 0),
                                          helpText: 'Closing Time for ${entry.key}',
                                        );
                                        
                                        if (pickedEnd != null) {
                                          setState(() {
                                            final startStr = '${pickedStart.hour.toString().padLeft(2, '0')}:${pickedStart.minute.toString().padLeft(2, '0')}';
                                            final endStr = '${pickedEnd.hour.toString().padLeft(2, '0')}:${pickedEnd.minute.toString().padLeft(2, '0')}';
                                            _openingHours[entry.key] = '$startStr-$endStr';
                                          });
                                        }
                                      }
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.cardBorder),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 16,
                                          color: entry.value.isEmpty ? AppColors.textDisabled : AppColors.merchantIndigo,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            entry.value.isEmpty ? 'Closed' : entry.value,
                                            style: AppTypography.bodySmall.copyWith(
                                              color: entry.value.isEmpty ? AppColors.textSecondary : AppColors.textPrimary,
                                              fontSize: 13,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (entry.value.isNotEmpty)
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _openingHours[entry.key] = '';
                                              });
                                            },
                                            child: const Icon(Icons.close, size: 16, color: AppColors.error),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: AppSpacing.xxxl),
                    PrimaryButton(
                      label: widget.restaurant != null ? 'Save Changes' : 'Create Restaurant',
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _saveRestaurant,
                    ),
                    const SizedBox(height: 100), // Bottom padding
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.merchantIndigo),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTypography.title.copyWith(fontSize: 18),
        ),
      ],
    );
  }

  Widget _buildFormSection({
    required List<Widget> children,
    EdgeInsets padding = const EdgeInsets.all(AppSpacing.xl),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.textDarkest.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildPriceTier(int value, String label, String tooltip) {
    final isSelected = _priceRange == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _priceRange = value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.merchantIndigo.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: AppTypography.title.copyWith(
                  color: isSelected ? AppColors.merchantIndigo : AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tooltip,
                style: AppTypography.caption.copyWith(
                  color: isSelected ? AppColors.merchantIndigo : AppColors.textDisabled,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
