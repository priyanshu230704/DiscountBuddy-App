import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/theme_provider.dart';
import '../../services/merchant_service.dart';
import '../../widgets/skeleton_loader.dart';
import 'add_restaurant_page.dart';

/// Merchant Restaurants Management Page
class MerchantRestaurantsPage extends StatefulWidget {
  const MerchantRestaurantsPage({super.key});

  @override
  State<MerchantRestaurantsPage> createState() =>
      _MerchantRestaurantsPageState();
}

class _MerchantRestaurantsPageState extends State<MerchantRestaurantsPage> {
  final MerchantService _merchantService = MerchantService();
  List<Map<String, dynamic>> _restaurants = [];
  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _filteredCities = [];
  int? _selectedCityId;
  String _selectedCityName = '';
  final _cityController = TextEditingController();
  final _cityFocusNode = FocusNode();
  final LayerLink _cityLayerLink = LayerLink();
  OverlayEntry? _cityOverlayEntry;
  final GlobalKey _cityFieldKey = GlobalKey();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Defer data loading to avoid blocking main thread
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
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
  }

  void _hideOverlay() {
    _cityOverlayEntry?.remove();
    _cityOverlayEntry = null;
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
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                shadowColor: Colors.black.withOpacity(0.3),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 250),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: NeoTasteColors.textDisabled.withOpacity(0.2),
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
                                color: NeoTasteColors.textDisabled,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _cityController.text.isEmpty
                                    ? 'Loading cities...'
                                    : 'No results found for "${_cityController.text}"',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  color: NeoTasteColors.textSecondary,
                                  fontSize: 14,
                                ),
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
                              color: NeoTasteColors.textDisabled.withOpacity(
                                0.1,
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
                                  color: NeoTasteColors.accent,
                                ),
                                title: Text(
                                  cityName,
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: NeoTasteColors.textPrimary,
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
                                  _loadRestaurants();
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
    _cityController.dispose();
    _cityFocusNode.removeListener(_onCityFocusChange);
    _cityFocusNode.dispose();
    _hideOverlay();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([_loadCities(), _loadRestaurants()]);
  }

  Future<void> _loadCities() async {
    try {
      final cities = await _merchantService.getCities();
      if (mounted) {
        setState(() {
          _cities = cities;
          _filteredCities = cities;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _loadRestaurants() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final restaurants = await _merchantService.getMerchantRestaurants(
        cityId: _selectedCityId,
      );
      if (mounted) {
        setState(() {
          _restaurants = restaurants;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load restaurants: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoTasteColors.background,
      appBar: AppBar(
        title: Text(
          'My Restaurants',
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: NeoTasteColors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddRestaurantPage(),
                ),
              ).then((_) => _loadRestaurants());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: NeoTasteColors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter by Location',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: NeoTasteColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                CompositedTransformTarget(
                  link: _cityLayerLink,
                  child: TextField(
                    key: _cityFieldKey,
                    controller: _cityController,
                    focusNode: _cityFocusNode,
                    readOnly: true,
                    onTap: () {
                      if (!_cityFocusNode.hasFocus) {
                        _cityFocusNode.requestFocus();
                      } else {
                        _showOverlay();
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Search City...',
                      hintStyle: GoogleFonts.inter(
                        color: NeoTasteColors.textDisabled,
                      ),
                      prefixIcon: const Icon(
                        Icons.location_on,
                        size: 20,
                        color: NeoTasteColors.accent,
                      ),
                      suffixIcon:
                          _selectedCityId != null ||
                              _cityController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                setState(() {
                                  _cityController.clear();
                                  _selectedCityId = null;
                                  _selectedCityName = '';
                                  _hideOverlay();
                                });
                                _loadRestaurants();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: NeoTasteColors.textDisabled.withOpacity(0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: NeoTasteColors.textDisabled.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: NeoTasteColors.accent,
                        ),
                      ),
                      filled: true,
                      fillColor: NeoTasteColors.background,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    style: GoogleFonts.inter(fontSize: 14),
                    onChanged: (value) {
                      setState(() {
                        if (value.isEmpty) {
                          _filteredCities = _cities;
                          if (_selectedCityId != null) {
                            _selectedCityId = null;
                            _selectedCityName = '';
                            _loadRestaurants();
                          }
                        } else {
                          _filteredCities = _cities.where((city) {
                            final cityName = (city['name'] as String? ?? '')
                                .toLowerCase();
                            return cityName.contains(value.toLowerCase());
                          }).toList();

                          if (_selectedCityName.toLowerCase() !=
                              value.toLowerCase()) {
                            _selectedCityId = null;
                          }
                        }
                        _cityOverlayEntry?.markNeedsBuild();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 5,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: SkeletonLoader(
                        height: 120,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  )
                : _restaurants.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.restaurant,
                          size: 64,
                          color: NeoTasteColors.textDisabled,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No restaurants yet',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: NeoTasteColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add your first restaurant to get started',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: NeoTasteColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddRestaurantPage(),
                              ),
                            ).then((_) => _loadRestaurants());
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: NeoTasteColors.accent,
                            foregroundColor: NeoTasteColors.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                          ),
                          child: Text(
                            'Add Restaurant',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadRestaurants,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _restaurants.length,
                      itemBuilder: (context, index) {
                        final restaurant = _restaurants[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _RestaurantCard(
                            restaurant: restaurant,
                            onTap: () async {
                              // Use existing restaurant data or fetch full details
                              final restaurantId = restaurant['id'];
                              final id = restaurantId is int
                                  ? restaurantId
                                  : int.tryParse(restaurantId.toString());

                              if (id != null) {
                                try {
                                  final fullRestaurant = await _merchantService
                                      .getRestaurantDetails(id);
                                  if (mounted) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AddRestaurantPage(
                                          restaurant: fullRestaurant,
                                        ),
                                      ),
                                    ).then((refresh) {
                                      if (refresh == true) {
                                        _loadRestaurants();
                                      }
                                    });
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to load restaurant: ${e.toString()}',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  final Map<String, dynamic> restaurant;
  final VoidCallback onTap;

  const _RestaurantCard({required this.restaurant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: NeoTasteColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant['name'] as String? ?? 'Unknown',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: NeoTasteColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (restaurant['categories'] != null &&
                      (restaurant['categories'] as List).isNotEmpty)
                    Text(
                      (restaurant['categories'] as List).first['name']
                              as String? ??
                          '',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: NeoTasteColors.textSecondary,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: NeoTasteColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          restaurant['address'] as String? ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: NeoTasteColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.chevron_right, color: NeoTasteColors.textDisabled),
          ],
        ),
      ),
    );
  }
}
