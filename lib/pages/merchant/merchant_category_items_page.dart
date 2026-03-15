import 'package:discount_buddy/theme/app_colors.dart';

import 'package:discount_buddy/theme/app_fonts.dart';
import 'package:flutter/material.dart';
import '../../services/merchant_service.dart';

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
          SnackBar(content: Text('Failed to load category: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _addOrUpdateItem({Map<String, dynamic>? existingItem}) async {
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
            title: Text(existingItem == null ? 'Add Item' : 'Edit Item'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name *'),
                  ),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 2,
                  ),
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(labelText: 'Price *'),
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('Vegetarian'),
                    value: isVegetarian,
                    onChanged: (v) => setState(() => isVegetarian = v!),
                  ),
                  CheckboxListTile(
                    title: const Text('Vegan'),
                    value: isVegan,
                    onChanged: (v) => setState(() => isVegan = v!),
                  ),
                  CheckboxListTile(
                    title: const Text('Gluten Free'),
                    value: isGlutenFree,
                    onChanged: (v) => setState(() => isGlutenFree = v!),
                  ),
                  CheckboxListTile(
                    title: const Text('Available'),
                    value: isAvailable,
                    onChanged: (v) => setState(() => isAvailable = v!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.isEmpty ||
                      priceController.text.isEmpty) {
                    return;
                  }
                  Navigator.pop(context, {
                    if (existingItem != null && existingItem.containsKey('id'))
                      'id': existingItem['id'],
                    'name': nameController.text,
                    'description': descriptionController.text,
                    'price': priceController.text,
                    'is_vegetarian': isVegetarian,
                    'is_vegan': isVegan,
                    'is_gluten_free': isGlutenFree,
                    'is_available': isAvailable,
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
                child: Text(existingItem == null ? 'Add' : 'Save'),
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
        // Update existing item
        final int id = itemData['id'];
        await _merchantService.updateMenuItem(id, itemData);
      } else {
        // Add new item
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
          const SnackBar(content: Text('Item saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save item: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _addDefaultItem() async {
    final newItem = {
      'name': 'Cheeseburger Deluxe',
      'description':
          'Juicy beef patty with cheddar cheese, lettuce, tomato, and our secret sauce.',
      'price': '12.99',
      'is_vegetarian': false,
      'is_vegan': false,
      'is_gluten_free': false,
      'is_available': true,
      'order': 0,
    };
    await _saveItem(newItem, isEdit: false);
  }

  Future<void> _deleteItem(Map<String, dynamic> item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete ${item['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
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
            SnackBar(content: Text('Failed to delete item: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.categoryName,
          style: AppFonts.bodyStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'default') {
                _addDefaultItem();
              } else if (value == 'refresh') {
                _loadCategory();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'default',
                child: Text('Quick Add Default Item'),
              ),
              const PopupMenuItem(value: 'refresh', child: Text('Refresh')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrUpdateItem(),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _category == null
          ? const Center(child: Text('Failed to load category'))
          : _buildItemsList(),
    );
  }

  Widget _buildItemsList() {
    final items = _category!['items'] as List<dynamic>? ?? [];

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 64,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: 16),
            Text(
              'No items in this category',
              style: AppFonts.bodyStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Tap + to add items'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              item['name'] ?? 'Item',
              style: AppFonts.bodyStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item['description'] != null &&
                    item['description'].isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 4),
                    child: Text(item['description']),
                  ),
                Text(
                  '\$${item['price']}',
                  style: AppFonts.bodyStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children: [
                    if (item['is_vegetarian'] == true)
                      _buildTag('Veg', AppColors.success),
                    if (item['is_vegan'] == true)
                      _buildTag('Vegan', AppColors.success),
                    if (item['is_gluten_free'] == true)
                      _buildTag('GF', AppColors.discount),
                    if (item['is_available'] == false)
                      _buildTag('Unavailable', Colors.grey),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _addOrUpdateItem(existingItem: item),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteItem(item),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: AppFonts.bodyStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
