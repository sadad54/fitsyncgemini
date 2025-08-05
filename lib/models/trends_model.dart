// lib/models/trends_model.dart
import 'package:flutter/material.dart';

class TrendsModel {
  final String selectedScope;
  final String selectedTimeframe;
  final List<TrendingStyle> trendingNow;
  final List<FashionInsight> fashionInsights;
  final List<InfluencerSpotlight> influencerSpotlight;
  final bool isLoading;
  final String? error;

  const TrendsModel({
    this.selectedScope = 'global',
    this.selectedTimeframe = 'week',
    this.trendingNow = const [],
    this.fashionInsights = const [],
    this.influencerSpotlight = const [],
    this.isLoading = false,
    this.error,
  });

  TrendsModel copyWith({
    String? selectedScope,
    String? selectedTimeframe,
    List<TrendingStyle>? trendingNow,
    List<FashionInsight>? fashionInsights,
    List<InfluencerSpotlight>? influencerSpotlight,
    bool? isLoading,
    String? error,
  }) {
    return TrendsModel(
      selectedScope: selectedScope ?? this.selectedScope,
      selectedTimeframe: selectedTimeframe ?? this.selectedTimeframe,
      trendingNow: trendingNow ?? this.trendingNow,
      fashionInsights: fashionInsights ?? this.fashionInsights,
      influencerSpotlight: influencerSpotlight ?? this.influencerSpotlight,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
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

enum TrendDirection {
  up,
  down,
  stable,
}

class FashionInsight {
  final String category;
  final List<String> trending;
  final List<String> declining;

  const FashionInsight({
    required this.category,
    required this.trending,
    required this.declining,
  });
}

class InfluencerSpotlight {
  final String id;
  final String name;
  final String handle;
  final String trendSetter;
  final String followers;
  final String engagement;
  final String recentTrend;

  const InfluencerSpotlight({
    required this.id,
    required this.name,
    required this.handle,
    required this.trendSetter,
    required this.followers,
    required this.engagement,
    required this.recentTrend,
  });
} 