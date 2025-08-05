// lib/models/dashboard_model.dart
import 'package:flutter/material.dart';

class DashboardModel {
  final String greeting;
  final String userName;
  final String styleArchetype;
  final int closetItemCount;
  final List<QuickAction> quickActions;
  final List<DashboardFeature> features;
  final OutfitSuggestion? todaysSuggestion;
  final StyleInsights styleInsights;
  final List<RecentActivity> recentActivities;
  final WeatherInfo weatherInfo;
  final bool isLoading;
  final String? error;

  const DashboardModel({
    required this.greeting,
    required this.userName,
    required this.styleArchetype,
    required this.closetItemCount,
    required this.quickActions,
    required this.features,
    this.todaysSuggestion,
    required this.styleInsights,
    required this.recentActivities,
    required this.weatherInfo,
    this.isLoading = false,
    this.error,
  });

  DashboardModel copyWith({
    String? greeting,
    String? userName,
    String? styleArchetype,
    int? closetItemCount,
    List<QuickAction>? quickActions,
    List<DashboardFeature>? features,
    OutfitSuggestion? todaysSuggestion,
    StyleInsights? styleInsights,
    List<RecentActivity>? recentActivities,
    WeatherInfo? weatherInfo,
    bool? isLoading,
    String? error,
  }) {
    return DashboardModel(
      greeting: greeting ?? this.greeting,
      userName: userName ?? this.userName,
      styleArchetype: styleArchetype ?? this.styleArchetype,
      closetItemCount: closetItemCount ?? this.closetItemCount,
      quickActions: quickActions ?? this.quickActions,
      features: features ?? this.features,
      todaysSuggestion: todaysSuggestion ?? this.todaysSuggestion,
      styleInsights: styleInsights ?? this.styleInsights,
      recentActivities: recentActivities ?? this.recentActivities,
      weatherInfo: weatherInfo ?? this.weatherInfo,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class QuickAction {
  final String id;
  final String label;
  final String icon;
  final String color;
  final VoidCallback? onTap;

  const QuickAction({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });
}

class DashboardFeature {
  final String id;
  final String title;
  final String subtitle;
  final String icon;
  final List<String> gradientColors;
  final VoidCallback? onTap;

  const DashboardFeature({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    this.onTap,
  });
}

class OutfitSuggestion {
  final String id;
  final String name;
  final String occasion;
  final List<String> itemIds;
  final double matchPercentage;
  final String description;
  final WeatherInfo weatherInfo;

  const OutfitSuggestion({
    required this.id,
    required this.name,
    required this.occasion,
    required this.itemIds,
    required this.matchPercentage,
    required this.description,
    required this.weatherInfo,
  });
}

class StyleInsights {
  final String styleArchetype;
  final String description;
  final List<String> traits;
  final Map<String, String> insights;

  const StyleInsights({
    required this.styleArchetype,
    required this.description,
    required this.traits,
    required this.insights,
  });
}

class RecentActivity {
  final String id;
  final String action;
  final String item;
  final String time;
  final ActivityType type;
  final String? icon;

  const RecentActivity({
    required this.id,
    required this.action,
    required this.item,
    required this.time,
    required this.type,
    this.icon,
  });
}

enum ActivityType {
  add,
  wear,
  like,
  share,
  create,
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