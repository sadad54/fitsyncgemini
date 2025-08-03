// lib/models/clothing_item.dart
class ClothingItem {
  final String id;
  final String name;
  final String category;
  final String subCategory;
  final String image;
  final List<String> colors;
  final String? brand;
  final double? price;
  final String? purchaseLocation;
  final DateTime? purchaseDate;
  final List<String> tags;
  final double? mlConfidence;
  final Map<String, dynamic> mlAnalysis;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ClothingItem({
    required this.id,
    required this.name,
    required this.category,
    required this.subCategory,
    required this.image,
    required this.colors,
    this.brand,
    this.price,
    this.purchaseLocation,
    this.purchaseDate,
    this.tags = const [],
    this.mlConfidence,
    this.mlAnalysis = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'subCategory': subCategory,
      'image': image,
      'colors': colors,
      'brand': brand,
      'price': price,
      'purchaseLocation': purchaseLocation,
      'purchaseDate': purchaseDate?.toIso8601String(),
      'tags': tags,
      'mlConfidence': mlConfidence,
      'mlAnalysis': mlAnalysis,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ClothingItem.fromMap(Map<String, dynamic> map, String id) {
    return ClothingItem(
      id: id,
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      subCategory: map['subCategory'] ?? '',
      image: map['image'] ?? '',
      colors: List<String>.from(map['colors'] ?? []),
      brand: map['brand'],
      price: map['price']?.toDouble(),
      purchaseLocation: map['purchaseLocation'],
      purchaseDate:
          map['purchaseDate'] != null
              ? DateTime.parse(map['purchaseDate'])
              : null,
      tags: List<String>.from(map['tags'] ?? []),
      mlConfidence: map['mlConfidence']?.toDouble(),
      mlAnalysis: Map<String, dynamic>.from(map['mlAnalysis'] ?? {}),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  ClothingItem copyWith({
    String? name,
    String? category,
    String? subCategory,
    String? image,
    List<String>? colors,
    String? brand,
    double? price,
    String? purchaseLocation,
    DateTime? purchaseDate,
    List<String>? tags,
    double? mlConfidence,
    Map<String, dynamic>? mlAnalysis,
    DateTime? updatedAt,
  }) {
    return ClothingItem(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      image: image ?? this.image,
      colors: colors ?? this.colors,
      brand: brand ?? this.brand,
      price: price ?? this.price,
      purchaseLocation: purchaseLocation ?? this.purchaseLocation,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      tags: tags ?? this.tags,
      mlConfidence: mlConfidence ?? this.mlConfidence,
      mlAnalysis: mlAnalysis ?? this.mlAnalysis,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
