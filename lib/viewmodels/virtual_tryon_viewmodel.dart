// lib/viewmodels/virtual_tryon_viewmodel.dart

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitsyncgemini/services/MLAPI_service.dart';
import 'package:fitsyncgemini/models/virtual_tryon_model.dart';

import 'dart:io';

class VirtualTryOnState {
  final bool isLoading;
  final String? error;
  final TryOnSession? currentSession;
  final List<QuickOutfitSuggestion> outfitSuggestions;
  final List<TryOnFeature> availableFeatures;
  final TryOnPreferences? userPreferences;
  final ViewMode currentViewMode;
  final int selectedOutfitIndex;
  final bool isProcessing;
  final double processingProgress;
  final Map<String, dynamic>? processingStatus;
  final List<TryOnOutfitAttempt> outfitAttempts;

  const VirtualTryOnState({
    this.isLoading = false,
    this.error,
    this.currentSession,
    this.outfitSuggestions = const [],
    this.availableFeatures = const [],
    this.userPreferences,
    this.currentViewMode = ViewMode.ar,
    this.selectedOutfitIndex = 0,
    this.isProcessing = false,
    this.processingProgress = 0.0,
    this.processingStatus,
    this.outfitAttempts = const [],
  });

  VirtualTryOnState copyWith({
    bool? isLoading,
    String? error,
    TryOnSession? currentSession,
    List<QuickOutfitSuggestion>? outfitSuggestions,
    List<TryOnFeature>? availableFeatures,
    TryOnPreferences? userPreferences,
    ViewMode? currentViewMode,
    int? selectedOutfitIndex,
    bool? isProcessing,
    double? processingProgress,
    Map<String, dynamic>? processingStatus,
    List<TryOnOutfitAttempt>? outfitAttempts,
  }) {
    return VirtualTryOnState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentSession: currentSession ?? this.currentSession,
      outfitSuggestions: outfitSuggestions ?? this.outfitSuggestions,
      availableFeatures: availableFeatures ?? this.availableFeatures,
      userPreferences: userPreferences ?? this.userPreferences,
      currentViewMode: currentViewMode ?? this.currentViewMode,
      selectedOutfitIndex: selectedOutfitIndex ?? this.selectedOutfitIndex,
      isProcessing: isProcessing ?? this.isProcessing,
      processingProgress: processingProgress ?? this.processingProgress,
      processingStatus: processingStatus ?? this.processingStatus,
      outfitAttempts: outfitAttempts ?? this.outfitAttempts,
    );
  }
}

class VirtualTryOnViewModel extends StateNotifier<VirtualTryOnState> {
  VirtualTryOnViewModel() : super(const VirtualTryOnState()) {
    _initialize();
  }

  /// Initialize the try-on screen
  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Load dashboard data
      await loadDashboardData();

