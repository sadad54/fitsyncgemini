// lib/models/outfit_suggestions_model.dart
import 'package:flutter/material.dart';

class OutfitSuggestionsModel {
  final String selectedCategory;
  final List<OutfitSuggestion> suggestions;
  final StyleFocus styleFocus;
  final bool isGenerating;
  final bool isLoading;
  final String? error;

  const OutfitSuggestionsModel({
    this.selectedCategory = 'Today',
    this.suggestions = const [],
    required this.styleFocus,
    this.isGenerating = false,
    this.isLoading = false,
    this.error,
  });

  OutfitSuggestionsModel copyWith({
    String? selectedCategory,
    List<OutfitSuggestion>? suggestions,
    StyleFocus? styleFocus,
    bool? isGenerating,
    bool? isLoading,
    String? error,
  }) {
    return OutfitSuggestionsModel(
      selectedCategory: selectedCategory ?? this.selectedCategory,
      suggestions: suggestions ?? this.suggestions,
      styleFocus: styleFocus ?? this.styleFocus,
      isGenerating: isGenerating ?? this.isGenerating,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class OutfitSuggestion {
  final String id;
  final String name;
  final String occasion;
  final List<OutfitItem> items;
  final double matchPercentage;
  final String description;
  final WeatherInfo weatherInfo;
  final bool isFavorite;

  const OutfitSuggestion({
    required this.id,
    required this.name,
    required this.occasion,
    required this.items,
    required this.matchPercentage,
    required this.description,
    required this.weatherInfo,
    this.isFavorite = false,
  });

  OutfitSuggestion copyWith({
    String? id,
    String? name,
    String? occasion,
    List<OutfitItem>? items,
    double? matchPercentage,
    String? description,
    WeatherInfo? weatherInfo,
    bool? isFavorite,
  }) {
    return OutfitSuggestion(
      id: id ?? this.id,
      name: name ?? this.name,
      occasion: occasion ?? this.occasion,
      items: items ?? this.items,
      matchPercentage: matchPercentage ?? this.matchPercentage,
      description: description ?? this.description,
      weatherInfo: weatherInfo ?? this.weatherInfo,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

class OutfitItem {
  final String id;
  final String name;
  final String category;
  final String imageUrl;
  final bool isMain;

  const OutfitItem({
    required this.id,
    required this.name,
    required this.category,
    required this.imageUrl,
    this.isMain = false,
  });
}

class StyleFocus {
  final String title;
  final String description;
  final WeatherInfo weatherInfo;
  final List<String> recommendations;

  const StyleFocus({
    required this.title,
    required this.description,
    required this.weatherInfo,
    required this.recommendations,
  });
}

class WeatherInfo {
  final double temperature;
  final String condition;
  final String unit;

  const WeatherInfo({
    required this.temperature,
    required this.condition,
    this.unit = '°C',
  });

  String get formattedTemperature => '${temperature.toInt()}$unit';
}
