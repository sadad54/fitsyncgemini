// lib/models/closet_model.dart
import 'package:flutter/material.dart';
import 'package:fitsyncgemini/models/clothing_item.dart';

class ClosetModel {
  final List<ClothingItem> items;
  final List<ClosetCategory> categories;
  final ClosetStats stats;
  final List<ClosetActivity> recentActivities;
  final String selectedCategory;
  final String searchQuery;
  final bool isGridView;
  final List<String> selectedItems;
  final bool isLoading;
  final String? error;

  const ClosetModel({
    required this.items,
    required this.categories,
    required this.stats,
    required this.recentActivities,
    this.selectedCategory = 'all',
    this.searchQuery = '',
    this.isGridView = true,
    this.selectedItems = const [],
    this.isLoading = false,
    this.error,
  });

  List<ClothingItem> get filteredItems {
    return items.where((item) {
      final matchesSearch = item.name.toLowerCase().contains(
        searchQuery.toLowerCase(),
      );
      final matchesCategory =
          selectedCategory == 'all' ||
          item.category.toLowerCase() == selectedCategory.toLowerCase();
      return matchesSearch && matchesCategory;
    }).toList();
  }

  ClosetModel copyWith({
    List<ClothingItem>? items,
    List<ClosetCategory>? categories,
    ClosetStats? stats,
    List<ClosetActivity>? recentActivities,
    String? selectedCategory,
    String? searchQuery,
    bool? isGridView,
    List<String>? selectedItems,
    bool? isLoading,
    String? error,
  }) {
    return ClosetModel(
      items: items ?? this.items,
      categories: categories ?? this.categories,
      stats: stats ?? this.stats,
      recentActivities: recentActivities ?? this.recentActivities,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      isGridView: isGridView ?? this.isGridView,
      selectedItems: selectedItems ?? this.selectedItems,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ClosetCategory {
  final String id;
  final String name;
  final int count;
  final bool isSelected;

  const ClosetCategory({
    required this.id,
    required this.name,
    required this.count,
    this.isSelected = false,
  });

  ClosetCategory copyWith({
    String? id,
    String? name,
    int? count,
    bool? isSelected,
  }) {
    return ClosetCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      count: count ?? this.count,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

class ClosetStats {
  final int totalItems;
  final int recentlyAdded;
  final String mostWorn;
  final String leastWorn;
  final double totalValue;

  const ClosetStats({
    required this.totalItems,
    required this.recentlyAdded,
    required this.mostWorn,
    required this.leastWorn,
    required this.totalValue,
  });
}

class ClosetActivity {
  final String id;
  final String action;
  final String item;
  final String time;
  final ActivityType type;

  const ClosetActivity({
    required this.id,
    required this.action,
    required this.item,
    required this.time,
    required this.type,
  });
}

enum ActivityType {
  add,
  wear,
  like,
  share,
  create,
} 