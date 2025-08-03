// lib/models/outfit.dart
import 'package:fitsyncgemini/models/clothing_item.dart';

class Outfit {
  final String id;
  final String name;
  final List<ClothingItem> items;
  final String occasion;

  const Outfit({
    required this.id,
    required this.name,
    required this.items,
    required this.occasion,
  });
}
