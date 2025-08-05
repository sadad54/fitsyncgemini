// lib/viewmodels/try_on_viewmodel.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitsyncgemini/models/try_on_model.dart';
import 'package:fitsyncgemini/services/ml_service.dart';
import 'package:fitsyncgemini/services/storage_service.dart';
import 'dart:io';

class TryOnViewModel extends StateNotifier<TryOnModel> {
  final MLService _mlService;
  final StorageService _storageService;

  TryOnViewModel(this._mlService, this._storageService)
    : super(const TryOnModel()) {
    _initializeTryOn();
  }

  Future<void> _initializeTryOn() async {
    state = state.copyWith(isLoading: true);

    try {
      await _loadOutfitOptions();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _loadOutfitOptions() async {
    try {
      // Mock outfit options - replace with actual implementation
      final outfitOptions = [
        const OutfitOption(
          id: '1',
          name: 'Casual Look',
          imageUrl:
              'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400',
          category: 'Casual',
        ),
        const OutfitOption(
          id: '2',
          name: 'Professional',
          imageUrl:
              'https://images.unsplash.com/photo-1602293589914-9e19a782a0e5?w=400',
          category: 'Work',
        ),
        const OutfitOption(
          id: '3',
          name: 'Evening Out',
          imageUrl:
              'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400',
          category: 'Event',
        ),
        const OutfitOption(
          id: '4',
          name: 'Weekend',
          imageUrl:
              'https://images.unsplash.com/photo-1494790108755-2616b612b77c?w=400',
          category: 'Casual',
        ),
        const OutfitOption(
          id: '5',
          name: 'Sporty',
          imageUrl:
              'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400',
          category: 'Athletic',
        ),
      ];

      state = state.copyWith(outfitOptions: outfitOptions);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> uploadUserPhoto(String source) async {
    try {
      state = state.copyWith(isLoading: true);

      // Mock photo upload - replace with actual implementation
      await Future.delayed(const Duration(seconds: 2));

      String photoUrl;
      if (source == 'camera') {
        // Mock camera photo
        photoUrl =
            'https://images.unsplash.com/photo-1494790108755-2616b612b77c?w=400';
      } else {
        // Mock gallery photo
        photoUrl =
            'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400';
      }

      state = state.copyWith(
        hasUserPhoto: true,
        userPhotoUrl: photoUrl,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void selectOutfit(String outfitId) {
    final outfitOptions =
        state.outfitOptions.map((outfit) {
          return outfit.copyWith(isSelected: outfit.id == outfitId);
        }).toList();

    final selectedOutfit = outfitOptions.firstWhere(
      (outfit) => outfit.id == outfitId,
    );

    state = state.copyWith(
      outfitOptions: outfitOptions,
      selectedOutfit: selectedOutfit,
    );
  }

  Future<void> tryOnOutfit() async {
    if (!state.hasUserPhoto || state.selectedOutfit == null) {
      state = state.copyWith(
        error: 'Please upload a photo and select an outfit first',
      );
      return;
    }

    try {
      state = state.copyWith(isProcessing: true);

      // Mock try-on processing - replace with actual ML service implementation
      await Future.delayed(const Duration(seconds: 3));

      // Mock result URL
      const resultUrl =
          'https://images.unsplash.com/photo-1494790108755-2616b612b77c?w=400';

      state = state.copyWith(tryOnResultUrl: resultUrl, isProcessing: false);
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
    }
  }

  void resetTryOn() {
    state = state.copyWith(
      hasUserPhoto: false,
      userPhotoUrl: null,
      selectedOutfit: null,
      tryOnResultUrl: null,
      isProcessing: false,
    );
  }

  Future<void> saveTryOnResult() async {
    if (state.tryOnResultUrl == null) {
      state = state.copyWith(error: 'No try-on result to save');
      return;
    }

    try {
      state = state.copyWith(isLoading: true);

      // Mock save operation - replace with actual implementation
      await Future.delayed(const Duration(seconds: 1));

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> shareTryOnResult() async {
    if (state.tryOnResultUrl == null) {
      state = state.copyWith(error: 'No try-on result to share');
      return;
    }

    try {
      state = state.copyWith(isLoading: true);

      // Mock share operation - replace with actual implementation
      await Future.delayed(const Duration(seconds: 1));

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final tryOnViewModelProvider =
    StateNotifierProvider<TryOnViewModel, TryOnModel>(
      (ref) => TryOnViewModel(
        ref.read(mlServiceProvider),
        ref.read(storageServiceProvider),
      ),
    );

// Mock storage service provider
final storageServiceProvider = Provider((ref) => StorageService());
