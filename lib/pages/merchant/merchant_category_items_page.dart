import 'package:flutter/material.dart';
import 'package:discount_buddy/design/app_design.dart';
import 'package:discount_buddy/widgets/app_scaffold.dart';
import 'package:discount_buddy/widgets/app_gradient_button.dart';
import 'package:discount_buddy/components/app_app_bar.dart';
import 'package:discount_buddy/components/layout.dart';
import '../../services/merchant_service.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/skeleton_loader.dart';

class MerchantCategoryItemsPage extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const MerchantCategoryItemsPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<MerchantCategoryItemsPage> createState() =>
      _MerchantCategoryItemsPageState();
}

class _MerchantCategoryItemsPageState extends State<MerchantCategoryItemsPage> {
  final MerchantService _merchantService = MerchantService();
  Map<String, dynamic>? _category;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategory();
  }

  Future<void> _loadCategory() async {
    setState(() => _isLoading = true);
    try {
      final category = await _merchantService.getMenuCategoryDetails(
        widget.categoryId,
      );
      if (mounted) {
        setState(() {
          _category = category;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load category: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    Widget? prefix,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: AppTypography.body,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTypography.bodySmall,
          filled: true,
          fillColor: AppColors.background,
          prefixIcon: prefix,
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

  Future<void> _addOrUpdateItem({Map<String, dynamic>? existingItem}) async {
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
                      label: 'Price *',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefix: const Icon(Icons.attach_money_rounded, size: 20, color: AppColors.textSecondary),
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
    if (_category == null) return;

    try {
      if (isEdit) {
        final int id = itemData['id'];
        await _merchantService.updateMenuItem(id, itemData);
      } else {
        final newItemData = Map<String, dynamic>.from(itemData);
        newItemData['category'] = widget.categoryId;
        if (!newItemData.containsKey('order')) {
          newItemData['order'] = 0;
        }
        await _merchantService.createMenuItem(newItemData);
      }

      _loadCategory();
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

    if (confirm == true && _category != null) {
      try {
        if (item.containsKey('id')) {
          await _merchantService.deleteMenuItem(item['id']);
          _loadCategory();
        } else {
          throw Exception('Item ID not found');
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
        titleText: widget.categoryName,
        backgroundColor: Colors.transparent,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textPrimary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (value) {
              if (value == 'refresh') {
                _loadCategory();
              }
            },
            itemBuilder: (context) => [

              PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
                    const SizedBox(width: 8),
                    Text('Refresh List', style: AppTypography.body),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: AppGradientButton(
        onPressed: () => _addOrUpdateItem(),
        width: 140,
        height: 56,
        borderRadius: BorderRadius.circular(28),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Add Item', 
              style: AppTypography.body.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _category == null
          ? const Center(child: Text('Failed to load category'))
          : _buildItemsList(),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.xl),
      itemCount: 5,
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
    return const EmptyStateWidget(
      icon: Icons.fastfood_rounded,
      title: 'No items in this category',
      message: 'Tap the + button to add your first menu item.',
    );
  }

  Widget _buildItemsList() {
    final items = _category!['items'] as List<dynamic>? ?? [];

    if (items.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadCategory,
      color: AppColors.merchantIndigo,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, 100),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final item = items[index];
          final bool isAvailable = item['is_available'] ?? true;
          
          return AppCard(
            padding: const EdgeInsets.all(AppSpacing.xl),
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
                          fontSize: 18,
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
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                if (item['description'] != null && item['description'].toString().trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 12),
                    child: Text(
                      item['description'],
                      style: AppTypography.body.copyWith(
                        color: isAvailable ? AppColors.textSecondary : AppColors.textDisabled,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 12),
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
                          icon: const Icon(Icons.edit_rounded, color: AppColors.merchantBlue, size: 22),
                          onPressed: () => _addOrUpdateItem(existingItem: item),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 22),
                          onPressed: () => _deleteItem(item),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
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
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
