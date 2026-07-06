import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart' show Geolocator;
import 'package:discount_buddy/design/app_design.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_gradient_button.dart';
import '../../components/app_app_bar.dart';
import '../../components/inputs.dart';
import '../../services/merchant_service.dart';
import '../../services/location_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/restaurant.dart' as model;
import '../../routes/app_routes.dart';

/// Add/Edit Restaurant Page for Merchants
class AddRestaurantPage extends StatefulWidget {
  final Map<String, dynamic>? restaurant; // If provided, edit mode; otherwise, create mode

  const AddRestaurantPage({super.key, this.restaurant});

  @override
  State<AddRestaurantPage> createState() => _AddRestaurantPageState();
}

class _AddRestaurantPageState extends State<AddRestaurantPage> {
  final MerchantService _merchantService = MerchantService();
  final LocationService _locationService = LocationService();
  final _formKey = GlobalKey<FormState>();
  final GlobalKey _loyaltySectionKey = GlobalKey();
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
  bool _loyaltyCardEnabled = false;
  final _loyaltyRequiredRedemptionsController = TextEditingController();
  final _loyaltyRewardDescriptionController = TextEditingController();

  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _cuisines = [];
  int? _selectedCityId;
  String _selectedCityName = '';
  final _cityController = TextEditingController();
  final _cityFocusNode = FocusNode();
  List<Map<String, dynamic>> _filteredCities = [];
  List<int> _selectedCategoryIds = [];
  List<int> _selectedCuisineIds = [];
  List<Map<String, dynamic>> _facilities = [];
  List<int> _selectedFacilityIds = [];
  int _priceRange = 2;
  String _menuType = 'structured'; // Default to structured
  List<model.RestaurantImage> _restaurantImages = [];
  final ImagePicker _picker = ImagePicker();
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

