// lib/services/clothing_detection_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for the service
final clothingDetectionServiceProvider = Provider<ClothingDetectionService>((
  ref,
) {
  return ClothingDetectionService();
});

class ClothingDetectionService {
  // Base URL - you can make this configurable
  static const String _baseUrl = 'http://127.0.0.1:8000/api/v1';

  // Timeout duration
  static const Duration _timeout = Duration(seconds: 30);

  /// Detects clothing items from an image file
  /// Returns a map containing detection results or throws an exception
  Future<Map<String, dynamic>> detectClothing(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/detect'),
      );

      // Add the image file to the request
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      // Add headers if needed
      request.headers.addAll({
        'Accept': 'application/json',
        'Content-Type': 'multipart/form-data',
      });

      // Send request with timeout
      var streamedResponse = await request.send().timeout(_timeout);
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return data;
      } else {
        throw ClothingDetectionException(
          'Detection failed with status code: ${response.statusCode}',
          response.statusCode,
        );
      }
    } on SocketException {
      throw ClothingDetectionException(
        'No internet connection or server unreachable',
        0,
      );
    } on http.ClientException {
      throw ClothingDetectionException('Network error occurred', 0);
    } on FormatException {
      throw ClothingDetectionException(
        'Invalid response format from server',
        0,
      );
    } catch (e) {
      throw ClothingDetectionException('Unexpected error: $e', 0);
    }
  }

  /// Detects colors from an image file
  /// Returns a map containing color detection results or throws an exception
  Future<Map<String, dynamic>> detectColors(File imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/color'));

      // Add the image file to the request
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      // Add headers if needed
      request.headers.addAll({
        'Accept': 'application/json',
        'Content-Type': 'multipart/form-data',
      });

      // Send request with timeout
      var streamedResponse = await request.send().timeout(_timeout);
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return data;
      } else {
        throw ClothingDetectionException(
          'Color detection failed with status code: ${response.statusCode}',
          response.statusCode,
        );
      }
    } on SocketException {
      throw ClothingDetectionException(
        'No internet connection or server unreachable',
        0,
      );
    } on http.ClientException {
      throw ClothingDetectionException('Network error occurred', 0);
    } on FormatException {
      throw ClothingDetectionException(
        'Invalid response format from server',
        0,
      );
    } catch (e) {
      throw ClothingDetectionException('Unexpected error: $e', 0);
    }
  }

  /// Gets style suggestions from an image file
  /// Returns a map containing style suggestions or throws an exception
  Future<Map<String, dynamic>> getSuggestions(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/suggest'),
      );

      // Add the image file to the request
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      // Add headers if needed
      request.headers.addAll({
        'Accept': 'application/json',
        'Content-Type': 'multipart/form-data',
      });

      // Send request with timeout
      var streamedResponse = await request.send().timeout(_timeout);
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return data;
      } else {
        throw ClothingDetectionException(
          'Style suggestions failed with status code: ${response.statusCode}',
          response.statusCode,
        );
      }
    } on SocketException {
      throw ClothingDetectionException(
        'No internet connection or server unreachable',
        0,
      );
    } on http.ClientException {
      throw ClothingDetectionException('Network error occurred', 0);
    } on FormatException {
      throw ClothingDetectionException(
        'Invalid response format from server',
        0,
      );
    } catch (e) {
      throw ClothingDetectionException('Unexpected error: $e', 0);
    }
  }

  /// Analyzes clothing and extracts metadata using all available endpoints
  Future<ClothingAnalysisResult> analyzeClothing(File imageFile) async {
    try {
      // Run all analyses in parallel for better performance
      final futures = await Future.wait([
        detectClothing(imageFile).catchError((e) => <String, dynamic>{}),
        detectColors(imageFile).catchError((e) => <String, dynamic>{}),
        getSuggestions(imageFile).catchError((e) => <String, dynamic>{}),
      ]);

      final detectionData = futures[0] as Map<String, dynamic>;
      final colorData = futures[1] as Map<String, dynamic>;
      final suggestionData = futures[2] as Map<String, dynamic>;

      // Combine all results into a comprehensive analysis
      final combinedData = {
        ...detectionData,
        'colorAnalysis': colorData,
        'suggestions': suggestionData,
      };

      // Process the combined data and convert to structured result
      return ClothingAnalysisResult.fromCombinedJson(combinedData);
    } catch (e) {
      rethrow;
    }
  }

  /// Analyzes colors only
  Future<ColorAnalysisResult> analyzeColors(File imageFile) async {
    try {
      final colorData = await detectColors(imageFile);
      return ColorAnalysisResult.fromJson(colorData);
    } catch (e) {
      rethrow;
    }
  }

  /// Gets style suggestions only
  Future<StyleSuggestionsResult> getStyleSuggestions(File imageFile) async {
    try {
      final suggestionData = await getSuggestions(imageFile);
      return StyleSuggestionsResult.fromJson(suggestionData);
    } catch (e) {
      rethrow;
    }
  }

  /// Health check for the detection service
  Future<bool> isServiceHealthy() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/health'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(_timeout);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
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
