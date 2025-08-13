// lib/services/dummy_data_service.dart
import 'package:flutter/material.dart';
import 'package:fitsyncgemini/constants/dummy_data.dart';
import 'package:fitsyncgemini/services/MLAPI_service.dart';
import 'package:fitsyncgemini/services/auth_service.dart';
import 'dart:io';

class DummyDataService {
  final AuthService _authService;

  DummyDataService(this._authService);

  /// Inject all dummy data for the current user
  Future<void> injectDummyData() async {
    try {
      final userId = _authService.getCurrentUserId();
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      // Inject clothing items
      await _injectClothingItems(userId);

      // Inject outfits
      await _injectOutfits(userId);

      // Inject style posts
      await _injectStylePosts();

      // Inject explore items
      await _injectExploreItems();

      debugPrint('✅ Dummy data injected successfully for user: $userId');
    } catch (e) {
      debugPrint('❌ Error injecting dummy data: $e');
      rethrow;
    }
  }

  /// Inject clothing items into the backend
  Future<void> _injectClothingItems(String userId) async {
    for (final item in DummyData.clothingItems) {
      try {
        // Map category names to backend enum values
        final category = _mapCategoryToEnum(item.category);
        final subcategory = _mapSubcategoryToEnum(item.subCategory);
        
        // Use the new create endpoint that doesn't require file upload
        await MLAPIService.createClothingItem(
          name: item.name,
          category: category,
          subcategory: subcategory,
          color: item.colors.first.toLowerCase(),
          colorHex: _getColorHex(item.colors.first),
          brand: item.brand,
          price: item.price,
          imageUrl: item.image,
          seasons: ['all_season'],
          occasions: ['casual'],
          styleTags: [item.category, item.subCategory],
        );

        debugPrint('✅ Created clothing item: ${item.name}');
      } catch (e) {
        debugPrint('❌ Failed to create clothing item ${item.name}: $e');
      }
    }
    debugPrint(
      '✅ Attempted to inject ${DummyData.clothingItems.length} clothing items',
    );
  }

  /// Map frontend category names to backend enum values
  String _mapCategoryToEnum(String category) {
    switch (category.toLowerCase()) {
      case 'tops':
        return 'tops';
      case 'bottoms':
        return 'bottoms';
      case 'dresses':
        return 'dresses';
      case 'outerwear':
        return 'outerwear';
      case 'shoes':
        return 'shoes';
      case 'accessories':
        return 'accessories';
      case 'underwear':
        return 'underwear';
      case 'swimwear':
        return 'swimwear';
      case 'activewear':
        return 'activewear';
      case 'formalwear':
        return 'formalwear';
      default:
        return 'tops'; // Default fallback
    }
  }

  /// Map frontend subcategory names to backend enum values
  String _mapSubcategoryToEnum(String subcategory) {
    switch (subcategory.toLowerCase()) {
      case 't-shirts':
      case 't_shirts':
        return 't_shirts';
      case 'shirts':
        return 'shirts';
      case 'blouses':
        return 'blouses';
      case 'sweaters':
        return 'sweaters';
      case 'hoodies':
        return 'hoodies';
      case 'tank tops':
      case 'tank_tops':
        return 'tank_tops';
      case 'jeans':
        return 'jeans';
      case 'pants':
        return 'pants';
      case 'shorts':
        return 'shorts';
      case 'skirts':
        return 'skirts';
      case 'leggings':
        return 'leggings';
      case 'casual dresses':
      case 'casual_dresses':
        return 'casual_dresses';
      case 'formal dresses':
      case 'formal_dresses':
        return 'formal_dresses';
      case 'maxi dresses':
      case 'maxi_dresses':
        return 'maxi_dresses';
      case 'mini dresses':
      case 'mini_dresses':
        return 'mini_dresses';
      case 'jackets':
        return 'jackets';
      case 'coats':
        return 'coats';
      case 'blazers':
        return 'blazers';
      case 'cardigans':
        return 'cardigans';
      case 'sneakers':
        return 'sneakers';
      case 'boots':
        return 'boots';
      case 'heels':
        return 'heels';
      case 'flats':
        return 'flats';
      case 'sandals':
        return 'sandals';
      case 'bags':
        return 'bags';
      case 'jewelry':
        return 'jewelry';
      case 'scarves':
        return 'scarves';
      case 'belts':
        return 'belts';
      case 'hats':
        return 'hats';
      default:
        return 't_shirts'; // Default fallback
    }
  }

  /// Get hex color code for color name
  String _getColorHex(String color) {
    switch (color.toLowerCase()) {
      case 'white':
        return '#FFFFFF';
      case 'black':
        return '#000000';
      case 'blue':
        return '#0000FF';
      case 'red':
        return '#FF0000';
      case 'green':
        return '#00FF00';
      case 'yellow':
        return '#FFFF00';
      case 'purple':
        return '#800080';
      case 'pink':
        return '#FFC0CB';
      case 'orange':
        return '#FFA500';
      case 'brown':
        return '#A52A2A';
      case 'gray':
      case 'grey':
        return '#808080';
      case 'beige':
        return '#F5F5DC';
      default:
        return '#000000'; // Default to black
    }
  }

  /// Inject outfits into the backend
  Future<void> _injectOutfits(String userId) async {
    // Note: Outfit endpoints are not yet implemented in MLAPIService
    // This is a placeholder for future implementation
    debugPrint('ℹ️ Outfit injection not yet implemented in API service');
  }

  /// Inject style posts into Firestore
  Future<void> _injectStylePosts() async {
    // Note: Style posts are currently not implemented in FirestoreService
    // This is a placeholder for future implementation
    debugPrint('ℹ️ Style posts injection not yet implemented');
  }

  /// Inject explore items into Firestore
  Future<void> _injectExploreItems() async {
    // Note: Explore items are currently not implemented in FirestoreService
    // This is a placeholder for future implementation
    debugPrint('ℹ️ Explore items injection not yet implemented');
  }

  /// Clear all dummy data for the current user
  Future<void> clearDummyData() async {
    try {
      final userId = _authService.getCurrentUserId();
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      // Note: Bulk deletion methods are not yet implemented in FirestoreService
      // This is a placeholder for future implementation
      debugPrint(
        'ℹ️ Bulk deletion not yet implemented - clear items individually',
      );
    } catch (e) {
      debugPrint('❌ Error clearing dummy data: $e');
      rethrow;
    }
  }

  /// Get dummy data statistics
  Map<String, dynamic> getDummyDataStats() {
    return {
      'clothing_items': DummyData.clothingItems.length,
      'outfits': DummyData.outfits.length,
      'style_posts': DummyData.stylePosts.length,
      'explore_items': DummyData.exploreItems.length,
      'categories': DummyData.categories.length,
      'trending_styles': DummyData.trendingStyles.length,
      'nearby_shops': DummyData.nearbyShops.length,
      'try_on_results': DummyData.tryOnResults.length,
    };
  }
}