  Future<void> _fetchCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final position = await _locationService.getCurrentLocation();
      setState(() {
        _latitudeController.text = position.latitude.toString();
        _longitudeController.text = position.longitude.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } on LocationServiceDisabledException {
      if (mounted) {
        _showLocationHelpSnackBar(
          'Location (GPS) is turned off. Turn it on in system settings, then try again.',
          isSystemLocationOff: true,
        );
      }
    } on LocationPermissionDeniedException {
      if (mounted) {
        _showLocationHelpSnackBar(
          'Location access is required. Allow it in app settings, then try again.',
          isSystemLocationOff: false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _locationErrorUserMessage(e),
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.black,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
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

  void _showLocationHelpSnackBar(String message, {required bool isSystemLocationOff}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        action: SnackBarAction(
          label: 'Settings',
          textColor: Colors.white,
          onPressed: () async {
            if (isSystemLocationOff) {
              await Geolocator.openLocationSettings();
            } else {
              await Geolocator.openAppSettings();
            }
          },
        ),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  String _locationErrorUserMessage(Object e) {
    var s = e.toString();
    if (s.startsWith('Exception: ')) s = s.substring(11);
    return "Couldn't get your current location. $s";
  }

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
    _loyaltyRequiredRedemptionsController.dispose();
    _loyaltyRewardDescriptionController.dispose();
    _cityFocusNode.removeListener(_onCityFocusChange);
    _cityFocusNode.dispose();
    _hideOverlay();
    super.dispose();
  }

  void _scrollToLoyaltySection() {
    final context = _loyaltySectionKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _loadReferenceData() async {
    try {
      final results = await Future.wait([
        _merchantService.getCities(),
        _merchantService.getCategories(),
        _merchantService.getFacilities(),
        _merchantService.getCuisines(),
      ]);

      if (mounted) {
        setState(() {
          _cities = results[0];
          _categories = results[1];
          _facilities = results[2];
          _cuisines = results[3];
          _filteredCities = _cities;
          _isLoadingData = false;
        });

        if (widget.restaurant != null && widget.restaurant!['scrollToLoyalty'] == true) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Future.delayed(const Duration(milliseconds: 350), () {
              if (mounted) {
                _scrollToLoyaltySection();
              }
            });
          });
        }
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
    _menuType = restaurant['menu_type'] as String? ?? 'structured';

    // Load images
    if (restaurant['images'] != null) {
      final imagesData = restaurant['images'] as List;
      _restaurantImages = imagesData.map((img) => model.RestaurantImage.fromJson(img)).toList();
    }

    // Load city
    if (restaurant['city'] != null) {
      final city = restaurant['city'] as Map<String, dynamic>;
      _selectedCityId = city['id'] as int?;
      _selectedCityName = city['name'] as String? ?? '';
      _cityController.text = _selectedCityName;
    }

    // Load categories
    final categoriesData = restaurant['categories'] ?? restaurant['category_ids'];
    if (categoriesData != null && categoriesData is List) {
      _selectedCategoryIds = categoriesData.map((c) {
        if (c is Map) return c['id'] as int;
        return c as int;
      }).toList();
    }

    // Load cuisines
    final cuisinesData = restaurant['cuisines'] ?? restaurant['cuisine_ids'];
    if (cuisinesData != null && cuisinesData is List) {
      _selectedCuisineIds = cuisinesData.map((c) {
        if (c is Map) return c['id'] as int;
        return c as int;
      }).toList();
    }

    // Load facilities
    final facilitiesData = restaurant['facilities'] ?? restaurant['facility_ids'];
    if (facilitiesData != null && facilitiesData is List) {
      _selectedFacilityIds = facilitiesData.map((f) {
        if (f is Map) return f['id'] as int;
        return f as int;
      }).toList();
    }

    // Load loyalty details
    _loyaltyCardEnabled = restaurant['loyalty_card_enabled'] as bool? ?? false;
    _loyaltyRequiredRedemptionsController.text = restaurant['loyalty_required_redemptions']?.toString() ?? '';
    _loyaltyRewardDescriptionController.text = restaurant['loyalty_reward_description'] as String? ?? '';

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
        'category_ids': _selectedCategoryIds,
        'cuisine_ids': _selectedCuisineIds,
        'facility_ids': _selectedFacilityIds,
        'price_range': _priceRange,
        'menu_type': _menuType,
        if (openingHours.isNotEmpty) 'opening_hours': openingHours,
        'loyalty_card_enabled': _loyaltyCardEnabled,
        if (_loyaltyCardEnabled) ...{
          'loyalty_required_redemptions': int.tryParse(_loyaltyRequiredRedemptionsController.text.trim()) ?? 0,
          'loyalty_reward_description': _loyaltyRewardDescriptionController.text.trim(),
        }
      };

      if (_websiteController.text.trim().isNotEmpty) {
        restaurantData['website'] = _websiteController.text.trim();
      }

      // Remove empty optional fields but keep IDs and lists that might be empty if intended
      restaurantData.removeWhere(
        (key, value) =>
            (value == null ||
                value == '' ||
                (value is List && value.isEmpty)) &&
            key != 'city_id' &&
            key != 'category_ids' &&
            key != 'facility_ids' &&
            key != 'cuisine_ids' &&
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

  Future<void> _pickAndUploadImage(String type) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (image == null) return;

    if (widget.restaurant == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please save the restaurant first before uploading images.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final restaurantId = widget.restaurant!['id'];
      final id = restaurantId is int ? restaurantId : int.parse(restaurantId.toString());

      await _merchantService.uploadRestaurantImage(
        restaurantId: id,
        imagePath: image.path,
        imageType: type,
        isPrimary: type == 'gallery' &&
            _restaurantImages
                .where((img) => img.imageType == 'gallery')
                .isEmpty,
      );

      // Reload restaurant data to get updated images list
      final updatedRestaurant = await _merchantService.getRestaurantDetail(id);
      if (mounted) {
        setState(() {
          if (updatedRestaurant['images'] != null) {
            final imagesData = updatedRestaurant['images'] as List;
            _restaurantImages = imagesData
                .map((img) => model.RestaurantImage.fromJson(img))
                .toList();
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image uploaded successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: ${e.toString()}'),
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

  Future<void> _deleteImage(int imageId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _merchantService.deleteRestaurantImage(imageId);
      if (mounted) {
        setState(() {
          _restaurantImages.removeWhere((img) => img.id == imageId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image deleted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete image: ${e.toString()}'),
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

  Future<void> _setPrimaryImage(int imageId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _merchantService.setPrimaryImage(imageId);
      if (mounted) {
        setState(() {
          _restaurantImages = _restaurantImages.map((img) {
            if (img.imageType == 'gallery') {
              return model.RestaurantImage(
                id: img.id,
                image: img.image,
                altText: img.altText,
                imageType: img.imageType,
                isPrimary: img.id == imageId,
                order: img.order,
              );
            }
            return img;
          }).toList();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Primary image updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update primary image: ${e.toString()}'),
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

  Future<void> _selectTimeRange(String day) async {
    FocusManager.instance.primaryFocus?.unfocus();
    FocusScope.of(context).requestFocus(FocusNode());
    final TimeOfDay? pickedStart = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      helpText: 'Opening Time for ${day[0].toUpperCase()}${day.substring(1)}',
    );
    if (pickedStart == null) return;
    
    if (!mounted) return;
    
    final TimeOfDay? pickedEnd = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 22, minute: 0),
      helpText: 'Closing Time for ${day[0].toUpperCase()}${day.substring(1)}',
    );
    if (pickedEnd == null) return;
    
    setState(() {
      final startStr = '${pickedStart.hour.toString().padLeft(2, '0')}:${pickedStart.minute.toString().padLeft(2, '0')}';
      final endStr = '${pickedEnd.hour.toString().padLeft(2, '0')}:${pickedEnd.minute.toString().padLeft(2, '0')}';
      final timeString = '$startStr-$endStr';
      _openingHours[day] = timeString;

      // Autofill other days if monday is selected and others are empty
      if (day == 'monday') {
        final allOtherEmpty = _openingHours.entries
            .where((e) => e.key != 'monday')
            .every((e) => e.value.isEmpty);
        if (allOtherEmpty) {
          _openingHours.forEach((key, value) {
            if (key != 'monday' && value.isEmpty) {
              _openingHours[key] = timeString;
            }
          });
        }
      }
    });
  }

  Future<void> _selectTime(String day, bool isStart) async {
    FocusManager.instance.primaryFocus?.unfocus();
    FocusScope.of(context).requestFocus(FocusNode());
    final currentVal = _openingHours[day] ?? '';
    if (currentVal.isEmpty) return;
    
    final parts = currentVal.split('-');
    if (parts.length != 2) return;
    
    final timeString = isStart ? parts[0] : parts[1];
    final timeParts = timeString.split(':');
    final initialTime = TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: isStart ? 'Opening Time for ${day[0].toUpperCase()}${day.substring(1)}' : 'Closing Time for ${day[0].toUpperCase()}${day.substring(1)}',
    );
    
    if (picked == null) return;
    
    setState(() {
      final pickedStr = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      if (isStart) {
        _openingHours[day] = '$pickedStr-${parts[1]}';
      } else {
        _openingHours[day] = '${parts[0]}-$pickedStr';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppAppBar(
        titleText: widget.restaurant != null ? 'Edit Restaurant' : 'Add Restaurant',
        backgroundColor: Colors.transparent,
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
                    Get.toNamed(
                      AppRoutes.merchantMenu,
                      arguments: {
                        'restaurantId': id,
                        'restaurantName': widget.restaurant!['name'],
                      },
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
                        title: Text('Delete Restaurant?', style: AppTypography.title.copyWith(fontSize: 18)),
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
                              style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                            ),
                          ),
                          AppGradientButton(
                            onPressed: () => Navigator.pop(context, true),
                            width: 120,
                            height: 48,
                            gradient: LinearGradient(colors: [AppColors.error, AppColors.error.withValues(alpha: 0.8)]),
                            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
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
                                readOnly: true,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(
                              child: AppTextField(
                                controller: _longitudeController,
                                label: 'Longitude',
                                readOnly: true,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _fetchCurrentLocation,
                            icon: const Icon(Icons.my_location),
                            label: const Text('Update Restaurant Location'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.merchantIndigo,
                              side: const BorderSide(color: AppColors.merchantIndigo),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
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
                              labelStyle: AppTypography.bodySmall.copyWith(
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
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
                    _buildSectionHeader('Cuisines', Icons.restaurant_rounded),
                    const SizedBox(height: AppSpacing.md),
                    _buildFormSection(
                      children: [
                        Text(
                          'Select the specific cuisines your restaurant serves.',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _cuisines.map((cuisine) {
                            final cuisineId = cuisine['id'] as int;
                            final isSelected = _selectedCuisineIds.contains(cuisineId);
                            return FilterChip(
                              label: Text(cuisine['name'] as String),
                              selected: isSelected,
                              showCheckmark: false,
                              selectedColor: AppColors.merchantIndigo,
                              backgroundColor: AppColors.background,
                              labelStyle: AppTypography.bodySmall.copyWith(
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
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
                                    _selectedCuisineIds.add(cuisineId);
                                  } else {
                                    _selectedCuisineIds.remove(cuisineId);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xl),
                    _buildSectionHeader('Facilities', Icons.featured_play_list_rounded),
                    const SizedBox(height: AppSpacing.md),
                    _buildFormSection(
                      children: [
                        Text(
                          'Select the amenities and facilities available at your restaurant.',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _facilities.map((facility) {
                            final facilityId = facility['id'] as int;
                            final isSelected = _selectedFacilityIds.contains(facilityId);
                            return FilterChip(
                              label: Text(facility['name'] as String),
                              selected: isSelected,
                              showCheckmark: false,
                              selectedColor: AppColors.merchantIndigo,
                              backgroundColor: AppColors.background,
                              labelStyle: AppTypography.bodySmall.copyWith(
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
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
                                    _selectedFacilityIds.add(facilityId);
                                  } else {
                                    _selectedFacilityIds.remove(facilityId);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xl),
                    _buildSectionHeader('Menu Type', Icons.restaurant_menu_rounded),
                    const SizedBox(height: AppSpacing.md),
                    _buildFormSection(
                      children: [
                        Text(
                          'Choose how you want to display your menu to users.',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        RadioGroup<String>(
                          groupValue: _menuType,
                          onChanged: (value) {
                            setState(() {
                              _menuType = value!;
                            });
                          },
                          child: Row(
                            children: [
                              Expanded(
                                child: RadioListTile<String>(
                                  title: Text('Structured', style: AppTypography.bodySmall),
                                  value: 'structured',
                                  activeColor: AppColors.merchantIndigo,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<String>(
                                  title: Text('Images', style: AppTypography.bodySmall),
                                  value: 'image',
                                  activeColor: AppColors.merchantIndigo,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
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
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 90,
                                child: Text(
                                  entry.key[0].toUpperCase() + entry.key.substring(1),
                                  style: AppTypography.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (entry.value.isEmpty)
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _selectTimeRange(entry.key),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: AppColors.background,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppColors.cardBorder),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text('Closed', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                                    ),
                                  ),
                                )
                              else ...[
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _selectTime(entry.key, true),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: AppColors.merchantIndigo.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppColors.merchantIndigo.withValues(alpha: 0.3)),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        entry.value.split('-')[0],
                                        style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.merchantIndigo),
                                      ),
                                    ),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Text('-', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                                ),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _selectTime(entry.key, false),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: AppColors.merchantIndigo.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppColors.merchantIndigo.withValues(alpha: 0.3)),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        entry.value.split('-').length > 1 ? entry.value.split('-')[1] : '',
                                        style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.merchantIndigo),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  onPressed: () {
                                    setState(() {
                                      _openingHours[entry.key] = '';
                                    });
                                  },
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                     const SizedBox(height: AppSpacing.xl),
                     _buildSectionHeader('Loyalty Card Program', Icons.card_membership_rounded, key: _loyaltySectionKey),
                     const SizedBox(height: AppSpacing.md),
                     _buildFormSection(
                       children: [
                         SwitchListTile(
                           title: Text(
                             'Enable Loyalty Card',
                             style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
                           ),
                           subtitle: Text(
                             'Reward repeat customers after a set number of redemptions',
                             style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                           ),
                           value: _loyaltyCardEnabled,
                           activeTrackColor: AppColors.merchantIndigo,
                           contentPadding: EdgeInsets.zero,
                           onChanged: (bool value) {
                             setState(() {
                               _loyaltyCardEnabled = value;
                             });
                           },
                         ),
                         if (_loyaltyCardEnabled) ...[
                           const SizedBox(height: AppSpacing.lg),
                           AppTextField(
                             controller: _loyaltyRequiredRedemptionsController,
                             label: 'Required Redemptions *',
                             hintText: 'e.g. 10',
                             keyboardType: TextInputType.number,
                             validator: (value) {
                               if (!_loyaltyCardEnabled) return null;
                               if (value == null || value.trim().isEmpty) {
                                 return 'Required redemptions is required';
                               }
                               final val = int.tryParse(value.trim());
                               if (val == null || val < 1) {
                                 return 'Must be a number greater than 0';
                               }
                               return null;
                             },
                           ),
                           const SizedBox(height: AppSpacing.lg),
                           AppTextField(
                             controller: _loyaltyRewardDescriptionController,
                             label: 'Reward Description *',
                             hintText: 'e.g. Free main course or dessert',
                             validator: (value) {
                               if (!_loyaltyCardEnabled) return null;
                               if (value == null || value.trim().isEmpty) {
                                 return 'Reward description is required';
                               }
                               return null;
                             },
                           ),
                         ],
                       ],
                     ),

                     const SizedBox(height: AppSpacing.xl),
                     _buildSectionHeader('Restaurant Gallery', Icons.image_rounded),
                    const SizedBox(height: AppSpacing.md),
                    _buildFormSection(
                      children: [
                        Text(
                          'Upload photos of your restaurant, ambiance, and popular dishes.',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildImageGrid('gallery'),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _pickAndUploadImage('gallery'),
                            icon: const Icon(Icons.add_a_photo_rounded),
                            label: const Text('Add Gallery Image'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.merchantIndigo,
                              side: const BorderSide(color: AppColors.merchantIndigo),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (_menuType == 'image') ...[
                      const SizedBox(height: AppSpacing.xl),
                      _buildSectionHeader('Menu Images', Icons.menu_book_rounded),
                      const SizedBox(height: AppSpacing.md),
                      _buildFormSection(
                        children: [
                          Text(
                            'Upload clear photos of your physical menu.',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _buildImageGrid('menu'),
                          const SizedBox(height: AppSpacing.md),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _pickAndUploadImage('menu'),
                              icon: const Icon(Icons.add_photo_alternate_rounded),
                              label: const Text('Add Menu Image'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.merchantIndigo,
                                side: const BorderSide(color: AppColors.merchantIndigo),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: AppSpacing.xxxl),
                    AppGradientButton(
                      onPressed: _isLoading ? null : _saveRestaurant,
                      isLoading: _isLoading,
                      child: Text(widget.restaurant != null ? 'Save Changes' : 'Create Restaurant'),
                    ),
                    const SizedBox(height: 100), // Bottom padding
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, {Key? key}) {
    return Row(
      key: key,
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

  Widget _buildImageGrid(String type) {
    final images = _restaurantImages.where((img) => img.imageType == type).toList();

    if (images.isEmpty) {
      return Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder, style: BorderStyle.solid),
        ),
        child: Center(
          child: Text(
            'No images uploaded yet',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textDisabled),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final image = images[index];
        return Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: image.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: image.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppColors.cardBorder,
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.cardBorder,
                          child: const Icon(Icons.error_outline),
                        ),
                      )
                    : Container(
                        color: AppColors.cardBorder,
                        child: const Icon(Icons.image_not_supported_outlined),
                      ),
              ),
            ),
            if (type == 'gallery' && image.isPrimary)
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.merchantIndigo,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Primary',
                    style: AppTypography.caption.copyWith(color: AppColors.white, fontSize: 8),
                  ),
                ),
              ),
            Positioned(
              top: 0,
              right: 0,
              child: PopupMenuButton<String>(
                icon: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.more_vert, size: 14, color: Colors.white),
                ),
                padding: EdgeInsets.zero,
                onSelected: (value) {
                  if (value == 'delete') {
                    _deleteImage(image.id);
                  } else if (value == 'primary') {
                    _setPrimaryImage(image.id);
                  }
                },
                itemBuilder: (context) => [
                  if (type == 'gallery' && !image.isPrimary)
                    const PopupMenuItem(
                      value: 'primary',
                      child: Row(
                        children: [
                          Icon(Icons.star_rounded, size: 18, color: Colors.amber),
                          SizedBox(width: 8),
                          Text('Set as Primary'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
