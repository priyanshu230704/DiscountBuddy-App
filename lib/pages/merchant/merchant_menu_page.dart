import 'package:flutter/material.dart';
import 'package:discount_buddy/theme/app_colors.dart';
import 'package:discount_buddy/design/app_spacing.dart';
import 'package:discount_buddy/design/app_typography.dart';
import 'package:discount_buddy/components/layout.dart';
import 'package:discount_buddy/components/app_app_bar.dart';
import '../../services/merchant_service.dart';
import '../../widgets/skeleton_loader.dart';

import 'merchant_category_items_page.dart';

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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    setState(() => _isLoading = true);
    try {
      final categories = await _merchantService.getMenuCategories(
        restaurantId: widget.restaurantId,
      );
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load menu: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _addCategory() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Menu Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name *'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              Navigator.pop(context, true);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _merchantService.createMenuCategory({
          'restaurant': widget.restaurantId,
          'name': nameController.text,
          'description': descriptionController.text,
          'order': _categories.length,
          'is_active': true,
        });
        _loadMenu();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add category: ${e.toString()}')),
          );
        }
      }
    }
  }

  Future<void> _addDefaultCategory() async {
    try {
      await _merchantService.createMenuCategory({
        'restaurant': widget.restaurantId,
        'name': 'Classic Burgers',
        'description': 'Our signature beef and chicken burgers',
        'order': _categories.length,
        'is_active': true,
      });
      _loadMenu();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Category "Classic Burgers" added successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add default category: ${e.toString()}'),
          ),
        );
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
        title: const Text('Edit Menu Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name *'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              Navigator.pop(context, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _merchantService.updateMenuCategory(category['id'], {
          'name': nameController.text,
          'description': descriptionController.text,
        });
        _loadMenu();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update category: ${e.toString()}'),
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
        title: const Text('Delete Category'),
        content: const Text('Are you sure you want to delete this category?'),
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

    if (confirm == true) {
      try {
        await _merchantService.deleteMenuCategory(id);
        _loadMenu();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppAppBar(
        titleText: 'Menu: ${widget.restaurantName}',
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.add),
            onSelected: (value) {
              if (value == 'add') {
                _addCategory();
              } else if (value == 'default') {
                _addDefaultCategory();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'add', child: Text('Add Category')),
              PopupMenuItem(
                value: 'default',
                child: Text('Quick Add Default'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _categories.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadMenu,
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppSpacing.xl,
                      left: 4,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Manage Menu Categories',
                          style: AppTypography.headline.copyWith(fontSize: 22),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap a category to organize or add food items',
                          style: AppTypography.subtitle,
                        ),
                      ],
                    ),
                  ),
                  ..._categories.map(
                    (category) => _CategoryCard(
                      category: category,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MerchantCategoryItemsPage(
                              categoryId: category['id'],
                              categoryName: category['name'],
                            ),
                          ),
                        ).then((_) => _loadMenu());
                      },
                      onEdit: () => _editCategory(category),
                      onDelete: () => _deleteCategory(category['id']),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: SkeletonLoader(
          height: 80,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return EmptyStateWidget(
      icon: Icons.menu_book,
      title: 'No menu categories yet',
      message: 'Organise your dishes into categories to make browsing easier.',
      primaryActionLabel: 'Add category',
      onPrimaryAction: _addCategory,
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Map<String, dynamic> category;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryCard({
    required this.category,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category['name'] ?? 'Category',
                  style: AppTypography.title.copyWith(fontSize: 16),
                ),
                if (category['description'] != null &&
                    category['description'].isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      category['description'],
                      style: AppTypography.bodySmall,
                    ),
                  ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${category['items_count'] ?? 0} items',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.grey),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
