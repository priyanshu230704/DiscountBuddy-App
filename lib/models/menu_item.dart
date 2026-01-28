/// Menu Item model
class MenuItem {
  final int id;
  final String name;
  final String description;
  final String price;
  final bool isVegetarian;
  final bool isVegan;
  final bool isGlutenFree;
  final bool isAvailable;
  final String? imageUrl;
  final int order;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.isVegetarian,
    required this.isVegan,
    required this.isGlutenFree,
    required this.isAvailable,
    this.imageUrl,
    required this.order,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: json['price'] as String? ?? '0.00',
      isVegetarian: json['is_vegetarian'] as bool? ?? false,
      isVegan: json['is_vegan'] as bool? ?? false,
      isGlutenFree: json['is_gluten_free'] as bool? ?? false,
      isAvailable: json['is_available'] as bool? ?? true,
      imageUrl: json['image_url'] as String?,
      order: json['order'] as int? ?? 0,
    );
  }
}

/// Menu Category model
class MenuCategory {
  final int id;
  final String name;
  final String description;
  final int order;
  final bool isActive;
  final List<MenuItem> items;
  final int itemsCount;

  MenuCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.order,
    required this.isActive,
    required this.items,
    required this.itemsCount,
  });

  factory MenuCategory.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    return MenuCategory(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      order: json['order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      items: itemsJson
          .map((item) => MenuItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      itemsCount: json['items_count'] as int? ?? 0,
    );
  }
}
