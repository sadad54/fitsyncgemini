import 'package:fitsyncgemini/services/MLAPI_service.dart';

class PersonalizationService {
  static Map<String, dynamic>? _stylePreferences;
  static String? _currentArchetype;

  /// Get user's style preferences from backend
  static Future<Map<String, dynamic>?> getStylePreferences() async {
    try {
      _stylePreferences = await MLAPIService.getStylePreferences();
      _currentArchetype = _stylePreferences?['style_archetype'];
      return _stylePreferences;
    } catch (e) {
      print('❌ Error getting style preferences: $e');
      return null;
    }
  }

  /// Get current style archetype
  static String getCurrentArchetype() {
    return _currentArchetype ?? 'minimalist';
  }

  /// Get personalized color palette for the user's archetype
  static List<String> getPersonalizedColors() {
    final archetype = getCurrentArchetype();
    final colorMappings = {
      'minimalist': ['#000000', '#FFFFFF', '#808080', '#F5F5F5', '#E0E0E0'],
      'classic': ['#000080', '#FFFFFF', '#000000', '#8B4513', '#C0C0C0'],
      'bohemian': ['#8B4513', '#228B22', '#FF4500', '#4B0082', '#D2691E'],
      'streetwear': ['#000000', '#FF0000', '#0000FF', '#FFFF00', '#FF69B4'],
      'elegant': ['#000000', '#FFFFFF', '#C0C0C0', '#800080', '#4169E1'],
      'romantic': ['#FFB6C1', '#DDA0DD', '#F0E68C', '#FF69B4', '#FFC0CB'],
      'natural': ['#228B22', '#8B4513', '#F4A460', '#DEB887', '#90EE90'],
      'dramatic': ['#FF0000', '#000000', '#FFD700', '#800080', '#FF4500'],
      'gamine': ['#000000', '#FFFFFF', '#FF69B4', '#00CED1', '#FF1493'],
      'creative': ['#FF4500', '#00CED1', '#FF69B4', '#32CD32', '#FF6347'],
    };
    return colorMappings[archetype] ?? colorMappings['minimalist']!;
  }

  /// Get personalized style recommendations
  static Map<String, dynamic> getStyleRecommendations() {
    final archetype = getCurrentArchetype();
    final recommendations = {
      'minimalist': {
        'focus': 'Clean lines and neutral colors',
        'tips': [
          'Invest in quality basics',
          'Stick to a neutral color palette',
          'Choose simple, structured silhouettes',
          'Minimize accessories',
        ],
        'avoid': [
          'Overly busy patterns',
          'Too many accessories',
          'Bright colors',
        ],
      },
      'classic': {
        'focus': 'Timeless elegance and sophistication',
        'tips': [
          'Choose well-tailored pieces',
          'Invest in quality fabrics',
          'Stick to traditional silhouettes',
          'Add subtle accessories',
        ],
        'avoid': ['Trendy pieces', 'Overly casual items', 'Bright colors'],
      },
      'bohemian': {
        'focus': 'Free-spirited and artistic expression',
        'tips': [
          'Mix textures and patterns',
          'Choose flowing silhouettes',
          'Add layered accessories',
          'Embrace earthy colors',
        ],
        'avoid': [
          'Structured pieces',
          'Minimal accessories',
          'Corporate looks',
        ],
      },
      'streetwear': {
        'focus': 'Urban culture and comfort',
        'tips': [
          'Choose comfortable, trendy pieces',
          'Mix high and low fashion',
          'Add statement accessories',
          'Embrace bold colors',
        ],
        'avoid': [
          'Overly formal pieces',
          'Minimal accessories',
          'Conservative looks',
        ],
      },
      'elegant': {
        'focus': 'Refined sophistication and polish',
        'tips': [
          'Choose high-quality fabrics',
          'Opt for sophisticated cuts',
          'Add refined accessories',
          'Stick to classic colors',
        ],
        'avoid': ['Casual pieces', 'Trendy items', 'Overly bold colors'],
      },
      'romantic': {
        'focus': 'Soft femininity and delicate details',
        'tips': [
          'Choose flowing silhouettes',
          'Add delicate accessories',
          'Embrace soft colors',
          'Include feminine details',
        ],
        'avoid': ['Harsh lines', 'Bold colors', 'Minimal accessories'],
      },
      'natural': {
        'focus': 'Comfort and earthiness',
        'tips': [
          'Choose comfortable fabrics',
          'Embrace natural colors',
          'Opt for relaxed fits',
          'Add organic accessories',
        ],
        'avoid': ['Structured pieces', 'Bright colors', 'Formal looks'],
      },
      'dramatic': {
        'focus': 'Bold statements and confidence',
        'tips': [
          'Choose statement pieces',
          'Embrace bold colors',
          'Add dramatic accessories',
          'Opt for strong silhouettes',
        ],
        'avoid': ['Subtle pieces', 'Neutral colors', 'Minimal accessories'],
      },
      'gamine': {
        'focus': 'Playful youthfulness and versatility',
        'tips': [
          'Mix classic and trendy pieces',
          'Add playful accessories',
          'Choose versatile items',
          'Embrace bright colors',
        ],
        'avoid': [
          'Overly formal pieces',
          'Minimal accessories',
          'Conservative looks',
        ],
      },
      'creative': {
        'focus': 'Individuality and artistic expression',
        'tips': [
          'Choose unique pieces',
          'Mix unexpected elements',
          'Add artistic accessories',
          'Embrace bold colors',
        ],
        'avoid': ['Basic pieces', 'Conservative looks', 'Minimal accessories'],
      },
    };
    return recommendations[archetype] ?? recommendations['minimalist']!;
  }

