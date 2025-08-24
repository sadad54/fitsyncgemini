// lib/viewmodels/closet_viewmodel.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitsyncgemini/models/closet_model.dart';
import 'package:fitsyncgemini/models/clothing_item.dart';
import 'package:fitsyncgemini/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClosetViewModel extends StateNotifier<ClosetModel> {
  final SupabaseClient _supabase;

  ClosetViewModel(this._supabase)
    : super(
        const ClosetModel(
          items: [],
          categories: [],
          stats: ClosetStats(
            totalItems: 0,
            recentlyAdded: 0,
            mostWorn: '',
            leastWorn: '',
            totalValue: 0,
          ),
          recentActivities: [],
        ),
      ) {
    _initializeCloset();
  }

  Future<void> _initializeCloset() async {
    state = state.copyWith(isLoading: true);

    try {
      await Future.wait([_loadClosetItems(), _loadRecentActivities()]);

      _updateCategories();
      _updateStats();

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _loadClosetItems() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('clothing_items')
          .select('*')
          .eq('user_id', currentUser.id)
          .order('created_at', ascending: false);

      final items =
          (response as List)
              .map((item) => ClothingItem.fromMap(item, item['id']))
              .toList();

      state = state.copyWith(items: items);
    } catch (e) {
      print('Error loading closet items: $e');
      // Fallback to empty list
      state = state.copyWith(items: []);
    }
  }

  Future<void> _loadRecentActivities() async {
    try {
      // Mock recent activities - replace with actual implementation
      final activities = [
        const ClosetActivity(
          id: '1',
          action: 'Added',
          item: 'Blue Denim Jacket',
          time: '2h ago',
          type: ActivityType.add,
        ),
        const ClosetActivity(
          id: '2',
          action: 'Wore',
          item: 'White Button Shirt',
          time: '1d ago',
          type: ActivityType.wear,
        ),
        const ClosetActivity(
          id: '3',
          action: 'Liked',
          item: 'Black Blazer',
          time: '2d ago',
          type: ActivityType.like,
        ),
      ];
      state = state.copyWith(recentActivities: activities);
    } catch (e) {
      print('Error loading recent activities: $e');
    }
  }

  void _updateCategories() {
    final categories = [
      const ClosetCategory(id: 'all', name: 'All', count: 0),
      const ClosetCategory(id: 'tops', name: 'Tops', count: 0),
      const ClosetCategory(id: 'bottoms', name: 'Bottoms', count: 0),
      const ClosetCategory(id: 'dresses', name: 'Dresses', count: 0),
      const ClosetCategory(id: 'outerwear', name: 'Outerwear', count: 0),
      const ClosetCategory(id: 'shoes', name: 'Shoes', count: 0),
    ];

    // Update counts
    final updatedCategories =
        categories.map((category) {
          int count = 0;
          if (category.id == 'all') {
            count = state.items.length;
          } else {
            count =
                state.items
                    .where((item) => item.category.toLowerCase() == category.id)
                    .length;
          }
          return category.copyWith(count: count);
        }).toList();

    state = state.copyWith(categories: updatedCategories);
  }

  void _updateStats() {
    final totalItems = state.items.length;
    final recentlyAdded =
        state.items
            .where(
              (item) => item.createdAt.isAfter(
                DateTime.now().subtract(const Duration(days: 7)),
              ),
            )
            .length;

    // Calculate stats from actual data
    final stats = ClosetStats(
      totalItems: totalItems,
      recentlyAdded: recentlyAdded,
      mostWorn: _getMostWornItem(),
      leastWorn: _getLeastWornItem(),
      totalValue: _calculateTotalValue(),
    );

    state = state.copyWith(stats: stats);
  }

  String _getMostWornItem() {
    if (state.items.isEmpty) return '';

    // For now, return the first item - implement actual wear tracking later
    return state.items.first.name;
  }

  String _getLeastWornItem() {
    if (state.items.isEmpty) return '';

    // For now, return the last item - implement actual wear tracking later
    return state.items.last.name;
  }

  double _calculateTotalValue() {
    return state.items.fold(0.0, (sum, item) => sum + (item.price ?? 0));
  }

  void setSelectedCategory(String categoryId) {
    state = state.copyWith(selectedCategory: categoryId);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void toggleGridView() {
    state = state.copyWith(isGridView: !state.isGridView);
  }

  void toggleItemSelection(String itemId) {
    final selectedItems = List<String>.from(state.selectedItems);
    if (selectedItems.contains(itemId)) {
      selectedItems.remove(itemId);
    } else {
      selectedItems.add(itemId);
    }
    state = state.copyWith(selectedItems: selectedItems);
  }

  void clearSelection() {
    state = state.copyWith(selectedItems: []);
  }

  Future<void> addClothingItem(ClothingItem item) async {
    try {
      state = state.copyWith(isLoading: true);

      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Add user_id to the item data
      final itemData = item.toMap();
      itemData['user_id'] = currentUser.id;

      await _supabase.from('clothing_items').insert(itemData);

      // Reload closet items
      await _loadClosetItems();
      _updateCategories();
      _updateStats();

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteClothingItem(String itemId) async {
    try {
      state = state.copyWith(isLoading: true);

      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('clothing_items')
          .delete()
          .eq('id', itemId)
          .eq('user_id', currentUser.id);

      // Reload closet items
      await _loadClosetItems();
      _updateCategories();
      _updateStats();

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refreshCloset() async {
    await _initializeCloset();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final closetViewModelProvider =
    StateNotifierProvider<ClosetViewModel, ClosetModel>(
      (ref) => ClosetViewModel(Supabase.instance.client),
    );
