import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Placeholder MLAPI Service - No backend dependencies
/// This service provides mock data for UI development and testing
class MLAPIService {
  static String? _authToken;

  static void setAuthToken(String token) {
    _authToken = token;
  }

  static String? get authToken => _authToken;

  // ---------- Auth Methods (Placeholder) ----------
  static Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    required String username,
    required String firstName,
    required String lastName,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    return {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'email': email,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'message': 'User registered successfully',
    };
  }

  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));

    final token = 'demo_token_${DateTime.now().millisecondsSinceEpoch}';
    setAuthToken(token);

    return {
      'access_token': token,
      'user_id': 'demo_user_${DateTime.now().millisecondsSinceEpoch}',
      'user': {
        'id': 'demo_user_${DateTime.now().millisecondsSinceEpoch}',
        'email': email,
        'username': email.split('@')[0],
        'first_name': 'John',
        'last_name': 'Doe',
      },
    };
  }

  static Future<Map<String, dynamic>> getCurrentUser() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    return {
      'id': 'demo_user_${DateTime.now().millisecondsSinceEpoch}',
      'email': 'demo@fitsync.com',
      'username': 'demo_user',
      'first_name': 'John',
      'last_name': 'Doe',
      'avatar':
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
      'hasCompletedOnboarding': true,
      'style_preferences': {
        'archetype': 'minimalist',
        'favorite_colors': ['black', 'white', 'navy', 'grey'],
        'preferred_styles': ['minimalist', 'casual', 'professional'],
      },
    };
  }

  static Future<void> logout() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));
    _authToken = null;
  }

  // ---------- Clothing Methods (Placeholder) ----------
  static Future<Map<String, dynamic>> uploadClothingItem({
    required File imageFile,
    required String name,
    required String category,
    required String subcategory,
    required String color,
    String? brand,
    String? size,
    double? price,
    String? season,
    String? occasion,
    List<String>? tags,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1500));

    return {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'category': category,
      'subcategory': subcategory,
      'color': color,
      'brand': brand,
      'size': size,
      'price': price,
      'season': season,
      'occasion': occasion,
      'tags': tags,
      'image_url':
          'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400',
      'uploaded_at': DateTime.now().toIso8601String(),
    };
  }

  static Future<Map<String, dynamic>> createClothingItem({
    required String name,
    required String category,
    required String subcategory,
    required String color,
    String? colorHex,
    String? pattern,
    String? material,
    String? brand,
    String? size,
    double? price,
    String? imageUrl,
    List<String>? seasons,
    List<String>? occasions,
    List<String>? styleTags,
    String? fitType,
    String? neckline,
    String? sleeveType,
    String? length,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    return {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'category': category,
      'subcategory': subcategory,
      'color': color,
      'color_hex': colorHex,
      'pattern': pattern,
      'material': material,
      'brand': brand,
      'size': size,
      'price': price,
      'image_url':
          imageUrl ??
          'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400',
      'seasons': seasons,
      'occasions': occasions,
      'style_tags': styleTags,
      'fit_type': fitType,
      'neckline': neckline,
      'sleeve_type': sleeveType,
      'length': length,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  static Future<List<Map<String, dynamic>>> getUserWardrobe({
    String? category,
    String? color,
    String? season,
    int limit = 20,
    int offset = 0,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Generate mock wardrobe items
    final List<Map<String, dynamic>> items = [];
    final categories = [
      'tops',
      'bottoms',
      'dresses',
      'outerwear',
      'shoes',
      'accessories',
    ];
    final colors = ['black', 'white', 'navy', 'grey', 'beige', 'brown'];
    final brands = ['Nike', 'Adidas', 'Zara', 'H&M', 'Uniqlo', 'Levi\'s'];

    for (int i = 0; i < limit; i++) {
      final itemCategory = category ?? categories[i % categories.length];
      final itemColor = color ?? colors[i % colors.length];

      items.add({
        'id': 'item_${DateTime.now().millisecondsSinceEpoch}_$i',
        'name': '${itemCategory.capitalize()} ${i + 1}',
        'category': itemCategory,
        'subcategory': 'casual',
        'color': itemColor,
        'brand': brands[i % brands.length],
        'size': 'M',
        'price': (50 + (i * 10)).toDouble(),
        'image_url':
            'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400',
        'created_at':
            DateTime.now().subtract(Duration(days: i)).toIso8601String(),
      });
    }

    return items;
  }

  static Future<Map<String, dynamic>> getWardrobeStats() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    return {
      'total_items': 47,
      'total_value': 2500.0,
      'recently_added': 3,
      'categories': {
        'tops': 15,
        'bottoms': 12,
        'dresses': 8,
        'outerwear': 6,
        'shoes': 4,
        'accessories': 2,
      },
      'colors': {
        'black': 12,
        'white': 10,
        'navy': 8,
        'grey': 7,
        'beige': 5,
        'brown': 3,
        'other': 2,
      },
    };
  }

  // ---------- ML / Analyze Methods (Placeholder) ----------
  static Future<Map<String, dynamic>> analyzeClothingImage(
    File imageFile,
  ) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 2000));

    return {
      'category': 'tops',
      'subcategory': 't-shirt',
      'color': 'white',
      'color_hex': '#FFFFFF',
      'pattern': 'solid',
      'material': 'cotton',
      'brand': 'Unknown',
      'confidence': 0.95,
      'tags': ['casual', 'basic', 'versatile'],
    };
  }

  static Future<Map<String, dynamic>> estimateBodyPose(File imageFile) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1500));

    return {
      'pose_keypoints': [
        {'x': 100, 'y': 200, 'confidence': 0.9},
        {'x': 120, 'y': 180, 'confidence': 0.85},
        // ... more keypoints
      ],
      'body_measurements': {
        'height': 175,
        'shoulder_width': 45,
        'chest': 95,
        'waist': 80,
        'hips': 95,
      },
      'confidence': 0.88,
    };
  }

  static Future<Map<String, dynamic>> generateVirtualTryOn(
    File personImage,
    File clothingImage,
  ) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 3000));

    return {
      'result_image_url':
          'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400',
      'confidence': 0.92,
      'fit_score': 0.85,
      'processing_time': 2.5,
    };
  }

  // ---------- Quiz and Style Preferences (Placeholder) ----------
  static Future<Map<String, dynamic>> completeQuiz(
    Map<String, dynamic> quizAnswers,
  ) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1000));

    return {
      'archetype': 'minimalist',
      'style_preferences': {
        'favorite_colors': ['black', 'white', 'navy'],
        'preferred_styles': ['minimalist', 'casual'],
        'fit_preference': 'relaxed',
        'occasion_preferences': ['casual', 'work'],
      },
      'recommendations': [
        'Focus on neutral colors',
        'Invest in quality basics',
        'Keep silhouettes clean and simple',
      ],
    };
  }

  static Future<Map<String, dynamic>> getStylePreferences() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    return {
      'archetype': 'minimalist',
      'favorite_colors': ['black', 'white', 'navy', 'grey'],
      'preferred_styles': ['minimalist', 'casual', 'professional'],
      'fit_preference': 'relaxed',
      'occasion_preferences': ['casual', 'work', 'weekend'],
      'brand_preferences': ['Uniqlo', 'COS', 'Everlane'],
    };
  }

  // ---------- Recommendations (Placeholder) ----------
  static Future<Map<String, dynamic>> getRecommendations({
    Map<String, dynamic>? context,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    return {
      'outfits': [
        {
          'id': 'outfit_1',
          'name': 'Minimalist Office Look',
          'items': [
            {'id': 'item_1', 'name': 'White T-Shirt', 'category': 'tops'},
            {'id': 'item_2', 'name': 'Black Pants', 'category': 'bottoms'},
            {'id': 'item_3', 'name': 'Navy Blazer', 'category': 'outerwear'},
          ],
          'confidence': 0.95,
          'occasion': 'work',
        },
        {
          'id': 'outfit_2',
          'name': 'Casual Weekend',
          'items': [
            {'id': 'item_4', 'name': 'Grey Sweatshirt', 'category': 'tops'},
            {'id': 'item_5', 'name': 'Black Jeans', 'category': 'bottoms'},
            {'id': 'item_6', 'name': 'White Sneakers', 'category': 'shoes'},
          ],
          'confidence': 0.88,
          'occasion': 'casual',
        },
      ],
      'context': context,
    };
  }

  // ---------- Model Status (Placeholder) ----------
  static Future<Map<String, dynamic>> getModelStatus() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));

    return {
      'clothing_detection': 'ready',
      'pose_estimation': 'ready',
      'virtual_tryon': 'ready',
      'style_analysis': 'ready',
      'recommendations': 'ready',
      'last_updated': DateTime.now().toIso8601String(),
    };
  }

  // ---------- Health Check (Placeholder) ----------
  static Future<Map<String, dynamic>> healthCheck() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));

    return {
      'status': 'healthy',
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0.0',
      'services': {
        'auth': 'healthy',
        'clothing': 'healthy',
        'ml': 'healthy',
        'recommendations': 'healthy',
      },
    };
  }

  // ---------- Explore Methods (Placeholder) ----------
  static Future<List<String>> getCategories() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return ['All', 'Minimalist', 'Streetwear', 'Boho', 'Preppy', 'Grunge'];
  }

  static Future<Map<String, dynamic>> getTrendingStyles({
    int limit = 10,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    return {
      'trending_styles': [
        {'name': 'Minimalist', 'growth': '+23%', 'posts': 1247},
        {'name': 'Streetwear', 'growth': '+18%', 'posts': 892},
        {'name': 'Boho', 'growth': '+12%', 'posts': 567},
        {'name': 'Preppy', 'growth': '+8%', 'posts': 445},
      ],
    };
  }

  static Future<Map<String, dynamic>> getExploreItems({
    String? category,
    bool? trending,
    int limit = 20,
    int offset = 0,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    return {
      'items': List.generate(
        limit,
        (index) => {
          'id': 'explore_item_$index',
          'title': 'Style Inspiration ${index + 1}',
          'author': 'Style Creator ${index + 1}',
          'likes': 100 + (index * 10),
          'views': 500 + (index * 50),
          'image':
              'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400',
          'trending': trending ?? (index < 5),
        },
      ),
      'total': 100,
      'has_more': offset + limit < 100,
    };
  }

  // ---------- Trends Methods (Placeholder) ----------
  static Future<Map<String, dynamic>> getTrendingNow({
    String scope = 'global',
    String timeframe = 'week',
    int limit = 10,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    return {
      'trending_items': List.generate(
        limit,
        (index) => {
          'id': 'trend_$index',
          'name': 'Trending Item ${index + 1}',
          'growth': '+${15 + (index * 2)}%',
          'posts': 1000 + (index * 100),
          'category': ['Minimalist', 'Streetwear', 'Boho'][index % 3],
        },
      ),
      'scope': scope,
      'timeframe': timeframe,
    };
  }

  static Future<Map<String, dynamic>> getFashionInsights({
    String scope = 'global',
    String timeframe = 'week',
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    return {
      'insights': [
        'Minimalist styles are trending up 23% this week',
        'Neutral colors dominate the fashion scene',
        'Sustainable fashion continues to gain popularity',
        'Athleisure remains a strong category',
      ],
      'scope': scope,
      'timeframe': timeframe,
    };
  }

  static Future<Map<String, dynamic>> getInfluencerSpotlight({
    String scope = 'global',
    int limit = 10,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    return {
      'influencers': List.generate(
        limit,
        (index) => {
          'id': 'influencer_$index',
          'name': 'Style Influencer ${index + 1}',
          'followers': '${(10 + index) * 10}K',
          'posts': 100 + (index * 10),
          'style': ['Minimalist', 'Streetwear', 'Boho'][index % 3],
          'avatar':
              'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=150',
        },
      ),
      'scope': scope,
    };
  }

  // ---------- Nearby Methods (Placeholder) ----------
  static Future<Map<String, dynamic>> getNearbyPeople({
    required double lat,
    required double lng,
    double radiusKm = 5.0,
    int limit = 20,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    return {
      'people': List.generate(
        limit,
        (index) => {
          'id': 'person_$index',
          'name': 'Style Enthusiast ${index + 1}',
          'distance': (0.5 + (index * 0.2)).toStringAsFixed(1),
          'style': ['Minimalist', 'Streetwear', 'Boho'][index % 3],
          'avatar':
              'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=150',
        },
      ),
      'location': {'lat': lat, 'lng': lng},
      'radius_km': radiusKm,
    };
  }

  static Future<Map<String, dynamic>> getNearbyEvents({
    required double lat,
    required double lng,
    double radiusKm = 5.0,
    int limit = 20,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    return {
      'events': List.generate(
        limit,
        (index) => {
          'id': 'event_$index',
          'name': 'Fashion Event ${index + 1}',
          'distance': (1.0 + (index * 0.5)).toStringAsFixed(1),
          'date':
              DateTime.now().add(Duration(days: index + 1)).toIso8601String(),
          'type': ['Pop-up', 'Sale', 'Show'][index % 3],
        },
      ),
      'location': {'lat': lat, 'lng': lng},
      'radius_km': radiusKm,
    };
  }

  static Future<Map<String, dynamic>> getHotspots({
    required double lat,
    required double lng,
    double radiusKm = 5.0,
    int limit = 20,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    return {
      'hotspots': List.generate(
        limit,
        (index) => {
          'id': 'hotspot_$index',
          'name': 'Fashion Hotspot ${index + 1}',
          'distance': (0.8 + (index * 0.3)).toStringAsFixed(1),
          'type': ['Boutique', 'Mall', 'Street'][index % 3],
          'rating': 4.0 + (index * 0.1),
        },
      ),
      'location': {'lat': lat, 'lng': lng},
      'radius_km': radiusKm,
    };
  }

  static Future<Map<String, dynamic>> getNearbyMap({
    required double lat,
    required double lng,
    double radiusKm = 5.0,
    int limitPeople = 10,
    int limitEvents = 10,
    int limitHotspots = 10,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    return {
      'people': List.generate(
        limitPeople,
        (index) => {
          'id': 'person_$index',
          'name': 'Style Enthusiast ${index + 1}',
          'lat': lat + (index * 0.001),
          'lng': lng + (index * 0.001),
          'style': ['Minimalist', 'Streetwear', 'Boho'][index % 3],
        },
      ),
      'events': List.generate(
        limitEvents,
        (index) => {
          'id': 'event_$index',
          'name': 'Fashion Event ${index + 1}',
          'lat': lat + (index * 0.002),
          'lng': lng + (index * 0.002),
          'type': ['Pop-up', 'Sale', 'Show'][index % 3],
        },
      ),
      'hotspots': List.generate(
        limitHotspots,
        (index) => {
          'id': 'hotspot_$index',
          'name': 'Fashion Hotspot ${index + 1}',
          'lat': lat + (index * 0.003),
          'lng': lng + (index * 0.003),
          'type': ['Boutique', 'Mall', 'Street'][index % 3],
        },
      ),
      'location': {'lat': lat, 'lng': lng},
      'radius_km': radiusKm,
    };
  }

  // ---------- Virtual Try-On Methods (Placeholder) ----------
  static Future<Map<String, dynamic>> createTryOnSession({
    String? sessionName,
    String viewMode = 'ar',
    Map<String, dynamic>? deviceInfo,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    return {
      'session_id': 'session_${DateTime.now().millisecondsSinceEpoch}',
      'session_name': sessionName ?? 'Try-On Session',
      'view_mode': viewMode,
      'device_info': deviceInfo,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  static Future<Map<String, dynamic>> getTryOnDashboard() async {
    await Future.delayed(const Duration(milliseconds: 300));

    return {
      'total_sessions': 5,
      'recent_outfits': 12,
      'favorite_outfits': 8,
      'processing_queue': 2,
      'recent_activity': [
        {
          'type': 'outfit_created',
          'outfit_name': 'Office Look',
          'timestamp':
              DateTime.now().subtract(Duration(hours: 2)).toIso8601String(),
        },
        {
          'type': 'outfit_rated',
          'outfit_name': 'Weekend Casual',
          'rating': 5,
          'timestamp':
              DateTime.now().subtract(Duration(hours: 4)).toIso8601String(),
        },
      ],
    };
  }

  static Future<Map<String, dynamic>> getTryOnPreferences() async {
    await Future.delayed(const Duration(milliseconds: 200));

    return {
      'default_view_mode': 'ar',
      'auto_save_results': true,
      'share_anonymously': false,
      'enabled_features': {
        'body_measurements': true,
        'fit_prediction': true,
        'style_recommendations': true,
      },
      'processing_quality': 'high',
      'max_processing_time': 30,
      'store_images': true,
      'allow_analytics': true,
    };
  }

  static Future<Map<String, dynamic>> updateTryOnPreferences({
    String? defaultViewMode,
    bool? autoSaveResults,
    bool? shareAnonymously,
    Map<String, bool>? enabledFeatures,
    String? processingQuality,
    int? maxProcessingTime,
    bool? storeImages,
    bool? allowAnalytics,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    return {
      'message': 'Preferences updated successfully',
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  static Future<List<Map<String, dynamic>>> getTryOnFeatures() async {
    await Future.delayed(const Duration(milliseconds: 300));

    return [
      {
        'id': 'body_measurements',
        'name': 'Body Measurements',
        'description': 'Get accurate body measurements from photos',
        'enabled': true,
      },
      {
        'id': 'fit_prediction',
        'name': 'Fit Prediction',
        'description': 'Predict how clothes will fit on your body',
        'enabled': true,
      },
      {
        'id': 'style_recommendations',
        'name': 'Style Recommendations',
        'description': 'Get personalized style suggestions',
        'enabled': true,
      },
    ];
  }

  static Future<List<Map<String, dynamic>>> getTryOnSuggestions({
    int limit = 3,
    String? occasion,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final List<Map<String, dynamic>> suggestions = [];
    for (int i = 0; i < limit; i++) {
      suggestions.add({
        'id': 'suggestion_$i',
        'name': '${occasion ?? 'Casual'} Outfit ${i + 1}',
        'occasion': occasion ?? 'casual',
        'items': [
          {'id': 'item_1', 'name': 'White T-Shirt', 'category': 'tops'},
          {'id': 'item_2', 'name': 'Black Pants', 'category': 'bottoms'},
          {'id': 'item_3', 'name': 'Navy Blazer', 'category': 'outerwear'},
        ],
        'confidence': 0.9 - (i * 0.1),
      });
    }
    return suggestions;
  }

  static Future<Map<String, dynamic>> addOutfitToSession({
    required String sessionId,
    required String outfitName,
    String? occasion,
    required List<Map<String, dynamic>> clothingItems,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    return {
      'outfit_id': 'outfit_${DateTime.now().millisecondsSinceEpoch}',
      'session_id': sessionId,
      'outfit_name': outfitName,
      'occasion': occasion,
      'clothing_items': clothingItems,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  static Future<Map<String, dynamic>> processOutfitTryOn({
    required String sessionId,
    required String attemptId,
    List<int>? imageBytes,
  }) async {
    await Future.delayed(const Duration(milliseconds: 3000));

    return {
      'attempt_id': attemptId,
      'session_id': sessionId,
      'status': 'completed',
      'result_image_url':
          'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400',
      'confidence': 0.92,
      'fit_score': 0.85,
      'processing_time': 2.5,
      'completed_at': DateTime.now().toIso8601String(),
    };
  }

  static Future<Map<String, dynamic>> getTryOnProcessingStatus({
    required String sessionId,
    required String attemptId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));

    return {
      'attempt_id': attemptId,
      'session_id': sessionId,
      'status': 'completed',
      'progress': 100,
      'estimated_completion': DateTime.now().toIso8601String(),
    };
  }

  static Future<Map<String, dynamic>> rateOutfitAttempt({
    required String sessionId,
    required String attemptId,
    required int rating,
    bool isFavorite = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    return {
      'message': 'Rating saved successfully',
      'attempt_id': attemptId,
      'session_id': sessionId,
      'rating': rating,
      'is_favorite': isFavorite,
      'rated_at': DateTime.now().toIso8601String(),
    };
  }

  static Future<Map<String, dynamic>> shareTryOnSession({
    required String sessionId,
    Map<String, dynamic>? shareOptions,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    return {
      'message': 'Session shared successfully',
      'session_id': sessionId,
      'share_url': 'https://fitsync.com/share/$sessionId',
      'shared_at': DateTime.now().toIso8601String(),
    };
  }
}

// Extension for string capitalization
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

// Riverpod provider
final mlApiServiceProvider = Provider((ref) => MLAPIService());
