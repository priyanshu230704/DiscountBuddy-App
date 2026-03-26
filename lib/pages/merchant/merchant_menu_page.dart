import 'package:flutter/material.dart';
import 'package:discount_buddy/design/app_design.dart';
import 'package:discount_buddy/widgets/app_scaffold.dart';
import 'package:discount_buddy/widgets/app_gradient_button.dart';
import 'package:discount_buddy/components/layout.dart' show AppCard;
import 'package:discount_buddy/widgets/empty_state_widget.dart';
import 'package:discount_buddy/widgets/skeleton_loader.dart';
import 'package:discount_buddy/components/app_app_bar.dart';
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

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    setState(() => _isLoading = true);
    try {
      // Fetch restaurant details first to get menu_type
      final restaurant = await _merchantService.getRestaurantDetail(widget.restaurantId);
      
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
              final exists = categories.any((c) => c['id'] == _selectedCategoryId);
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
            borderSide: const BorderSide(color: AppColors.merchantIndigo, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        title: Text('Add Menu Category', style: AppTypography.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.sm),
            _buildTextField(controller: nameController, label: 'Category Name *'),
            _buildTextField(controller: descriptionController, label: 'Description (Optional)'),
          ],
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
            onPressed: () {
              if (nameController.text.trim().isEmpty) return;
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.merchantIndigo,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Add Category', style: TextStyle(fontWeight: FontWeight.bold)),
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
    final descriptionController = TextEditingController(text: category['description']);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Edit Category', style: AppTypography.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.sm),
            _buildTextField(controller: nameController, label: 'Category Name *'),
            _buildTextField(controller: descriptionController, label: 'Description (Optional)'),
          ],
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
            onPressed: () {
              if (nameController.text.trim().isEmpty) return;
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.merchantIndigo,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
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
        title: Text('Delete Category?', style: AppTypography.title),
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

    final nameController = TextEditingController(text: existingItem?['name'] ?? '');
    final descriptionController = TextEditingController(text: existingItem?['description'] ?? '');
    final priceController = TextEditingController(text: existingItem?['price']?.toString() ?? '');

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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(existingItem == null ? 'Add Item' : 'Edit Item', style: AppTypography.title),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    _buildTextField(controller: nameController, label: 'Item Name *'),
                    _buildTextField(
                      controller: priceController,
                      label: 'Price (£) *',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    _buildTextField(
                      controller: descriptionController,
                      label: 'Description (Optional)',
                      maxLines: 3,
                    ),
                    const Divider(height: 32),
                    Text('Dietary Tags', style: AppTypography.subtitle.copyWith(color: AppColors.textPrimary)),
                    const SizedBox(height: AppSpacing.sm),
                    SwitchListTile(
                      title: Text('Vegetarian', style: AppTypography.body),
                      value: isVegetarian,
                      activeThumbColor: AppColors.success,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) => setState(() => isVegetarian = v),
                    ),
                    SwitchListTile(
                      title: Text('Vegan', style: AppTypography.body),
                      value: isVegan,
                      activeThumbColor: AppColors.success,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) => setState(() => isVegan = v),
                    ),
                    SwitchListTile(
                      title: Text('Gluten Free', style: AppTypography.body),
                      value: isGlutenFree,
                      activeThumbColor: AppColors.merchantAmber,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) => setState(() => isGlutenFree = v),
                    ),
                    const Divider(height: 32),
                    SwitchListTile(
                      title: Text('Available', style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
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
                  style: AppTypography.body.copyWith(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.trim().isEmpty || priceController.text.trim().isEmpty) return;
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.merchantIndigo,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  existingItem == null ? 'Add Item' : 'Save Changes',
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
        title: Text('Delete Item?', style: AppTypography.title),
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
    return AppScaffold(
      appBar: AppAppBar(
        titleText: widget.restaurantName,
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _menuType == 'image'
              ? _buildImageMenu()
              : _buildStructuredMenu(),
      floatingActionButton: _menuType == 'image'
          ? FloatingActionButton.extended(
              onPressed: _pickAndUploadMenuPhoto,
              backgroundColor: AppColors.merchantIndigo,
              icon: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white),
              label: const Text('Add Menu Image', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : FloatingActionButton.extended(
              onPressed: _addOrUpdateItem,
              backgroundColor: AppColors.merchantIndigo,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Add Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            Text(
              'No menu images yet',
              style: AppTypography.title,
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: Text(
                'Upload photos of your physical menu so customers can see your full offerings.',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
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
                child: CachedNetworkImage(
                  imageUrl: image.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (context, url) => Container(
                    color: AppColors.shimmer,
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.shimmer,
                    child: const Icon(Icons.error_outline, color: AppColors.error),
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

  Widget _buildCategorySelector() {
    return Container(
      height: 60,
      color: Colors.transparent,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        itemCount: _categories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                backgroundColor: AppColors.merchantIndigo.withValues(alpha: 0.1),
                label: const Icon(Icons.add, color: AppColors.merchantIndigo, size: 18),
                onPressed: _addCategory,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            );
          }

          final category = _categories[index - 1];
          final isSelected = _selectedCategoryId == category['id'];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(category['name']),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) _selectCategory(category['id']);
              },
              backgroundColor: AppColors.background,
              selectedColor: AppColors.merchantIndigo,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemsList() {
    if (_selectedCategoryData == null) return const Center(child: CircularProgressIndicator());
    
    final items = _selectedCategoryData!['items'] as List<dynamic>? ?? [];

    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _fetchCategoryItems(_selectedCategoryId!),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 400,
            child: EmptyStateWidget(
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
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 100),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length + 1,
        separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text(
                    _selectedCategoryData!['name'],
                    style: AppTypography.title.copyWith(fontSize: 20),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, color: AppColors.merchantBlue, size: 20),
                        onPressed: () => _editCategory(_selectedCategoryData!),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                        onPressed: () => _deleteCategory(_selectedCategoryId!),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
          
          final item = items[index - 1];
          final bool isAvailable = item['is_available'] ?? true;
          
          return AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item['name'] ?? 'Item',
                        style: AppTypography.title.copyWith(
                          fontSize: 17,
                          decoration: isAvailable ? null : TextDecoration.lineThrough,
                          color: isAvailable ? AppColors.textDarkest : AppColors.textDisabled,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '£${item['price']}',
                      style: AppTypography.title.copyWith(
                        color: isAvailable ? AppColors.merchantIndigo : AppColors.textDisabled,
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
                if (item['description'] != null && item['description'].toString().trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                    child: Text(
                      item['description'],
                      style: AppTypography.bodySmall.copyWith(
                        color: isAvailable ? AppColors.textSecondary : AppColors.textDisabled,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (item['is_vegetarian'] == true)
                            _buildTag('Veg', AppColors.success),
                          if (item['is_vegan'] == true)
                            _buildTag('Vegan', AppColors.success),
                          if (item['is_gluten_free'] == true)
                            _buildTag('GF', AppColors.merchantAmber),
                          if (!isAvailable)
                            _buildTag('Sold Out', AppColors.error),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, color: AppColors.merchantBlue, size: 20),
                          onPressed: () => _addOrUpdateItem(existingItem: item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                          onPressed: () => _deleteItem(item),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(color: color, fontWeight: FontWeight.w700, fontSize: 10),
      ),
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
      primaryActionLabel: _menuType == 'image' ? 'Upload photo' : 'Add category',
      onPrimaryAction: _menuType == 'image' ? _pickAndUploadMenuPhoto : _addCategory,
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
        content: Text('Are you sure you want to delete this menu image?', style: AppTypography.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
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
