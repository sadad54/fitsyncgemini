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
        // Use the new create endpoint that doesn't require file upload
        await MLAPIService.createClothingItem(
          name: item.name,
          category: item.category.toLowerCase(),
          subcategory: item.subCategory.toLowerCase(),
          color: item.colors.first,
          colorHex: item.colors.first,
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
