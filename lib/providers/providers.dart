// lib/providers/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitsyncgemini/services/firestore_service.dart';
import 'package:fitsyncgemini/services/ml_service.dart';
import 'package:fitsyncgemini/services/storage_service.dart';
import 'package:fitsyncgemini/services/auth_service.dart';
import 'package:fitsyncgemini/models/dashboard_model.dart';
import 'package:fitsyncgemini/models/closet_model.dart';
import 'package:fitsyncgemini/models/outfit_suggestions_model.dart';
import 'package:fitsyncgemini/models/trends_model.dart';
import 'package:fitsyncgemini/models/try_on_model.dart';
import 'package:fitsyncgemini/models/nearby_model.dart';
import 'package:fitsyncgemini/models/settings_model.dart';
import 'package:fitsyncgemini/viewmodels/dashboard_viewmodel.dart';
import 'package:fitsyncgemini/viewmodels/closet_viewmodel.dart';
import 'package:fitsyncgemini/viewmodels/outfit_suggestions_viewmodel.dart';
import 'package:fitsyncgemini/viewmodels/trends_viewmodel.dart';
import 'package:fitsyncgemini/viewmodels/try_on_viewmodel.dart';
import 'package:fitsyncgemini/viewmodels/nearby_viewmodel.dart';
import 'package:fitsyncgemini/viewmodels/settings_viewmodel.dart';
import 'package:fitsyncgemini/viewmodels/auth_viewmodel.dart';

// Service Providers
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

final mlServiceProvider = Provider<MLService>((ref) {
  return MLService();
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// ViewModel Providers
final dashboardViewModelProvider =
    StateNotifierProvider<DashboardViewModel, DashboardModel>((ref) {
      final firestoreService = ref.watch(firestoreServiceProvider);
      final mlService = ref.watch(mlServiceProvider);
      return DashboardViewModel(firestoreService, mlService);
    });

final closetViewModelProvider =
    StateNotifierProvider<ClosetViewModel, ClosetModel>((ref) {
      final firestoreService = ref.watch(firestoreServiceProvider);
      return ClosetViewModel(firestoreService);
    });

final outfitSuggestionsViewModelProvider =
    StateNotifierProvider<OutfitSuggestionsViewModel, OutfitSuggestionsModel>((
      ref,
    ) {
      final mlService = ref.watch(mlServiceProvider);
      final firestoreService = ref.watch(firestoreServiceProvider);
      return OutfitSuggestionsViewModel(mlService, firestoreService);
    });

final trendsViewModelProvider =
    StateNotifierProvider<TrendsViewModel, TrendsModel>((ref) {
      final mlService = ref.watch(mlServiceProvider);
      return TrendsViewModel(mlService);
    });

final tryOnViewModelProvider =
    StateNotifierProvider<TryOnViewModel, TryOnModel>((ref) {
      final mlService = ref.watch(mlServiceProvider);
      final storageService = ref.watch(storageServiceProvider);
      return TryOnViewModel(mlService, storageService);
    });

final nearbyViewModelProvider =
    StateNotifierProvider<NearbyViewModel, NearbyModel>((ref) {
      return NearbyViewModel();
    });

final settingsViewModelProvider =
    StateNotifierProvider<SettingsViewModel, SettingsModel>((ref) {
      return SettingsViewModel();
    });

// Auth ViewModel Provider
final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>((
  ref,
) {
  return AuthViewModel();
});
