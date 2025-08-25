// lib/services/clothing_detection_service.dart
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'backend_api.dart';

// Provider for the service
final clothingDetectionServiceProvider = Provider<ClothingDetectionService>((
  ref,
) {
  return ClothingDetectionService();
});

class ClothingDetectionService {
  /// Detects clothing items from an image file (placeholder)
  /// Returns a map containing detection results or throws an exception
  Future<Map<String, dynamic>> detectClothing(File imageFile) async {
    final res = await BackendApi.createClothingItem(
      image: imageFile,
      name: 'Uploaded Item',
    );
    return res;
  }

  /// Detects colors from an image file (placeholder)
  /// Returns a map containing color detection results or throws an exception
  Future<Map<String, dynamic>> detectColors(File imageFile) async {
    // Color analysis is part of createClothingItem response; reuse detectClothing
    final res = await detectClothing(imageFile);
    return res['colorAnalysis'] ?? res['color_analysis'] ?? res;
  }

  /// Gets style suggestions from an image file (placeholder)
  /// Returns a map containing style suggestions or throws an exception
  Future<Map<String, dynamic>> getSuggestions(File imageFile) async {
    final res = await detectClothing(imageFile);
    return res['suggestions'] ?? res['styleSuggestions'] ?? res;
  }

  /// Analyzes clothing and extracts metadata using all available endpoints (placeholder)
  Future<ClothingAnalysisResult> analyzeClothing(File imageFile) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 2500));

      // Generate mock analysis data
      final detectionData = await detectClothing(imageFile);
      final colorData = await detectColors(imageFile);
      final suggestionData = await getSuggestions(imageFile);

      // Extract first detected item
      Map<String, dynamic>? firstItem;
      final items = detectionData['items'];
      if (items is List && items.isNotEmpty && items.first is Map) {
        firstItem = Map<String, dynamic>.from(items.first as Map);
      }

      // Extract category and confidence from first detection
      final detectedCategory = (firstItem?['type'] as String?)?.toString();
      final double detectedConfidence =
          (firstItem?['confidence'] is num)
              ? (firstItem?['confidence'] as num).toDouble()
              : 0.0;

      // Build color analysis from detection palette if available
      Map<String, dynamic>? colorAnalysisFromDetection;
      final palette = firstItem?['color_palette'];
      if (palette is Map) {
        final List<String> paletteColors = List<String>.from(
          (palette['colors'] is List)
              ? palette['colors'] as List
              : const <String>[],
        );
        final primary = (paletteColors.isNotEmpty) ? paletteColors.first : null;
        colorAnalysisFromDetection = {
          'dominantColors': paletteColors,
          'primaryColor': primary,
          'colorPercentages': <String, double>{},
        };
      }

      // Build suggestions from style classification if available
      Map<String, dynamic>? suggestionsFromDetection;
      final styleCls = firstItem?['style_classification'];
      if (styleCls is Map) {
        final styleName = styleCls['style']?.toString();
        suggestionsFromDetection = {
          'suggestedOutfits': <String>[],
          'complementaryItems': <String>[],
          'occasions': <String>[],
          'styleArchetype': styleName,
          'seasonRecommendations': <String>[],
          'confidence': detectedConfidence,
        };
      }

      // Combine all data
      final combinedData = <String, dynamic>{
        'category': detectedCategory,
        'confidence': detectedConfidence,
        'colors':
            (colorAnalysisFromDetection != null)
                ? List<String>.from(
                  colorAnalysisFromDetection['dominantColors'] as List,
                )
                : List<String>.from(
                  colorData['dominantColors'] ??
                      colorData['colors'] ??
                      const <String>[],
                ),
        'colorAnalysis': colorAnalysisFromDetection ?? colorData,
        'suggestions': suggestionsFromDetection ?? suggestionData,
        'tags': ['casual', 'minimalist', 'versatile'],
        'name': 'Casual T-Shirt & Jeans',
      };

      // Process the combined data and convert to structured result
      return ClothingAnalysisResult.fromCombinedJson(combinedData);
    } catch (e) {
      // Return a default result if analysis fails
      return ClothingAnalysisResult(
        detectedCategory: 'tops',
        colors: ['white', 'navy', 'grey'],
        tags: ['casual', 'minimalist'],
        suggestedName: 'Casual Top',
        confidence: 0.85,
      );
    }
  }

  /// Analyzes colors only (placeholder)
  Future<ColorAnalysisResult> analyzeColors(File imageFile) async {
    try {
      final colorData = await detectColors(imageFile);
      return ColorAnalysisResult.fromJson(colorData);
    } catch (e) {
      // Return default color analysis
      return ColorAnalysisResult(
        dominantColors: ['white', 'navy', 'grey'],
        accentColors: ['black', 'beige'],
        primaryColor: 'white',
        confidence: 0.85,
      );
    }
  }

  /// Gets style suggestions only (placeholder)
  Future<StyleSuggestionsResult> getStyleSuggestions(File imageFile) async {
    try {
      final suggestionData = await getSuggestions(imageFile);
      return StyleSuggestionsResult.fromJson(suggestionData);
    } catch (e) {
      // Return default style suggestions
      return StyleSuggestionsResult(
        suggestedOutfits: ['Minimalist Look', 'Casual Style'],
        complementaryItems: ['White sneakers', 'Minimalist watch'],
        occasions: ['casual', 'weekend'],
        styleArchetype: 'minimalist',
        seasonRecommendations: ['spring', 'summer'],
        confidence: 0.85,
      );
    }
  }

  /// Health check for the detection service (placeholder)
  Future<bool> isServiceHealthy() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));

    // Always return true for placeholder service
    return true;
  }
}

