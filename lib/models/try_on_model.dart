// lib/models/try_on_model.dart
import 'package:flutter/material.dart';

class TryOnModel {
  final bool hasUserPhoto;
  final String? userPhotoUrl;
  final bool isProcessing;
  final List<OutfitOption> outfitOptions;
  final OutfitOption? selectedOutfit;
  final String? tryOnResultUrl;
  final bool isLoading;
  final String? error;

  const TryOnModel({
    this.hasUserPhoto = false,
    this.userPhotoUrl,
    this.isProcessing = false,
    this.outfitOptions = const [],
    this.selectedOutfit,
    this.tryOnResultUrl,
    this.isLoading = false,
    this.error,
  });

  TryOnModel copyWith({
    bool? hasUserPhoto,
    String? userPhotoUrl,
    bool? isProcessing,
    List<OutfitOption>? outfitOptions,
    OutfitOption? selectedOutfit,
    String? tryOnResultUrl,
    bool? isLoading,
    String? error,
  }) {
    return TryOnModel(
      hasUserPhoto: hasUserPhoto ?? this.hasUserPhoto,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      isProcessing: isProcessing ?? this.isProcessing,
      outfitOptions: outfitOptions ?? this.outfitOptions,
      selectedOutfit: selectedOutfit ?? this.selectedOutfit,
      tryOnResultUrl: tryOnResultUrl ?? this.tryOnResultUrl,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class OutfitOption {
  final String id;
  final String name;
  final String imageUrl;
  final String category;
  final bool isSelected;

  const OutfitOption({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.category,
    this.isSelected = false,
  });

  OutfitOption copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? category,
    bool? isSelected,
  }) {
    return OutfitOption(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      isSelected: isSelected ?? this.isSelected,
    );
  }
} 