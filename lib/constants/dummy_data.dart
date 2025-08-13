// lib/constants/dummy_data.dart
import 'package:fitsyncgemini/models/clothing_item.dart';
import 'package:fitsyncgemini/models/outfit.dart';
import 'package:fitsyncgemini/models/user_profile.dart';
import 'package:fitsyncgemini/models/category.dart';
import 'package:fitsyncgemini/models/style_post.dart';
import 'package:fitsyncgemini/models/explore_item.dart';

class DummyData {
  // ===== USER PROFILE =====
  static final UserProfile currentUser = UserProfile(
    id: '1',
    firstName: 'Alex',
    lastName: 'Johnson',
    email: 'alex.johnson@example.com',
    profileImageUrl:
        'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400&h=400&fit=crop&crop=face',
    styleArchetype: 'Minimalist',
    quizResults: {
      'style_preference': 'minimalist',
      'color_preference': 'neutral',
      'comfort_level': 'high',
      'budget_range': 'mid',
      'occasion_focus': 'casual',
    },
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
    updatedAt: DateTime.now(),
  );

  // ===== CLOTHING ITEMS =====
  static final List<ClothingItem> clothingItems = [
    // Tops
    ClothingItem(
      id: '1',
      name: 'White Cotton T-Shirt',
      category: 'Tops',
      subCategory: 'T-Shirts',
      image:
          'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400&h=500&fit=crop',
      colors: ['White'],
      brand: 'Uniqlo',
      price: 29.99,
      purchaseLocation: 'Uniqlo Store',
      purchaseDate: DateTime.now().subtract(const Duration(days: 45)),
      tags: ['basic', 'casual', 'versatile'],
      mlConfidence: 0.95,
      mlAnalysis: {
        'style': 'minimalist',
        'fit': 'regular',
        'material': 'cotton',
      },
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
      updatedAt: DateTime.now().subtract(const Duration(days: 45)),
    ),
    ClothingItem(
      id: '2',
      name: 'Blue Denim Shirt',
      category: 'Tops',
      subCategory: 'Shirts',
      image:
          'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=400&h=500&fit=crop',
      colors: ['Blue'],
      brand: 'Levi\'s',
      price: 89.99,
      purchaseLocation: 'Levi\'s Store',
      purchaseDate: DateTime.now().subtract(const Duration(days: 30)),
      tags: ['denim', 'casual', 'versatile'],
      mlConfidence: 0.92,
      mlAnalysis: {'style': 'casual', 'fit': 'regular', 'material': 'denim'},
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    ClothingItem(
      id: '3',
      name: 'Black Sweater',
      category: 'Tops',
      subCategory: 'Sweaters',
      image:
          'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=400&h=500&fit=crop',
      colors: ['Black'],
      brand: 'H&M',
      price: 49.99,
      purchaseLocation: 'H&M Online',
      purchaseDate: DateTime.now().subtract(const Duration(days: 60)),
      tags: ['warm', 'casual', 'versatile'],
      mlConfidence: 0.88,
      mlAnalysis: {'style': 'minimalist', 'fit': 'regular', 'material': 'wool'},
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      updatedAt: DateTime.now().subtract(const Duration(days: 60)),
    ),
    ClothingItem(
      id: '4',
      name: 'White Blouse',
      category: 'Tops',
      subCategory: 'Blouses',
      image:
          'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=400&h=500&fit=crop',
      colors: ['White'],
      brand: 'Zara',
      price: 69.99,
      purchaseLocation: 'Zara Store',
      purchaseDate: DateTime.now().subtract(const Duration(days: 20)),
      tags: ['elegant', 'formal', 'versatile'],
      mlConfidence: 0.94,
      mlAnalysis: {'style': 'elegant', 'fit': 'fitted', 'material': 'silk'},
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      updatedAt: DateTime.now().subtract(const Duration(days: 20)),
    ),

    // Bottoms
    ClothingItem(
      id: '5',
      name: 'Blue Denim Jeans',
      category: 'Bottoms',
      subCategory: 'Jeans',
      image:
          'https://images.unsplash.com/photo-1542272604-787c3835535d?w=400&h=500&fit=crop',
      colors: ['Blue'],
      brand: 'Levi\'s',
      price: 119.99,
      purchaseLocation: 'Levi\'s Store',
      purchaseDate: DateTime.now().subtract(const Duration(days: 90)),
      tags: ['denim', 'casual', 'versatile'],
      mlConfidence: 0.96,
      mlAnalysis: {'style': 'casual', 'fit': 'slim', 'material': 'denim'},
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
      updatedAt: DateTime.now().subtract(const Duration(days: 90)),
    ),
    ClothingItem(
      id: '6',
      name: 'Black Pants',
      category: 'Bottoms',
      subCategory: 'Pants',
      image:
          'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=400&h=500&fit=crop',
      colors: ['Black'],
      brand: 'H&M',
      price: 59.99,
      purchaseLocation: 'H&M Store',
      purchaseDate: DateTime.now().subtract(const Duration(days: 40)),
      tags: ['formal', 'versatile', 'elegant'],
      mlConfidence: 0.91,
      mlAnalysis: {'style': 'formal', 'fit': 'slim', 'material': 'polyester'},
      createdAt: DateTime.now().subtract(const Duration(days: 40)),
      updatedAt: DateTime.now().subtract(const Duration(days: 40)),
    ),
    ClothingItem(
      id: '7',
      name: 'Beige Shorts',
      category: 'Bottoms',
      subCategory: 'Shorts',
      image:
          'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=400&h=500&fit=crop',
      colors: ['Beige'],
      brand: 'Uniqlo',
      price: 39.99,
      purchaseLocation: 'Uniqlo Store',
      purchaseDate: DateTime.now().subtract(const Duration(days: 15)),
      tags: ['casual', 'summer', 'comfortable'],
      mlConfidence: 0.87,
      mlAnalysis: {'style': 'casual', 'fit': 'regular', 'material': 'cotton'},
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      updatedAt: DateTime.now().subtract(const Duration(days: 15)),
    ),

    // Dresses
    ClothingItem(
      id: '8',
      name: 'Black Dress',
      category: 'Dresses',
      subCategory: 'Casual Dresses',
      image:
          'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=400&h=500&fit=crop',
      colors: ['Black'],
      brand: 'Zara',
      price: 89.99,
      purchaseLocation: 'Zara Store',
      purchaseDate: DateTime.now().subtract(const Duration(days: 25)),
      tags: ['elegant', 'versatile', 'formal'],
      mlConfidence: 0.93,
      mlAnalysis: {
        'style': 'elegant',
        'fit': 'fitted',
        'material': 'polyester',
      },
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
      updatedAt: DateTime.now().subtract(const Duration(days: 25)),
    ),

    // Outerwear
    ClothingItem(
      id: '9',
      name: 'Denim Jacket',
      category: 'Outerwear',
      subCategory: 'Jackets',
      image:
          'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=400&h=500&fit=crop',
      colors: ['Blue'],
      brand: 'Levi\'s',
      price: 149.99,
      purchaseLocation: 'Levi\'s Store',
      purchaseDate: DateTime.now().subtract(const Duration(days: 70)),
      tags: ['denim', 'casual', 'versatile'],
      mlConfidence: 0.89,
      mlAnalysis: {'style': 'casual', 'fit': 'regular', 'material': 'denim'},
      createdAt: DateTime.now().subtract(const Duration(days: 70)),
      updatedAt: DateTime.now().subtract(const Duration(days: 70)),
    ),

    // Shoes
    ClothingItem(
      id: '10',
      name: 'White Sneakers',
      category: 'Shoes',
      subCategory: 'Sneakers',
      image:
          'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=400&h=500&fit=crop',
      colors: ['White'],
      brand: 'Nike',
      price: 129.99,
      purchaseLocation: 'Nike Store',
      purchaseDate: DateTime.now().subtract(const Duration(days: 50)),
      tags: ['casual', 'comfortable', 'versatile'],
      mlConfidence: 0.97,
      mlAnalysis: {'style': 'casual', 'fit': 'regular', 'material': 'leather'},
      createdAt: DateTime.now().subtract(const Duration(days: 50)),
      updatedAt: DateTime.now().subtract(const Duration(days: 50)),
    ),
    ClothingItem(
      id: '11',
      name: 'Black Heels',
      category: 'Shoes',
      subCategory: 'Heels',
      image:
          'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?w=400&h=500&fit=crop',
      colors: ['Black'],
      brand: 'Steve Madden',
      price: 89.99,
      purchaseLocation: 'Steve Madden Store',
      purchaseDate: DateTime.now().subtract(const Duration(days: 35)),
      tags: ['formal', 'elegant', 'versatile'],
      mlConfidence: 0.90,
      mlAnalysis: {'style': 'formal', 'fit': 'regular', 'material': 'leather'},
      createdAt: DateTime.now().subtract(const Duration(days: 35)),
      updatedAt: DateTime.now().subtract(const Duration(days: 35)),
    ),

    // Accessories
    ClothingItem(
      id: '12',
      name: 'Leather Bag',
      category: 'Accessories',
      subCategory: 'Bags',
      image:
          'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=400&h=500&fit=crop',
      colors: ['Brown'],
      brand: 'Coach',
      price: 299.99,
      purchaseLocation: 'Coach Store',
      purchaseDate: DateTime.now().subtract(const Duration(days: 100)),
      tags: ['elegant', 'versatile', 'quality'],
      mlConfidence: 0.94,
      mlAnalysis: {'style': 'elegant', 'fit': 'regular', 'material': 'leather'},
      createdAt: DateTime.now().subtract(const Duration(days: 100)),
      updatedAt: DateTime.now().subtract(const Duration(days: 100)),
    ),
  ];

  // ===== OUTFITS =====
  static final List<Outfit> outfits = [
    Outfit(
      id: '1',
      name: 'Casual Day Out',
      occasion: 'Casual',
      itemIds: ['1', '5', '10'],
      imageUrl:
          'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400&h=500&fit=crop',
      aiScore: 0.92,
      styleAnalysis: {
        'color_harmony': 0.9,
        'style_coherence': 0.85,
        'occasion_match': 0.95,
      },
      tags: ['casual', 'comfortable', 'versatile'],
      isFavorite: true,
      wearCount: 5,
      lastWorn: DateTime.now().subtract(const Duration(days: 2)),
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Outfit(
      id: '2',
      name: 'Office Professional',
      occasion: 'Business',
      itemIds: ['4', '6', '11'],
      imageUrl:
          'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=400&h=500&fit=crop',
      aiScore: 0.88,
      styleAnalysis: {
        'color_harmony': 0.85,
        'style_coherence': 0.9,
        'occasion_match': 0.92,
      },
      tags: ['formal', 'professional', 'elegant'],
      isFavorite: false,
      wearCount: 3,
      lastWorn: DateTime.now().subtract(const Duration(days: 5)),
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
      updatedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Outfit(
      id: '3',
      name: 'Weekend Casual',
      occasion: 'Casual',
      itemIds: ['2', '7', '10'],
      imageUrl:
          'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400&h=500&fit=crop',
      aiScore: 0.85,
      styleAnalysis: {
        'color_harmony': 0.8,
        'style_coherence': 0.88,
        'occasion_match': 0.9,
      },
      tags: ['casual', 'comfortable', 'relaxed'],
      isFavorite: true,
      wearCount: 2,
      lastWorn: DateTime.now().subtract(const Duration(days: 1)),
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  // ===== CATEGORIES =====
  static final List<Category> categories = [
    Category(id: '1', name: 'All', count: 12),
    Category(id: '2', name: 'Tops', count: 4),
    Category(id: '3', name: 'Bottoms', count: 3),
    Category(id: '4', name: 'Dresses', count: 1),
    Category(id: '5', name: 'Outerwear', count: 1),
    Category(id: '6', name: 'Shoes', count: 2),
    Category(id: '7', name: 'Accessories', count: 1),
  ];

  // ===== STYLE POSTS =====
  static final List<StylePost> stylePosts = [
    StylePost(
      id: '1',
      userId: '2',
      userName: 'Emma Chen',
      userAvatarUrl:
          'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=100&h=100&fit=crop&crop=face',
      imageUrl:
          'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400&h=500&fit=crop',
      caption: 'Minimalist Monday vibes ✨ Simple, clean, and timeless',
      likesCount: 1240,
      commentsCount: 89,
      tags: ['minimalist', 'casual', 'timeless'],
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    StylePost(
      id: '2',
      userId: '3',
      userName: 'Marcus Rodriguez',
      userAvatarUrl:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&h=100&fit=crop&crop=face',
      imageUrl:
          'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=400&h=500&fit=crop',
      caption: 'Sustainable fashion doesn\'t mean compromising on style 🌱',
      likesCount: 890,
      commentsCount: 67,
      tags: ['sustainable', 'eco-friendly', 'style'],
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];

  // ===== EXPLORE ITEMS =====
  static final List<ExploreItem> exploreItems = [
    ExploreItem(
      id: 1,
      title: 'Minimalist Wardrobe Essentials',
      author: 'Style Guide',
      authorAvatar:
          'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=50&h=50&fit=crop&crop=face',
      likes: 1240,
      views: 8900,
      tags: ['minimalist', 'wardrobe', 'essentials'],
      image:
          'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=300&h=400&fit=crop',
      trending: true,
    ),
    ExploreItem(
      id: 2,
      title: 'Sustainable Fashion Brands',
      author: 'Eco Style',
      authorAvatar:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=50&h=50&fit=crop&crop=face',
      likes: 890,
      views: 5600,
      tags: ['sustainable', 'eco-friendly', 'brands'],
      image:
          'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=300&h=400&fit=crop',
      trending: true,
    ),
    ExploreItem(
      id: 3,
      title: 'Capsule Wardrobe Challenge',
      author: 'Fashion Challenge',
      authorAvatar:
          'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=50&h=50&fit=crop&crop=face',
      likes: 2100,
      views: 12000,
      tags: ['capsule', 'wardrobe', 'challenge'],
      image:
          'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=300&h=400&fit=crop',
      trending: false,
    ),
  ];

  // ===== CLOSET STATS =====
  static final ClosetStats closetStats = ClosetStats(
    totalItems: 12,
    totalValue: 1299.89,
    recentlyAdded: 3,
    mostWornItem: 'White Cotton T-Shirt',
    categoryBreakdown: {
      'Tops': 4,
      'Bottoms': 3,
      'Dresses': 1,
      'Outerwear': 1,
      'Shoes': 2,
      'Accessories': 1,
    },
    colorBreakdown: {'White': 4, 'Blue': 3, 'Black': 3, 'Beige': 1, 'Brown': 1},
    brandBreakdown: {
      'Uniqlo': 3,
      'Levi\'s': 3,
      'H&M': 2,
      'Zara': 2,
      'Nike': 1,
      'Steve Madden': 1,
    },
  );

  // ===== TRENDING STYLES =====
  static final List<TrendingStyle> trendingStyles = [
    TrendingStyle(
      id: '1',
      title: 'Minimalist Aesthetic',
      growth: '+23%',
      trend: TrendDirection.up,
      description: 'Clean lines and neutral colors dominate social media',
      image:
          'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=300&h=400&fit=crop',
      tags: ['minimalist', 'neutral', 'clean'],
      engagement: 15420,
      posts: 2340,
    ),
    TrendingStyle(
      id: '2',
      title: 'Sustainable Fashion',
      growth: '+18%',
      trend: TrendDirection.up,
      description: 'Eco-friendly clothing choices on the rise',
      image:
          'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=300&h=400&fit=crop',
      tags: ['sustainable', 'eco-friendly', 'conscious'],
      engagement: 12890,
      posts: 1890,
    ),
    TrendingStyle(
      id: '3',
      title: 'Vintage Revival',
      growth: '+12%',
      trend: TrendDirection.up,
      description: 'Retro styles making a comeback',
      image:
          'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=300&h=400&fit=crop',
      tags: ['vintage', 'retro', 'nostalgic'],
      engagement: 9870,
      posts: 1450,
    ),
  ];

  // ===== NEARBY SHOPS =====
  static final List<NearbyShop> nearbyShops = [
    NearbyShop(
      id: '1',
      name: 'Uniqlo Store',
      category: 'Clothing',
      distance: 0.8,
      rating: 4.5,
      imageUrl:
          'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=300&h=200&fit=crop',
      address: '123 Fashion St, Downtown',
      isOpen: true,
      offers: ['20% off basics', 'Free shipping'],
    ),
    NearbyShop(
      id: '2',
      name: 'Levi\'s Store',
      category: 'Denim',
      distance: 1.2,
      rating: 4.3,
      imageUrl:
          'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=300&h=200&fit=crop',
      address: '456 Denim Ave, Fashion District',
      isOpen: true,
      offers: ['Buy 2 get 1 free', 'Student discount'],
    ),
  ];

  // ===== TRY-ON RESULTS =====
  static final List<TryOnResult> tryOnResults = [
    TryOnResult(
      id: '1',
      originalImage:
          'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=300&h=400&fit=crop',
      resultImage:
          'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=300&h=400&fit=crop',
      confidence: 0.92,
      processingTime: 2.5,
      status: 'completed',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ];
}

// Additional model classes for completeness
class ClosetStats {
  final int totalItems;
  final double totalValue;
  final int recentlyAdded;
  final String mostWornItem;
  final Map<String, int> categoryBreakdown;
  final Map<String, int> colorBreakdown;
  final Map<String, int> brandBreakdown;

  const ClosetStats({
    required this.totalItems,
    required this.totalValue,
    required this.recentlyAdded,
    required this.mostWornItem,
    required this.categoryBreakdown,
    required this.colorBreakdown,
    required this.brandBreakdown,
  });
}

class TrendingStyle {
  final String id;
  final String title;
  final String growth;
  final TrendDirection trend;
  final String description;
  final String image;
  final List<String> tags;
  final int engagement;
  final int posts;

  const TrendingStyle({
    required this.id,
    required this.title,
    required this.growth,
    required this.trend,
    required this.description,
    required this.image,
    required this.tags,
    required this.engagement,
    required this.posts,
  });
}

enum TrendDirection { up, down, stable }

class NearbyShop {
  final String id;
  final String name;
  final String category;
  final double distance;
  final double rating;
  final String imageUrl;
  final String address;
  final bool isOpen;
  final List<String> offers;

  const NearbyShop({
    required this.id,
    required this.name,
    required this.category,
    required this.distance,
    required this.rating,
    required this.imageUrl,
    required this.address,
    required this.isOpen,
    required this.offers,
  });
}

class TryOnResult {
  final String id;
  final String originalImage;
  final String resultImage;
  final double confidence;
  final double processingTime;
  final String status;
  final DateTime createdAt;

  const TryOnResult({
    required this.id,
    required this.originalImage,
    required this.resultImage,
    required this.confidence,
    required this.processingTime,
    required this.status,
    required this.createdAt,
  });
}
