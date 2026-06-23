import 'package:flutter/material.dart';
import 'package:discount_buddy/design/app_design.dart';
import 'package:discount_buddy/widgets/app_scaffold.dart';
import 'package:discount_buddy/widgets/app_gradient_button.dart';
import 'package:discount_buddy/components/layout.dart' show AppCard;
import 'package:discount_buddy/widgets/empty_state_widget.dart';
import 'package:discount_buddy/widgets/skeleton_loader.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/merchant_service.dart';
import '../../models/restaurant.dart' as model;

import 'package:image_picker/image_picker.dart';

class MerchantMenuPage extends StatefulWidget {
  final int restaurantId;
  final String restaurantName;

  const MerchantMenuPage({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  State<MerchantMenuPage> createState() => _MerchantMenuPageState();
}

class _MerchantMenuPageState extends State<MerchantMenuPage> {
  final MerchantService _merchantService = MerchantService();
  List<Map<String, dynamic>> _categories = [];
  int? _selectedCategoryId;
  Map<String, dynamic>? _selectedCategoryData;
  bool _isLoading = true;
  bool _isItemsLoading = false;
  String _menuType = 'structured';
  List<model.RestaurantImage> _menuImages = [];
  final ImagePicker _picker = ImagePicker();

  /// Index of the menu item in the current category list whose details are expanded (null = all collapsed).
  int? _expandedItemIndex;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadMenu() async {
    setState(() => _isLoading = true);
    try {
      // Fetch restaurant details first to get menu_type
      final restaurant = await _merchantService.getRestaurantDetail(
        widget.restaurantId,
      );

      if (mounted) {
        setState(() {
          _menuType = restaurant['menu_type'] ?? 'structured';
          if (restaurant['images'] != null) {
            final imagesData = restaurant['images'] as List;
            _menuImages = imagesData
                .map((img) => model.RestaurantImage.fromJson(img))
                .where((img) => img.imageType == 'menu')
                .toList();
          }
        });
      }

      if (_menuType == 'structured') {
        final categories = await _merchantService.getMenuCategories(
          restaurantId: widget.restaurantId,
        );
        if (mounted) {
          setState(() {
            _categories = categories;
            _isLoading = false;
          });

          if (categories.isNotEmpty) {
            if (_selectedCategoryId == null) {
              _selectCategory(categories.first['id']);
            } else {
              // Check if selected category still exists
              final exists = categories.any(
                (c) => c['id'] == _selectedCategoryId,
              );
              if (exists) {
                _fetchCategoryItems(_selectedCategoryId!);
              } else {
                _selectCategory(categories.first['id']);
              }
            }
          }
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load menu: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _selectCategory(int categoryId) async {
    setState(() {
      _selectedCategoryId = categoryId;
      _expandedItemIndex = null;
    });
    _fetchCategoryItems(categoryId);
  }

  Future<void> _fetchCategoryItems(int categoryId) async {
    setState(() => _isItemsLoading = true);
    try {
      final categoryData = await _merchantService.getMenuCategoryDetails(
        categoryId,
        restaurantId: widget.restaurantId,
      );
      if (mounted && _selectedCategoryId == categoryId) {
        setState(() {
          _selectedCategoryData = categoryData;
          _isItemsLoading = false;
          _expandedItemIndex = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isItemsLoading = false);
        debugPrint('Error fetching category items: $e');
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: AppTypography.body,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTypography.bodySmall,
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.merchantIndigo,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Future<void> _addCategory() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Add Menu Category',
          style: AppTypography.title.copyWith(fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.sm),
            _buildTextField(
              controller: nameController,
              label: 'Category Name *',
            ),
            _buildTextField(
              controller: descriptionController,
              label: 'Description (Optional)',
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          AppGradientButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) return;
              Navigator.pop(context, true);
            },
            width: 150,
            height: 48,
            child: const Text(
              'Add Category',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _merchantService.createMenuCategory({
          'restaurant': widget.restaurantId,
          'name': nameController.text.trim(),
          'description': descriptionController.text.trim(),
          'order': _categories.length,
          'is_active': true,
        });
        _loadMenu();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add category: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _editCategory(Map<String, dynamic> category) async {
    final nameController = TextEditingController(text: category['name']);
    final descriptionController = TextEditingController(
      text: category['description'],
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Edit Category',
          style: AppTypography.title.copyWith(fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.sm),
            _buildTextField(
              controller: nameController,
              label: 'Category Name *',
            ),
            _buildTextField(
              controller: descriptionController,
              label: 'Description (Optional)',
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          AppGradientButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) return;
              Navigator.pop(context, true);
            },
            width: 150,
            height: 48,
            child: const Text(
              'Save Changes',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _merchantService.updateMenuCategory(category['id'], {
          'name': nameController.text.trim(),
          'description': descriptionController.text.trim(),
        });
        _loadMenu();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update category: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteCategory(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Delete Category?',
          style: AppTypography.title.copyWith(fontSize: 18),
        ),
        content: Text(
          'Are you sure you want to delete this category and all its items? This action cannot be undone.',
          style: AppTypography.body,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          AppGradientButton(
            onPressed: () => Navigator.pop(context, true),
            width: 120,
            height: 48,
            gradient: LinearGradient(
              colors: [AppColors.error, AppColors.error.withValues(alpha: 0.8)],
            ),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _merchantService.deleteMenuCategory(id);
        if (_selectedCategoryId == id) {
          _selectedCategoryId = null;
          _selectedCategoryData = null;
        }
        _loadMenu();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _addOrUpdateItem({Map<String, dynamic>? existingItem}) async {
    if (_selectedCategoryId == null) return;

    final nameController = TextEditingController(
      text: existingItem?['name'] ?? '',
    );
    final descriptionController = TextEditingController(
      text: existingItem?['description'] ?? '',
    );
    final priceController = TextEditingController(
      text: existingItem?['price']?.toString() ?? '',
    );

    bool isVegetarian = existingItem?['is_vegetarian'] ?? false;
    bool isVegan = existingItem?['is_vegan'] ?? false;
    bool isGlutenFree = existingItem?['is_gluten_free'] ?? false;
    bool isAvailable = existingItem?['is_available'] ?? true;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Text(
              existingItem == null ? 'Add Item' : 'Edit Item',
              style: AppTypography.title.copyWith(fontSize: 18),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    _buildTextField(
                      controller: nameController,
                      label: 'Item Name *',
                    ),
                    _buildTextField(
                      controller: priceController,
                      label: 'Price (£) *',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    _buildTextField(
                      controller: descriptionController,
                      label: 'Description (Optional)',
                      maxLines: 3,
                    ),
                    const Divider(height: 32),
                    Text(
                      'Dietary Tags',
                      style: AppTypography.subtitle.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SwitchListTile(
                      title: Text('Vegetarian', style: AppTypography.bodySmall),
                      value: isVegetarian,
                      activeThumbColor: AppColors.success,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) => setState(() => isVegetarian = v),
                    ),
                    SwitchListTile(
                      title: Text('Vegan', style: AppTypography.bodySmall),
                      value: isVegan,
                      activeThumbColor: AppColors.success,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) => setState(() => isVegan = v),
                    ),
                    SwitchListTile(
                      title: Text(
                        'Gluten Free',
                        style: AppTypography.bodySmall,
                      ),
                      value: isGlutenFree,
                      activeThumbColor: AppColors.merchantAmber,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) => setState(() => isGlutenFree = v),
                    ),
                    const Divider(height: 32),
                    SwitchListTile(
                      title: Text(
                        'Available',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      value: isAvailable,
                      activeThumbColor: AppColors.merchantIndigo,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) => setState(() => isAvailable = v),
                    ),
                  ],
                ),
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              AppGradientButton(
                onPressed: () {
                  if (nameController.text.trim().isEmpty ||
                      priceController.text.trim().isEmpty)
                    return;
                  Navigator.pop(context, {
                    if (existingItem != null && existingItem.containsKey('id'))
                      'id': existingItem['id'],
                    'name': nameController.text.trim(),
                    'description': descriptionController.text.trim(),
                    'price': priceController.text.trim(),
                    'is_vegetarian': isVegetarian,
                    'is_vegan': isVegan,
                    'is_gluten_free': isGlutenFree,
                    'is_available': isAvailable,
                  });
                },
                width: 160,
                height: 48,
                child: Text(
                  existingItem == null ? 'Add Item' : 'Save Changes',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (result != null) {
      _saveItem(result, isEdit: existingItem != null);
    }
  }

  Future<void> _saveItem(
    Map<String, dynamic> itemData, {
    required bool isEdit,
  }) async {
    if (_selectedCategoryId == null) return;

    try {
      if (isEdit) {
        final int id = itemData['id'];
        await _merchantService.updateMenuItem(id, itemData);
      } else {
        final newItemData = Map<String, dynamic>.from(itemData);
        newItemData['category'] = _selectedCategoryId;
        if (!newItemData.containsKey('order')) {
          newItemData['order'] = 0;
        }
        await _merchantService.createMenuItem(newItemData);
      }

      _fetchCategoryItems(_selectedCategoryId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item saved successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save item: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteItem(Map<String, dynamic> item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Delete Item?',
          style: AppTypography.title.copyWith(fontSize: 18),
        ),
        content: Text(
          'Are you sure you want to delete "${item['name']}"? This action cannot be undone.',
          style: AppTypography.body,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          AppGradientButton(
            onPressed: () => Navigator.pop(context, true),
            width: 120,
            height: 48,
            gradient: LinearGradient(
              colors: [AppColors.error, AppColors.error.withValues(alpha: 0.8)],
            ),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        if (item.containsKey('id')) {
          await _merchantService.deleteMenuItem(item['id']);
          _fetchCategoryItems(_selectedCategoryId!);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete item: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSearching,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isSearching) {
          _searchController.clear();
          _searchFocusNode.unfocus();
          setState(() {
            _searchQuery = '';
            _isSearching = false;
          });
        }
      },
      child: AppScaffold(
      appBar: _isSearching
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
              automaticallyImplyLeading: false,
              titleSpacing: AppSpacing.lg,
              toolbarHeight: 76,
              title: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.search,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                        decoration: const InputDecoration(
                          hintText: "Search menu items...",
                          hintStyle: TextStyle(
                            color: AppColors.textDisabled,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: AppTypography.body.copyWith(fontSize: 14),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _isSearching = false;
                        });
                      },
                    ),
                  ],
                ),
              ),
            )
          : AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).maybePop(),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.restaurantName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.title.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage categories & menu items',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
              centerTitle: false,
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
              titleSpacing: 8,
              toolbarHeight: 76,
              iconTheme: const IconThemeData(color: AppColors.textPrimary),
              actions: [
                if (!_isSearching &&
                    _menuType == 'structured' &&
                    _categories.isNotEmpty)
                  IconButton(
                    icon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () {
                      setState(() => _isSearching = true);
                      _searchFocusNode.requestFocus();
                    },
                  ),
              ],
            ),
      body: _isLoading
          ? _buildLoadingState()
          : _menuType == 'image'
          ? _buildImageMenu()
          : _buildStructuredMenu(),
      floatingActionButton: _menuType == 'image'
          ? FloatingActionButton.extended(
              onPressed: _pickAndUploadMenuPhoto,
              backgroundColor: AppColors.primary,
              icon: const Icon(
                Icons.add_photo_alternate_rounded,
                color: Colors.white,
              ),
              label: const Text(
                'Add Menu Image',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : _categories.isEmpty
          ? null
          : Container(
              decoration: BoxDecoration(
                gradient: AppColors.purpleGradient,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: _addOrUpdateItem,
                backgroundColor: Colors.transparent,
                elevation: 0,
                highlightElevation: 0,
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text(
                  'Add Item',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildImageMenu() {
    if (_menuImages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.merchantIndigo.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                size: 64,
                color: AppColors.merchantIndigo,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('No menu images yet', style: AppTypography.title),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: Text(
                'Upload photos of your physical menu so customers can see your full offerings.',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppGradientButton(
              onPressed: _pickAndUploadMenuPhoto,
              width: 200,
              child: const Text('Upload Menu Photo'),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.8,
      ),
      itemCount: _menuImages.length,
      itemBuilder: (context, index) {
        final image = _menuImages[index];
        return AppCard(
          padding: EdgeInsets.zero,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: image.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: image.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        placeholder: (context, url) => Container(
                          color: AppColors.shimmer,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.shimmer,
                          child: const Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                          ),
                        ),
                      )
                    : Container(
                        color: AppColors.shimmer,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: AppColors.textDisabled,
                        ),
                      ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _deleteMenuPhoto(image.id),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStructuredMenu() {
    return Column(
      children: [
        _buildCategorySelector(),
        Expanded(
          child: _categories.isEmpty
              ? _buildEmptyState()
              : _isItemsLoading
              ? _buildItemsLoadingState()
              : _buildItemsList(),
        ),
      ],
    );
  }

  /// Chip row: fixed height = chip size only (no tall container + vertical centering
  /// that left a visible gap before the list below).
  Widget _buildCategorySelector() {
    const double chipLineHeight = 40;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          height: chipLineHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _categories.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: _addCategory,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      height: chipLineHeight,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                );
              }

              final category = _categories[index - 1];
              final isSelected = _selectedCategoryId == category['id'];

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => _selectCategory(category['id']),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: chipLineHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppColors.purpleGradient : null,
                      color: isSelected ? null : AppColors.background,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                      border: isSelected
                          ? null
                          : Border.all(color: AppColors.cardBorder),
                    ),
                    child: Text(
                      category['name'],
                      style: AppTypography.bodySmall.copyWith(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    if (_selectedCategoryData == null)
      return const Center(child: CircularProgressIndicator());

    final allItems = _selectedCategoryData!['items'] as List<dynamic>? ?? [];
    final items = _searchQuery.isEmpty
        ? allItems
        : allItems.where((item) {
            final name = (item['name'] as String?)?.toLowerCase() ?? '';
            final description =
                (item['description'] as String?)?.toLowerCase() ?? '';
            final query = _searchQuery.toLowerCase();
            return name.contains(query) || description.contains(query);
          }).toList();

    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _fetchCategoryItems(_selectedCategoryId!),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 400,
            child: _searchQuery.isNotEmpty
                ? EmptyStateWidget(
                    icon: Icons.search_off_rounded,
                    title: 'No matching items',
                    message: 'Try adjusting your search query.',
                  )
                : EmptyStateWidget(
                    icon: Icons.fastfood_rounded,
                    title: 'No items in ${_selectedCategoryData!['name']}',
                    message: 'Add your first item to this category.',
                    primaryActionLabel: 'Add Item',
                    onPrimaryAction: _addOrUpdateItem,
                  ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchCategoryItems(_selectedCategoryId!),
      color: AppColors.merchantIndigo,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          100,
        ),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildCategorySectionHeader(),
          const SizedBox(height: 10),
          ...items.asMap().entries.map((e) {
            final item = Map<String, dynamic>.from(
              e.value as Map<dynamic, dynamic>,
            );
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _buildLightMenuItemCard(item, listIndex: e.key),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategorySectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            _selectedCategoryData!['name'] as String? ?? 'Category',
            style: AppTypography.title.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
              icon: const Icon(
                Icons.edit_rounded,
                color: AppColors.merchantBlue,
                size: 22,
              ),
              onPressed: () => _editCategory(_selectedCategoryData!),
            ),
            IconButton(
              style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.error,
                size: 22,
              ),
              onPressed: () => _deleteCategory(_selectedCategoryId!),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLightMenuItemCard(
    Map<String, dynamic> item, {
    required int listIndex,
  }) {
    final isAvailable = item['is_available'] as bool? ?? true;
    final name = item['name'] as String? ?? 'Item';
    final desc = item['description']?.toString().trim() ?? '';
    final priceStr = _formatMenuItemPrice(item['price']);
    final imageUrl = _menuItemImageUrl(item);
    final hasDietTag =
        item['is_vegetarian'] == true ||
        item['is_vegan'] == true ||
        item['is_gluten_free'] == true;
    final hasExpandable = desc.isNotEmpty || hasDietTag || !isAvailable;
    final hasAnyTagPill = hasDietTag || !isAvailable;
    final isOpen = hasExpandable && _expandedItemIndex == listIndex;

    final namePrice = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.title.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            height: 1.2,
            color: isAvailable ? AppColors.textDarkest : AppColors.textDisabled,
            decoration: isAvailable ? null : TextDecoration.lineThrough,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          priceStr,
          style: AppTypography.title.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            height: 1.2,
            color: isAvailable
                ? AppColors.merchantIndigo
                : AppColors.textDisabled,
          ),
        ),
      ],
    );

    final header = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _MenuItemThumb(imageUrl: imageUrl, isAvailable: isAvailable),
          const SizedBox(width: 10),
          Expanded(child: namePrice),
          _buildItemActionMenuButton(item, light: true),
          if (hasExpandable)
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              icon: Icon(
                isOpen ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                color: AppColors.textSecondary,
              ),
              onPressed: () {
                setState(() {
                  _expandedItemIndex = isOpen ? null : listIndex;
                });
              },
            ),
        ],
      ),
    );

    if (!hasExpandable) {
      return AppCard(padding: EdgeInsets.zero, child: header);
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          header,
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            clipBehavior: Clip.hardEdge,
            child: isOpen
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: _buildMenuItemDetailsPanel(
                      item: item,
                      desc: desc,
                      hasDesc: desc.isNotEmpty,
                      hasAnyTagPill: hasAnyTagPill,
                      isAvailable: isAvailable,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItemDetailsPanel({
    required Map<String, dynamic> item,
    required String desc,
    required bool hasDesc,
    required bool hasAnyTagPill,
    required bool isAvailable,
  }) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasDesc) ...[
            Text(
              'Description',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            if (hasAnyTagPill) const SizedBox(height: 12),
          ],
          if (hasAnyTagPill) ...[
            Text(
              'Tags',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (item['is_vegetarian'] == true)
                  _buildMenuTag('Veg', AppColors.success),
                if (item['is_vegan'] == true)
                  _buildMenuTag('Vegan', AppColors.success),
                if (item['is_gluten_free'] == true)
                  _buildMenuTag('GF', AppColors.merchantAmber),
                if (!isAvailable)
                  _buildMenuTag('Off menu', AppColors.textSecondary),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatMenuItemPrice(dynamic price) {
    if (price == null) return '—';
    final s = price.toString();
    if (s.startsWith('£')) return s;
    return '£$s';
  }

  String? _menuItemImageUrl(Map<String, dynamic> item) {
    final v =
        item['image'] ??
        item['image_url'] ??
        item['thumbnail_url'] ??
        item['photo'];
    if (v == null || v.toString().isEmpty) return null;
    return v.toString();
  }

  Widget _buildMenuTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildItemActionMenuButton(
    Map<String, dynamic> item, {
    required bool light,
  }) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      color: light ? AppColors.surface : const Color(0xFF1C1C1E),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.cardBorder),
      ),
      offset: const Offset(0, 32),
      icon: Icon(
        Icons.more_vert_rounded,
        color: light ? AppColors.textPrimary : const Color(0xFF8E8E93),
        size: 22,
      ),
      onSelected: (v) {
        if (v == 'edit') _addOrUpdateItem(existingItem: item);
        if (v == 'delete') _deleteItem(item);
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(
                Icons.edit_rounded,
                size: 18,
                color: AppColors.merchantBlue,
              ),
              const SizedBox(width: 10),
              Text(
                'Edit',
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: AppColors.error,
              ),
              const SizedBox(width: 10),
              Text(
                'Delete',
                style: AppTypography.body.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.xl),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: SkeletonLoader(
          height: 100,
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }

  Widget _buildItemsLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.xl),
      itemCount: 3,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: SkeletonLoader(
          height: 120,
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return EmptyStateWidget(
      icon: Icons.menu_book_rounded,
      title: _menuType == 'image' ? 'No menu images' : 'No menu categories',
      message: _menuType == 'image'
          ? 'Upload photos of your physical menu for customers to view.'
          : 'Organize your dishes into categories like "Starters" or "Mains".',
      primaryActionLabel: _menuType == 'image'
          ? 'Upload photo'
          : 'Add category',
      onPrimaryAction: _menuType == 'image'
          ? _pickAndUploadMenuPhoto
          : _addCategory,
    );
  }

  Future<void> _pickAndUploadMenuPhoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (image == null) return;

    setState(() => _isLoading = true);

    try {
      await _merchantService.uploadRestaurantImage(
        restaurantId: widget.restaurantId,
        imagePath: image.path,
        imageType: 'menu',
      );

      _loadMenu();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Menu photo uploaded successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload menu photo: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteMenuPhoto(int imageId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Delete Image?', style: AppTypography.title),
        content: Text(
          'Are you sure you want to delete this menu image?',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          AppGradientButton(
            onPressed: () => Navigator.pop(context, true),
            width: 120,
            height: 48,
            gradient: LinearGradient(
              colors: [AppColors.error, AppColors.error.withValues(alpha: 0.8)],
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      await _merchantService.deleteRestaurantImage(imageId);
      _loadMenu();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image deleted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete image: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _MenuItemThumb extends StatelessWidget {
  final String? imageUrl;
  final bool isAvailable;

  const _MenuItemThumb({required this.imageUrl, required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 40,
        height: 40,
        color: AppColors.shimmer,
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Opacity(
                opacity: isAvailable ? 1.0 : 0.45,
                child: CachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover,
                  width: 40,
                  height: 40,
                  placeholder: (context, url) => const Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Icon(
                    Icons.fastfood_rounded,
                    size: 20,
                    color: AppColors.textDisabled,
                  ),
                ),
              )
            : Icon(
                Icons.fastfood_rounded,
                size: 20,
                color: AppColors.textDisabled,
              ),
      ),
    );
  }
}
