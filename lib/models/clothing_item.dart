// lib/models/clothing_item.dart
class ClothingItem {
  final String id;
  final String name;
  final String category;
  final String image;
  final List<String> colors;

  const ClothingItem({
    required this.id,
    required this.name,
    required this.category,
    required this.image,
    required this.colors,
  });
}
