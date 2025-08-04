class AppConstants {
  // App Info
  static const String appName = 'FitSync';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Your AI-Powered Fashion Companion';

  // Style Archetypes
  static const List<String> styleArchetypes = [
    'Minimalist',
    'Streetwear',
    'Grunge',
    'Old Money',
    'Boho',
    'Preppy',
    'Romantic',
    'Edgy',
  ];

  // Clothing Categories
  static const List<String> clothingCategories = [
    'Tops',
    'Bottoms',
    'Dresses',
    'Outerwear',
    'Shoes',
    'Accessories',
    'Bags',
    'Jewelry',
  ];

  // Occasions
  static const List<String> occasions = [
    'Casual',
    'Work',
    'Date',
    'Party',
    'Workout',
    'Formal',
    'Beach',
    'Travel',
  ];

  // Colors
  static const List<String> commonColors = [
    'Black',
    'White',
    'Gray',
    'Brown',
    'Beige',
    'Navy',
    'Blue',
    'Red',
    'Pink',
    'Green',
    'Yellow',
    'Purple',
    'Orange',
  ];

  // ML Confidence Thresholds
  static const double minClothingDetectionConfidence = 0.7;
  static const double minOutfitCompatibilityScore = 0.6;
  static const double minTrendDetectionConfidence = 0.8;

  // Image Constraints
  static const int maxImageSizeBytes = 10 * 1024 * 1024; // 10MB
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png'];

  // Nearby Feed
  static const double defaultSearchRadiusKm = 5.0;
  static const double maxSearchRadiusKm = 50.0;
  static const int maxNearbyPosts = 50;

  // Outfit Generation
  static const int maxOutfitSuggestions = 6;
  static const int maxOutfitItems = 8;

  // Storage Paths
  static const String userProfilePath = 'users/{userId}/profile.jpg';
  static const String clothingItemPath = 'users/{userId}/clothing/{itemId}.jpg';
  static const String outfitImagePath = 'users/{userId}/outfits/{outfitId}.jpg';
  static const String tryOnImagePath = 'users/{userId}/tryon/{timestamp}.jpg';

  // Error Messages
  static const String networkErrorMessage =
      'Network error. Please check your connection.';
  static const String authErrorMessage =
      'Authentication failed. Please try again.';
  static const String mlErrorMessage = 'AI analysis failed. Please try again.';
  static const String uploadErrorMessage = 'Upload failed. Please try again.';
  static const String genericErrorMessage =
      'Something went wrong. Please try again.';

  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
}