      // Create a new session
      await createNewSession();

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to initialize try-on: $e',
      );
    }
  }

  /// Load dashboard data including suggestions and features
  Future<void> loadDashboardData() async {
    try {
      // Load multiple data sources in parallel
      final results = await Future.wait([
        MLAPIService.getTryOnSuggestions(limit: 3),
        MLAPIService.getTryOnFeatures(),
        MLAPIService.getTryOnPreferences(),
      ]);

      final suggestions =
          (results[0] as List<Map<String, dynamic>>)
              .map((json) => QuickOutfitSuggestion.fromJson(json))
              .toList();

      final features =
          (results[1] as List<Map<String, dynamic>>)
              .map((json) => TryOnFeature.fromJson(json))
              .toList();

      final preferencesData = results[2] as Map<String, dynamic>;
      final preferences = TryOnPreferences.fromJson(preferencesData);

      state = state.copyWith(
        outfitSuggestions: suggestions,
        availableFeatures: features,
        userPreferences: preferences,
        currentViewMode: preferences.defaultViewMode,
      );
    } catch (e) {
      debugPrint('Failed to load dashboard data: $e');
      // Don't set error state for non-critical data
    }
  }

  /// Create a new virtual try-on session
  Future<void> createNewSession() async {
    try {
      final sessionData = await MLAPIService.createTryOnSession(
        sessionName: 'Try-On Session ${DateTime.now().millisecondsSinceEpoch}',
        viewMode: state.currentViewMode.value,
        deviceInfo: await _getDeviceInfo(),
      );

      final session = TryOnSession.fromJson(sessionData);
      state = state.copyWith(currentSession: session);
    } catch (e) {
      throw Exception('Failed to create session: $e');
    }
  }

  /// Get device information for optimal settings
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      // Get available cameras
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      return {
        'camera_count': cameras.length,
        'front_camera_resolution': frontCamera.toString(),
        'platform': Platform.isIOS ? 'ios' : 'android',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'platform': Platform.isIOS ? 'ios' : 'android',
        'error': e.toString(),
      };
    }
  }

  /// Switch between AR and Mirror view modes
  void switchViewMode(ViewMode mode) {
    if (state.currentViewMode != mode) {
      state = state.copyWith(currentViewMode: mode);

      // Update user preferences
      updatePreferences(defaultViewMode: mode);
    }
  }

  /// Select an outfit suggestion
  void selectOutfit(int index) {
    if (index >= 0 && index < state.outfitSuggestions.length) {
      state = state.copyWith(selectedOutfitIndex: index);
    }
  }

  /// Toggle a try-on feature
  Future<void> toggleFeature(String featureId, bool enabled) async {
    final currentFeatures = state.userPreferences?.enabledFeatures ?? {};
    final updatedFeatures = Map<String, bool>.from(currentFeatures);
    updatedFeatures[featureId] = enabled;

    // Update locally first for immediate UI feedback
    final now = DateTime.now();
    final updatedPrefs =
        state.userPreferences ??
        TryOnPreferences(
          id: 0,
          userId: 0,
          defaultViewMode: ViewMode.ar,
          autoSaveResults: true,
          shareAnonymously: false,
          enabledFeatures: const {},
          processingQuality: ProcessingQuality.high,
          maxProcessingTime: 30,
          storeImages: true,
          allowAnalytics: true,
          createdAt: now,
        );

    // Update features list
    final updatedFeaturesList =
        state.availableFeatures.map((feature) {
          if (feature.id == featureId) {
            return feature.copyWith(enabled: enabled);
          }
          return feature;
        }).toList();

    state = state.copyWith(availableFeatures: updatedFeaturesList);

    // Update preferences on backend
    try {
      await updatePreferences(enabledFeatures: updatedFeatures);
    } catch (e) {
      debugPrint('Failed to update feature preference: $e');
      // Revert the change if backend update fails
      final revertedFeatures =
          state.availableFeatures.map((feature) {
            if (feature.id == featureId) {
              return feature.copyWith(enabled: !enabled);
            }
            return feature;
          }).toList();

      state = state.copyWith(availableFeatures: revertedFeatures);
    }
  }

  /// Update user preferences
  Future<void> updatePreferences({
    ViewMode? defaultViewMode,
    bool? autoSaveResults,
    bool? shareAnonymously,
    Map<String, bool>? enabledFeatures,
    ProcessingQuality? processingQuality,
    int? maxProcessingTime,
    bool? storeImages,
    bool? allowAnalytics,
  }) async {
    try {
      final updatedPrefs = await MLAPIService.updateTryOnPreferences(
        defaultViewMode: defaultViewMode?.value,
        autoSaveResults: autoSaveResults,
        shareAnonymously: shareAnonymously,
        enabledFeatures: enabledFeatures,
        processingQuality: processingQuality?.value,
        maxProcessingTime: maxProcessingTime,
        storeImages: storeImages,
        allowAnalytics: allowAnalytics,
      );

      final preferences = TryOnPreferences.fromJson(updatedPrefs);
      state = state.copyWith(userPreferences: preferences);
    } catch (e) {
      debugPrint('Failed to update preferences: $e');
    }
  }

  /// Start virtual try-on process
  Future<void> startTryOn({List<int>? userImageBytes}) async {
    if (state.currentSession == null) {
      await createNewSession();
    }

    if (state.currentSession == null) {
      state = state.copyWith(error: 'No active session');
      return;
    }

    final selectedOutfit = state.outfitSuggestions[state.selectedOutfitIndex];

    try {
      state = state.copyWith(
        isProcessing: true,
        processingProgress: 0.0,
        error: null,
      );

      // Add outfit to session
      final clothingItems =
          selectedOutfit.items.asMap().entries.map((entry) {
            return {
              'id': 'item_${entry.key}',
              'name': entry.value,
              'category': 'clothing',
              'image_url':
                  'https://example.com/${entry.value.toLowerCase().replaceAll(' ', '_')}.jpg',
            };
          }).toList();

      final outfitAttempt = await MLAPIService.addOutfitToSession(
        sessionId: state.currentSession!.id,
        outfitName: selectedOutfit.name,
        occasion: selectedOutfit.occasion,
        clothingItems: clothingItems,
      );

      final attempt = TryOnOutfitAttempt.fromJson(outfitAttempt);

      // Start processing
      await MLAPIService.processOutfitTryOn(
        sessionId: state.currentSession!.id,
        attemptId: attempt.id,
        imageBytes: userImageBytes,
      );

      // Monitor processing status
      await _monitorProcessing(state.currentSession!.id, attempt.id);
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: 'Try-on failed: $e');
    }
  }

  /// Monitor processing status with periodic updates
  Future<void> _monitorProcessing(String sessionId, String attemptId) async {
    const maxAttempts = 60; // 60 seconds max
    int attempts = 0;

    while (attempts < maxAttempts && state.isProcessing) {
      try {
        await Future.delayed(const Duration(seconds: 1));

        final status = await MLAPIService.getTryOnProcessingStatus(
          sessionId: sessionId,
          attemptId: attemptId,
        );

        final processingStatus = TryOnProcessingStatus.fromJson(status);

        state = state.copyWith(
          processingProgress: processingStatus.progress,
          processingStatus: status,
        );

        if (processingStatus.status == TryOnStatus.completed) {
          state = state.copyWith(isProcessing: false, processingProgress: 1.0);

          // Refresh session data to get results
          await _refreshSessionData();
          break;
        } else if (processingStatus.status == TryOnStatus.failed) {
          state = state.copyWith(
            isProcessing: false,
            error: processingStatus.errorMessage ?? 'Processing failed',
          );
          break;
        }

        attempts++;
      } catch (e) {
        debugPrint('Error monitoring processing: $e');
        attempts++;
      }
    }

    if (attempts >= maxAttempts && state.isProcessing) {
      state = state.copyWith(isProcessing: false, error: 'Processing timeout');
    }
  }

  /// Refresh session data to get latest results
  Future<void> _refreshSessionData() async {
    if (state.currentSession == null) return;

    try {
      // This would call a get session endpoint to refresh data
      // For now, we'll simulate getting the updated session
      debugPrint('Try-on completed successfully');
    } catch (e) {
      debugPrint('Failed to refresh session data: $e');
    }
  }

  /// Rate the current try-on result
  Future<void> rateResult({
    required int rating,
    bool isFavorite = false,
  }) async {
    if (state.currentSession == null || state.outfitAttempts.isEmpty) {
      return;
    }

    try {
      final latestAttempt = state.outfitAttempts.last;
      await MLAPIService.rateOutfitAttempt(
        sessionId: state.currentSession!.id,
        attemptId: latestAttempt.id,
        rating: rating,
        isFavorite: isFavorite,
      );

      // Update local state
      final updatedAttempts =
          state.outfitAttempts.map((attempt) {
            if (attempt.id == latestAttempt.id) {
              return TryOnOutfitAttempt(
                id: attempt.id,
                sessionId: attempt.sessionId,
                outfitName: attempt.outfitName,
                occasion: attempt.occasion,
                clothingItems: attempt.clothingItems,
                confidenceScore: attempt.confidenceScore,
                fitAnalysis: attempt.fitAnalysis,
                colorAnalysis: attempt.colorAnalysis,
                styleScore: attempt.styleScore,
                userRating: rating,
                isFavorite: isFavorite,
                isShared: attempt.isShared,
                processingTimeMs: attempt.processingTimeMs,
                resultImageUrl: attempt.resultImageUrl,
                createdAt: attempt.createdAt,
                updatedAt: DateTime.now(),
              );
            }
            return attempt;
          }).toList();

      state = state.copyWith(outfitAttempts: updatedAttempts);
    } catch (e) {
      debugPrint('Failed to rate result: $e');
    }
  }

  /// Share the try-on result
  Future<String?> shareResult() async {
    if (state.currentSession == null) return null;

    try {
      final shareResult = await MLAPIService.shareTryOnSession(
        sessionId: state.currentSession!.id,
        shareOptions: {'include_attempts': true, 'include_preferences': false},
      );

      return shareResult['share_link'] as String?;
    } catch (e) {
      debugPrint('Failed to share result: $e');
      return null;
    }
  }

  /// Clear any error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Reset the try-on state
  void reset() {
    state = const VirtualTryOnState();
    _initialize();
  }

  /// Get current outfit suggestion
  QuickOutfitSuggestion? get currentOutfit {
    if (state.outfitSuggestions.isEmpty) return null;
    return state.outfitSuggestions[state.selectedOutfitIndex];
  }

  /// Check if a feature is enabled
  bool isFeatureEnabled(String featureId) {
    return state.userPreferences?.enabledFeatures[featureId] ?? false;
  }

  /// Get confidence score for current attempt
  double? get currentConfidenceScore {
    if (state.outfitAttempts.isEmpty) return null;
    return state.outfitAttempts.last.confidenceScore;
  }
}

// Provider for the VirtualTryOnViewModel
final virtualTryOnViewModelProvider =
    StateNotifierProvider<VirtualTryOnViewModel, VirtualTryOnState>(
      (ref) => VirtualTryOnViewModel(),
    );
