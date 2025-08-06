// lib/services/outfit_suggestions_service.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitsyncgemini/services/clothing_detection_service.dart';
import 'dart:io';

// Provider for outfit suggestions service
final outfitSuggestionsServiceProvider = Provider<OutfitSuggestionsService>((
  ref,
) {
  final clothingDetectionService = ref.read(clothingDetectionServiceProvider);
  return OutfitSuggestionsService(clothingDetectionService);
});

class OutfitSuggestionsService {
  final ClothingDetectionService _clothingDetectionService;

  OutfitSuggestionsService(this._clothingDetectionService);

  /// Generate outfit suggestions based on a single clothing item
  Future<OutfitRecommendations> generateOutfitSuggestions(
    File imageFile,
  ) async {
    try {
      final suggestions = await _clothingDetectionService.getStyleSuggestions(
        imageFile,
      );
      final colorAnalysis = await _clothingDetectionService.analyzeColors(
        imageFile,
      );

      return OutfitRecommendations(
        baseItem: imageFile,
        styleSuggestions: suggestions,
        colorAnalysis: colorAnalysis,
        recommendedOutfits: _buildOutfitRecommendations(
          suggestions,
          colorAnalysis,
        ),
      );
    } catch (e) {
      throw OutfitSuggestionsException(
        'Failed to generate outfit suggestions: $e',
      );
    }
  }

  /// Generate suggestions for multiple items
  Future<List<OutfitCombination>> generateCombinations(List<File> items) async {
    final combinations = <OutfitCombination>[];

    for (int i = 0; i < items.length; i++) {
      for (int j = i + 1; j < items.length; j++) {
        try {
          final item1Analysis = await _clothingDetectionService.analyzeClothing(
            items[i],
          );
          final item2Analysis = await _clothingDetectionService.analyzeClothing(
            items[j],
          );

          final compatibility = _calculateCompatibility(
            item1Analysis,
            item2Analysis,
          );

          if (compatibility.score > 0.6) {
            // Only include good combinations
            combinations.add(
              OutfitCombination(
                items: [items[i], items[j]],
                compatibility: compatibility,
                occasion: compatibility.bestOccasion,
                season: compatibility.bestSeason,
              ),
            );
          }
        } catch (e) {
          // Skip this combination if analysis fails
          continue;
        }
      }
    }

    // Sort by compatibility score
    combinations.sort(
      (a, b) => b.compatibility.score.compareTo(a.compatibility.score),
    );

    return combinations;
  }

  /// Check color compatibility between items
  Future<ColorCompatibility> checkColorCompatibility(
    File item1,
    File item2,
  ) async {
    try {
      final color1 = await _clothingDetectionService.analyzeColors(item1);
      final color2 = await _clothingDetectionService.analyzeColors(item2);

      return _analyzeColorCompatibility(color1, color2);
    } catch (e) {
      throw OutfitSuggestionsException(
        'Failed to check color compatibility: $e',
      );
    }
  }

  List<RecommendedOutfit> _buildOutfitRecommendations(
    StyleSuggestionsResult suggestions,
    ColorAnalysisResult colorAnalysis,
  ) {
    final outfits = <RecommendedOutfit>[];

    for (final outfit in suggestions.suggestedOutfits) {
      outfits.add(
        RecommendedOutfit(
          name: outfit,
          items: suggestions.complementaryItems,
          occasion:
              suggestions.occasions.isNotEmpty
                  ? suggestions.occasions.first
                  : 'casual',
          colorScheme: colorAnalysis.dominantColors,
          confidence: suggestions.confidence,
        ),
      );
    }

    return outfits;
  }

  CompatibilityScore _calculateCompatibility(
    ClothingAnalysisResult item1,
    ClothingAnalysisResult item2,
  ) {
    double score = 0.0;
    String bestOccasion = 'casual';
    String bestSeason = 'all seasons';

    // Color compatibility (40% weight)
    if (item1.colorAnalysis != null && item2.colorAnalysis != null) {
      final colorCompat = _analyzeColorCompatibility(
        item1.colorAnalysis!,
        item2.colorAnalysis!,
      );
      score += colorCompat.score * 0.4;
    }

    // Style compatibility (30% weight)
    if (item1.styleSuggestions != null && item2.styleSuggestions != null) {
      final commonOccasions = item1.styleSuggestions!.occasions
          .toSet()
          .intersection(item2.styleSuggestions!.occasions.toSet());
      if (commonOccasions.isNotEmpty) {
        score += 0.3;
        bestOccasion = commonOccasions.first;
      }

      final commonSeasons = item1.styleSuggestions!.seasonRecommendations
          .toSet()
          .intersection(item2.styleSuggestions!.seasonRecommendations.toSet());
      if (commonSeasons.isNotEmpty) {
        bestSeason = commonSeasons.first;
      }
    }

    // Category compatibility (30% weight)
    if (item1.detectedCategory != null && item2.detectedCategory != null) {
      if (_areCompatibleCategories(
        item1.detectedCategory!,
        item2.detectedCategory!,
      )) {
        score += 0.3;
      }
    }

    return CompatibilityScore(
      score: score,
      bestOccasion: bestOccasion,
      bestSeason: bestSeason,
    );
  }