  /// Get personalized outfit suggestions based on archetype
  static List<Map<String, dynamic>> getPersonalizedOutfitSuggestions() {
    final archetype = getCurrentArchetype();
    final suggestions = {
      'minimalist': [
        {
          'name': 'Clean Minimalist Look',
          'description': 'A simple, elegant outfit with clean lines',
          'items': ['White T-Shirt', 'Black Pants', 'Minimalist Sneakers'],
          'colors': ['White', 'Black', 'Gray'],
        },
        {
          'name': 'Neutral Elegance',
          'description': 'Sophisticated neutral tones',
          'items': ['Beige Sweater', 'Gray Pants', 'White Sneakers'],
          'colors': ['Beige', 'Gray', 'White'],
        },
      ],
      'classic': [
        {
          'name': 'Timeless Classic',
          'description': 'A sophisticated, professional look',
          'items': ['White Button-Down', 'Navy Pants', 'Leather Loafers'],
          'colors': ['White', 'Navy', 'Brown'],
        },
        {
          'name': 'Elegant Professional',
          'description': 'Refined and polished appearance',
          'items': ['Blazer', 'Tailored Pants', 'Oxford Shoes'],
          'colors': ['Black', 'Gray', 'White'],
        },
      ],
      'bohemian': [
        {
          'name': 'Free Spirit',
          'description': 'Flowing, artistic pieces',
          'items': ['Maxi Dress', 'Layered Necklaces', 'Ankle Boots'],
          'colors': ['Earth Tones', 'Rust', 'Olive'],
        },
        {
          'name': 'Artistic Bohemian',
          'description': 'Eclectic and creative',
          'items': ['Flowy Blouse', 'Wide-Leg Pants', 'Statement Jewelry'],
          'colors': ['Purple', 'Orange', 'Green'],
        },
      ],
      'streetwear': [
        {
          'name': 'Urban Cool',
          'description': 'Trendy and comfortable',
          'items': ['Graphic Tee', 'Distressed Jeans', 'Sneakers'],
          'colors': ['Black', 'White', 'Red'],
        },
        {
          'name': 'Street Style',
          'description': 'Bold and confident',
          'items': ['Hoodie', 'Joggers', 'High-Top Sneakers'],
          'colors': ['Gray', 'Black', 'Bright Accents'],
        },
      ],
      'elegant': [
        {
          'name': 'Sophisticated Elegance',
          'description': 'Refined and polished',
          'items': ['Silk Blouse', 'Tailored Skirt', 'Heels'],
          'colors': ['Black', 'White', 'Silver'],
        },
        {
          'name': 'Luxury Minimalist',
          'description': 'High-quality, simple pieces',
          'items': ['Cashmere Sweater', 'Wool Pants', 'Leather Bag'],
          'colors': ['Cream', 'Gray', 'Black'],
        },
      ],
      'romantic': [
        {
          'name': 'Soft Romance',
          'description': 'Delicate and feminine',
          'items': ['Floral Dress', 'Delicate Jewelry', 'Strappy Sandals'],
          'colors': ['Pink', 'Lavender', 'Blush'],
        },
        {
          'name': 'Feminine Grace',
          'description': 'Flowing and elegant',
          'items': ['Ruffled Blouse', 'A-Line Skirt', 'Pearl Accessories'],
          'colors': ['Rose Gold', 'Pink', 'White'],
        },
      ],
      'natural': [
        {
          'name': 'Earth Mother',
          'description': 'Comfortable and natural',
          'items': ['Linen Dress', 'Natural Jewelry', 'Comfortable Shoes'],
          'colors': ['Brown', 'Green', 'Beige'],
        },
        {
          'name': 'Relaxed Natural',
          'description': 'Easy and comfortable',
          'items': ['Cotton Tee', 'Relaxed Jeans', 'Slip-On Shoes'],
          'colors': ['Olive', 'Brown', 'Cream'],
        },
      ],
      'dramatic': [
        {
          'name': 'Bold Statement',
          'description': 'Confident and eye-catching',
          'items': ['Statement Dress', 'Bold Jewelry', 'High Heels'],
          'colors': ['Red', 'Black', 'Gold'],
        },
        {
          'name': 'Power Dressing',
          'description': 'Strong and confident',
          'items': ['Structured Blazer', 'Skinny Pants', 'Statement Bag'],
          'colors': ['Black', 'Red', 'White'],
        },
      ],
      'gamine': [
        {
          'name': 'Playful Youth',
          'description': 'Fun and versatile',
          'items': ['Crop Top', 'High-Waisted Shorts', 'Sneakers'],
          'colors': ['Bright Colors', 'White', 'Black'],
        },
        {
          'name': 'Trendy Mix',
          'description': 'Classic meets trendy',
          'items': ['Blazer', 'Graphic Tee', 'Mom Jeans'],
          'colors': ['Blue', 'White', 'Black'],
        },
      ],
      'creative': [
        {
          'name': 'Artistic Expression',
          'description': 'Unique and individual',
          'items': ['Colorful Dress', 'Mixed Jewelry', 'Unique Shoes'],
          'colors': ['Mixed Colors', 'Bold Hues', 'Neon'],
        },
        {
          'name': 'Creative Mix',
          'description': 'Unexpected combinations',
          'items': ['Vintage Blouse', 'Modern Pants', 'Artistic Accessories'],
          'colors': [
            'Unexpected Combinations',
            'Bold Colors',
            'Mixed Patterns',
          ],
        },
      ],
    };
    return suggestions[archetype] ?? suggestions['minimalist']!;
  }

