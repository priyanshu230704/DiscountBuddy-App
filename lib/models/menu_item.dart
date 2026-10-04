import 'image_variants.dart';

/// Helper to safely parse a value to int
int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

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
  final ImageVariants image;
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
    required this.image,
    required this.order,
  });

  // Convenience getter for backward compatibility
  String? get imageUrl => image.urlFor(fullScreen: false);

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    final rawImage = json['image'] ?? json['image_url'];
    ImageVariants parsedImage;
    if (rawImage is Map<String, dynamic>) {
      parsedImage = ImageVariants.fromJson(rawImage);
    } else if (rawImage is String) {
      parsedImage = ImageVariants(medium: rawImage, large: rawImage);
    } else {
      parsedImage = const ImageVariants();
    }

    return MenuItem(
      id: _parseInt(json['id']) ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: json['price']?.toString() ?? '0.00',
      isVegetarian: json['is_vegetarian'] as bool? ?? false,
      isVegan: json['is_vegan'] as bool? ?? false,
      isGlutenFree: json['is_gluten_free'] as bool? ?? false,
      isAvailable: json['is_available'] as bool? ?? true,
      image: parsedImage,
      order: _parseInt(json['order']) ?? 0,
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
      id: _parseInt(json['id']) ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      order: _parseInt(json['order']) ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      items: itemsJson
          .map((item) => MenuItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      itemsCount: _parseInt(json['items_count']) ?? 0,
    );
  }
}