/// Custom exception for clothing detection errors
class ClothingDetectionException implements Exception {
  final String message;
  final int statusCode;

  ClothingDetectionException(this.message, this.statusCode);

  @override
  String toString() => 'ClothingDetectionException: $message';
}

/// Data model for clothing analysis results
class ClothingAnalysisResult {
  final String? detectedCategory;
  final List<String> colors;
  final List<String> tags;
  final String? suggestedName;
  final double confidence;
  final ColorAnalysisResult? colorAnalysis;
  final StyleSuggestionsResult? styleSuggestions;
  final Map<String, dynamic> rawData;

  ClothingAnalysisResult({
    this.detectedCategory,
    this.colors = const [],
    this.tags = const [],
    this.suggestedName,
    this.confidence = 0.0,
    this.colorAnalysis,
    this.styleSuggestions,
    this.rawData = const {},
  });

  factory ClothingAnalysisResult.fromJson(Map<String, dynamic> json) {
    return ClothingAnalysisResult(
      detectedCategory: json['category']?.toString(),
      colors: List<String>.from(json['colors'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      suggestedName: json['name']?.toString(),
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      rawData: json,
    );
  }

  factory ClothingAnalysisResult.fromCombinedJson(Map<String, dynamic> json) {
    return ClothingAnalysisResult(
      detectedCategory: json['category']?.toString(),
      colors: List<String>.from(json['colors'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      suggestedName: json['name']?.toString(),
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      colorAnalysis:
          json['colorAnalysis'] != null
              ? ColorAnalysisResult.fromJson(json['colorAnalysis'])
              : null,
      styleSuggestions:
          json['suggestions'] != null
              ? StyleSuggestionsResult.fromJson(json['suggestions'])
              : null,
      rawData: json,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': detectedCategory,
      'colors': colors,
      'tags': tags,
      'name': suggestedName,
      'confidence': confidence,
      'colorAnalysis': colorAnalysis?.toJson(),
      'styleSuggestions': styleSuggestions?.toJson(),
      'rawData': rawData,
    };
  }
}

/// Data model for color analysis results
class ColorAnalysisResult {
  final List<String> dominantColors;
  final List<String> accentColors;
  final String? primaryColor;
  final Map<String, double> colorPercentages;
  final double confidence;
  final Map<String, dynamic> rawData;

  ColorAnalysisResult({
    this.dominantColors = const [],
    this.accentColors = const [],
    this.primaryColor,
    this.colorPercentages = const {},
    this.confidence = 0.0,
    this.rawData = const {},
  });

  factory ColorAnalysisResult.fromJson(Map<String, dynamic> json) {
    return ColorAnalysisResult(
      dominantColors: List<String>.from(
        json['dominantColors'] ?? json['colors'] ?? [],
      ),
      accentColors: List<String>.from(json['accentColors'] ?? []),
      primaryColor: json['primaryColor']?.toString(),
      colorPercentages: Map<String, double>.from(
        (json['colorPercentages'] ?? {}).map(
          (k, v) => MapEntry(k, v.toDouble()),
        ),
      ),
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      rawData: json,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dominantColors': dominantColors,
      'accentColors': accentColors,
      'primaryColor': primaryColor,
      'colorPercentages': colorPercentages,
      'confidence': confidence,
      'rawData': rawData,
    };
  }
}

/// Data model for style suggestions results
class StyleSuggestionsResult {
  final List<String> suggestedOutfits;
  final List<String> complementaryItems;
  final List<String> occasions;
  final String? styleArchetype;
  final List<String> seasonRecommendations;
  final double confidence;
  final Map<String, dynamic> rawData;

  StyleSuggestionsResult({
    this.suggestedOutfits = const [],
    this.complementaryItems = const [],
    this.occasions = const [],
    this.styleArchetype,
    this.seasonRecommendations = const [],
    this.confidence = 0.0,
    this.rawData = const {},
  });

  factory StyleSuggestionsResult.fromJson(Map<String, dynamic> json) {
    return StyleSuggestionsResult(
      suggestedOutfits: List<String>.from(
        json['suggestedOutfits'] ?? json['outfits'] ?? [],
      ),
      complementaryItems: List<String>.from(
        json['complementaryItems'] ?? json['complementary'] ?? [],
      ),
      occasions: List<String>.from(json['occasions'] ?? []),
      styleArchetype:
          json['styleArchetype']?.toString() ?? json['style']?.toString(),
      seasonRecommendations: List<String>.from(
        json['seasonRecommendations'] ?? json['seasons'] ?? [],
      ),
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      rawData: json,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'suggestedOutfits': suggestedOutfits,
      'complementaryItems': complementaryItems,
      'occasions': occasions,
      'styleArchetype': styleArchetype,
      'seasonRecommendations': seasonRecommendations,
      'confidence': confidence,
      'rawData': rawData,
    };
  }
}