  /// Get personalized brand recommendations
  static List<String> getPersonalizedBrands() {
    final archetype = getCurrentArchetype();
    final brandMappings = {
      'minimalist': ['COS', 'Everlane', 'Uniqlo', 'Theory', 'Céline'],
      'classic': [
        'Ralph Lauren',
        'Brooks Brothers',
        'J.Crew',
        'Banana Republic',
        'Tommy Hilfiger',
      ],
      'bohemian': [
        'Free People',
        'Anthropologie',
        'Urban Outfitters',
        'Zara',
        'H&M',
      ],
      'streetwear': ['Nike', 'Adidas', 'Supreme', 'Off-White', 'Palace'],
      'elegant': ['Chanel', 'Dior', 'Gucci', 'Prada', 'Saint Laurent'],
      'romantic': [
        'Reformation',
        'For Love & Lemons',
        'Free People',
        'Urban Outfitters',
        'Zara',
      ],
      'natural': ['Patagonia', 'REI', 'L.L.Bean', 'The North Face', 'Columbia'],
      'dramatic': [
        'Balenciaga',
        'Vetements',
        'Off-White',
        'Givenchy',
        'Balmain',
      ],
      'gamine': ['Zara', 'H&M', 'Topshop', 'ASOS', 'Urban Outfitters'],
      'creative': [
        'Vintage',
        'Thrift Stores',
        'Local Designers',
        'Etsy',
        'Independent Brands',
      ],
    };
    return brandMappings[archetype] ?? brandMappings['minimalist']!;
  }

  /// Get personalized occasion preferences
  static Map<String, double> getPersonalizedOccasionPreferences() {
    final archetype = getCurrentArchetype();
    final occasionMappings = {
      'minimalist': {
        'casual': 0.8,
        'business': 0.7,
        'formal': 0.6,
        'party': 0.4,
      },
      'classic': {'business': 0.9, 'formal': 0.8, 'casual': 0.6, 'party': 0.5},
      'bohemian': {'casual': 0.9, 'party': 0.7, 'business': 0.3, 'formal': 0.2},
      'streetwear': {
        'casual': 0.9,
        'party': 0.8,
        'business': 0.2,
        'formal': 0.1,
      },
      'elegant': {'formal': 0.9, 'business': 0.8, 'party': 0.7, 'casual': 0.5},
      'romantic': {'party': 0.8, 'casual': 0.7, 'formal': 0.6, 'business': 0.4},
      'natural': {'casual': 0.9, 'business': 0.5, 'formal': 0.4, 'party': 0.6},
      'dramatic': {'party': 0.9, 'formal': 0.7, 'casual': 0.6, 'business': 0.5},
      'gamine': {'casual': 0.8, 'party': 0.7, 'business': 0.5, 'formal': 0.4},
      'creative': {'party': 0.8, 'casual': 0.7, 'business': 0.5, 'formal': 0.5},
    };
    return occasionMappings[archetype] ?? occasionMappings['minimalist']!;
  }

  /// Check if user has completed style preferences
  static bool hasStylePreferences() {
    return _stylePreferences != null && _currentArchetype != null;
  }

  /// Refresh style preferences from backend
  static Future<void> refreshStylePreferences() async {
    await getStylePreferences();
  }
}