  ColorCompatibility _analyzeColorCompatibility(
    ColorAnalysisResult color1,
    ColorAnalysisResult color2,
  ) {
    double score = 0.0;
    final reasons = <String>[];

    // Check for complementary colors
    if (color1.primaryColor != null && color2.primaryColor != null) {
      if (_areComplementaryColors(color1.primaryColor!, color2.primaryColor!)) {
        score += 0.5;
        reasons.add('Complementary colors');
      }
    }

    // Check for neutral combinations
    final neutralColors = ['white', 'black', 'grey', 'beige'];
    final hasNeutral1 = color1.dominantColors.any(
      (c) => neutralColors.contains(c.toLowerCase()),
    );
    final hasNeutral2 = color2.dominantColors.any(
      (c) => neutralColors.contains(c.toLowerCase()),
    );

    if (hasNeutral1 || hasNeutral2) {
      score += 0.3;
      reasons.add('Neutral base');
    }

    // Check for monochromatic scheme
    final commonColors = color1.dominantColors.toSet().intersection(
      color2.dominantColors.toSet(),
    );
    if (commonColors.isNotEmpty) {
      score += 0.4;
      reasons.add('Matching colors');
    }

    return ColorCompatibility(
      score: score,
      reasons: reasons,
      recommendedCombination:
          '${color1.primaryColor} with ${color2.primaryColor}',
    );
  }

  bool _areCompatibleCategories(String category1, String category2) {
    // Define compatible category pairs
    final compatiblePairs = {
      'Tops': ['Bottoms', 'Outerwear'],
      'Bottoms': ['Tops', 'Outerwear'],
      'Dresses': ['Outerwear', 'Accessories'],
      'Outerwear': ['Tops', 'Bottoms', 'Dresses'],
      'Shoes': ['Tops', 'Bottoms', 'Dresses', 'Outerwear'],
      'Accessories': ['Tops', 'Bottoms', 'Dresses', 'Outerwear'],
    };

    return compatiblePairs[category1]?.contains(category2) ?? false;
  }

  bool _areComplementaryColors(String color1, String color2) {
    // Define complementary color pairs
    final complementaryPairs = {
      'red': ['green', 'white', 'black'],
      'blue': ['orange', 'white', 'beige'],
      'yellow': ['purple', 'navy', 'black'],
      'green': ['red', 'pink', 'white'],
      'purple': ['yellow', 'gold', 'white'],
      'orange': ['blue', 'navy', 'white'],
    };

    return complementaryPairs[color1.toLowerCase()]?.contains(
          color2.toLowerCase(),
        ) ??
        false;
  }
}

// Data models for outfit suggestions

class OutfitRecommendations {
  final File baseItem;
  final StyleSuggestionsResult styleSuggestions;
  final ColorAnalysisResult colorAnalysis;
  final List<RecommendedOutfit> recommendedOutfits;

  OutfitRecommendations({
    required this.baseItem,
    required this.styleSuggestions,
    required this.colorAnalysis,
    required this.recommendedOutfits,
  });
}

class RecommendedOutfit {
  final String name;
  final List<String> items;
  final String occasion;
  final List<String> colorScheme;
  final double confidence;

  RecommendedOutfit({
    required this.name,
    required this.items,
    required this.occasion,
    required this.colorScheme,
    required this.confidence,
  });
}

class OutfitCombination {
  final List<File> items;
  final CompatibilityScore compatibility;
  final String occasion;
  final String season;

  OutfitCombination({
    required this.items,
    required this.compatibility,
    required this.occasion,
    required this.season,
  });
}

class CompatibilityScore {
  final double score;
  final String bestOccasion;
  final String bestSeason;

  CompatibilityScore({
    required this.score,
    required this.bestOccasion,
    required this.bestSeason,
  });
}

class ColorCompatibility {
  final double score;
  final List<String> reasons;
  final String recommendedCombination;

  ColorCompatibility({
    required this.score,
    required this.reasons,
    required this.recommendedCombination,
  });
}

class OutfitSuggestionsException implements Exception {
  final String message;

  OutfitSuggestionsException(this.message);

  @override
  String toString() => 'OutfitSuggestionsException: $message';
}
