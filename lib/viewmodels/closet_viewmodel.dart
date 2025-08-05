// lib/viewmodels/closet_viewmodel.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitsyncgemini/models/closet_model.dart';
import 'package:fitsyncgemini/models/clothing_item.dart';
import 'package:fitsyncgemini/services/firestore_service.dart';

class ClosetViewModel extends StateNotifier<ClosetModel> {
  final FirestoreService _firestoreService;

  ClosetViewModel(this._firestoreService)
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
      // Mock user ID - replace with actual user ID from auth
      const userId = 'current_user_id';
      final closetStream = _firestoreService.getClosetItems(userId);
      final items = await closetStream.first;
      state = state.copyWith(items: items);
    } catch (e) {
      // Handle error
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
      // Handle error
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

    // Mock stats - replace with actual calculation
    const stats = ClosetStats(
      totalItems: 6,
      recentlyAdded: 3,
      mostWorn: 'White Button Shirt',
      leastWorn: 'Black Dress',
      totalValue: 2840,
    );

    state = state.copyWith(stats: stats);
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

      // Mock user ID - replace with actual user ID from auth
      const userId = 'current_user_id';
      await _firestoreService.addClothingItem(userId, item);

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

      // Mock user ID - replace with actual user ID from auth
      const userId = 'current_user_id';
      await _firestoreService.deleteClothingItem(userId, itemId);

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
      (ref) => ClosetViewModel(ref.read(firestoreServiceProvider)),
    );
