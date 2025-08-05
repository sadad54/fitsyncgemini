// lib/viewmodels/outfit_suggestions_viewmodel.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitsyncgemini/models/outfit_suggestions_model.dart';
import 'package:fitsyncgemini/services/ml_service.dart';
import 'package:fitsyncgemini/services/firestore_service.dart';

class OutfitSuggestionsViewModel extends StateNotifier<OutfitSuggestionsModel> {
  final MLService _mlService;
  final FirestoreService _firestoreService;

  OutfitSuggestionsViewModel(this._mlService, this._firestoreService)
      : super(const OutfitSuggestionsModel(
          styleFocus: StyleFocus(
            title: '',
            description: '',
            weatherInfo: WeatherInfo(
              temperature: 0,
              condition: '',
            ),
            recommendations: [],
          ),
        )) {
    _initializeOutfitSuggestions();
  }

  Future<void> _initializeOutfitSuggestions() async {
    state = state.copyWith(isLoading: true);
    
    try {
      await Future.wait([
        _loadStyleFocus(),
        _loadSuggestions(),
      ]);
      
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> _loadStyleFocus() async {
    try {
      // Mock style focus - replace with actual implementation
      const styleFocus = StyleFocus(
        title: 'Today\'s Style Focus',
        description: 'Minimalist • Light layers recommended for temperature changes',
        weatherInfo: WeatherInfo(
          temperature: 24.0,
          condition: 'Sunny',
        ),
        recommendations: [
          'Light layers for temperature changes',
          'Neutral colors for versatility',
          'Comfortable fabrics for all-day wear',
        ],
      );
      
      state = state.copyWith(styleFocus: styleFocus);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _loadSuggestions() async {
    try {
      // Mock suggestions - replace with actual ML service implementation
      final suggestions = [
        const OutfitSuggestion(
          id: '1',
          name: 'Perfect for Today\'s Weather',
          occasion: 'Casual',
          items: [
            OutfitItem(
              id: 'item1',
              name: 'White Cotton Tee',
              category: 'comfortable',
              imageUrl: 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400',
              isMain: true,
            ),
            OutfitItem(
              id: 'item2',
              name: 'Light Blue Jeans',
              category: 'breathable',
              imageUrl: 'https://images.unsplash.com/photo-1602293589914-9e19a782a0e5?w=400',
            ),
            OutfitItem(
              id: 'item3',
              name: 'White Sneakers',
              category: 'casual',
              imageUrl: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400',
            ),
          ],
          matchPercentage: 95.0,
          description: 'Based on weather forecast and your minimalist style preference',
          weatherInfo: WeatherInfo(
            temperature: 24.0,
            condition: 'Sunny',
          ),
        ),
        const OutfitSuggestion(
          id: '2',
          name: 'Professional Power Look',
          occasion: 'Work',
          items: [
            OutfitItem(
              id: 'item4',
              name: 'Navy Blazer',
              category: 'Professional',
              imageUrl: 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400',
              isMain: true,
            ),
            OutfitItem(
              id: 'item5',
              name: 'White Button Shirt',
              category: 'Classic',
              imageUrl: 'https://images.unsplash.com/photo-1602293589914-9e19a782a0e5?w=400',
            ),
            OutfitItem(
              id: 'item6',
              name: 'Tailored Trousers',
              category: 'Business',
              imageUrl: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400',
            ),
          ],
          matchPercentage: 89.0,
          description: 'Perfect for important meetings and presentations',
          weatherInfo: WeatherInfo(
            temperature: 24.0,
            condition: 'Meeting Ready',
          ),
        ),
      ];
      
      state = state.copyWith(suggestions: suggestions);
    } catch (e) {
      // Handle error
    }
  }

  void setSelectedCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  Future<void> generateNewSuggestions() async {
    try {
      state = state.copyWith(isGenerating: true);
      
      // Mock generation delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Mock new suggestions - replace with actual ML service implementation
      final newSuggestions = [
        const OutfitSuggestion(
          id: '3',
          name: 'Fresh Casual Look',
          occasion: 'Casual',
          items: [
            OutfitItem(
              id: 'item7',
              name: 'Striped T-Shirt',
              category: 'casual',
              imageUrl: 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400',
              isMain: true,
            ),
            OutfitItem(
              id: 'item8',
              name: 'Black Jeans',
              category: 'versatile',
              imageUrl: 'https://images.unsplash.com/photo-1602293589914-9e19a782a0e5?w=400',
            ),
            OutfitItem(
              id: 'item9',
              name: 'White Sneakers',
              category: 'comfortable',
              imageUrl: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400',
            ),
          ],
          matchPercentage: 92.0,
          description: 'A fresh take on casual wear with modern styling',
          weatherInfo: WeatherInfo(
            temperature: 24.0,
            condition: 'Sunny',
          ),
        ),
      ];
      
      final updatedSuggestions = [...state.suggestions, ...newSuggestions];
      
      state = state.copyWith(
        suggestions: updatedSuggestions,
        isGenerating: false,
      );
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        error: e.toString(),
      );
    }
  }

  Future<void> saveOutfitSuggestion(String suggestionId) async {
    try {
      final suggestion = state.suggestions.firstWhere(
        (s) => s.id == suggestionId,
      );
      
      // Mock user ID - replace with actual user ID from auth
      const userId = 'current_user_id';
      
      // Convert to Outfit model and save
      // This would require creating an Outfit from OutfitSuggestion
      // For now, just mark as favorite in the current state
      
      final updatedSuggestions = state.suggestions.map((s) {
        if (s.id == suggestionId) {
          return s.copyWith(isFavorite: !s.isFavorite);
        }
        return s;
      }).toList();
      
      state = state.copyWith(suggestions: updatedSuggestions);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> refreshSuggestions() async {
    await _initializeOutfitSuggestions();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final outfitSuggestionsViewModelProvider = StateNotifierProvider<OutfitSuggestionsViewModel, OutfitSuggestionsModel>(
  (ref) => OutfitSuggestionsViewModel(
    ref.read(mlServiceProvider),
    ref.read(firestoreServiceProvider),
  ),
); 