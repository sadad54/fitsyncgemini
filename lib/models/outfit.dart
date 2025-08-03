// lib/models/outfit.dart
class Outfit {
  final String id;
  final String name;
  final String occasion;
  final List<String> itemIds; // References to clothing items
  final String? imageUrl; // Generated outfit image
  final double? aiScore; // AI-generated compatibility score
  final Map<String, dynamic> styleAnalysis;
  final List<String> tags;
  final bool isFavorite;
  final int wearCount;
  final DateTime? lastWorn;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Outfit({
    required this.id,
    required this.name,
    required this.occasion,
    required this.itemIds,
    this.imageUrl,
    this.aiScore,
    this.styleAnalysis = const {},
    this.tags = const [],
    this.isFavorite = false,
    this.wearCount = 0,
    this.lastWorn,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'occasion': occasion,
      'itemIds': itemIds,
      'imageUrl': imageUrl,
      'aiScore': aiScore,
      'styleAnalysis': styleAnalysis,
      'tags': tags,
      'isFavorite': isFavorite,
      'wearCount': wearCount,
      'lastWorn': lastWorn?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Outfit.fromMap(Map<String, dynamic> map, String id) {
    return Outfit(
      id: id,
      name: map['name'] ?? '',
      occasion: map['occasion'] ?? '',
      itemIds: List<String>.from(map['itemIds'] ?? []),
      imageUrl: map['imageUrl'],
      aiScore: map['aiScore']?.toDouble(),
      styleAnalysis: Map<String, dynamic>.from(map['styleAnalysis'] ?? {}),
      tags: List<String>.from(map['tags'] ?? []),
      isFavorite: map['isFavorite'] ?? false,
      wearCount: map['wearCount'] ?? 0,
      lastWorn:
          map['lastWorn'] != null ? DateTime.parse(map['lastWorn']) : null,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Outfit copyWith({
    String? name,
    String? occasion,
    List<String>? itemIds,
    String? imageUrl,
    double? aiScore,
    Map<String, dynamic>? styleAnalysis,
    List<String>? tags,
    bool? isFavorite,
    int? wearCount,
    DateTime? lastWorn,
    DateTime? updatedAt,
  }) {
    return Outfit(
      id: id,
      name: name ?? this.name,
      occasion: occasion ?? this.occasion,
      itemIds: itemIds ?? this.itemIds,
      imageUrl: imageUrl ?? this.imageUrl,
      aiScore: aiScore ?? this.aiScore,
      styleAnalysis: styleAnalysis ?? this.styleAnalysis,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      wearCount: wearCount ?? this.wearCount,
      lastWorn: lastWorn ?? this.lastWorn,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
