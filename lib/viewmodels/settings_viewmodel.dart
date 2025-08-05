// lib/viewmodels/settings_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitsyncgemini/models/settings_model.dart';

class SettingsViewModel extends StateNotifier<SettingsModel> {
  SettingsViewModel()
    : super(
        const SettingsModel(
          appSettings: AppSettings(),
          notificationSettings: NotificationSettings(),
          privacySettings: PrivacySettings(),
        ),
      ) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    state = state.copyWith(isLoading: true);

    try {
      // Mock settings loading - replace with actual implementation
      await Future.delayed(const Duration(seconds: 1));

      // Mock settings - replace with actual settings storage
      const appSettings = AppSettings(
        themeMode: ThemeMode.system,
        language: 'en',
        autoSave: true,
        analyticsEnabled: true,
        appVersion: '1.0.0',
      );

      const notificationSettings = NotificationSettings(
        outfitSuggestions: true,
        trendAlerts: true,
        nearbyActivity: true,
        weeklyInsights: true,
        pushNotifications: true,
        emailNotifications: false,
      );

      const privacySettings = PrivacySettings(
        profileVisible: true,
        locationSharing: true,
        outfitSharing: true,
        dataCollection: true,
        thirdPartySharing: false,
      );

      state = state.copyWith(
        appSettings: appSettings,
        notificationSettings: notificationSettings,
        privacySettings: privacySettings,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateThemeMode(ThemeMode themeMode) async {
    try {
      final updatedAppSettings = state.appSettings.copyWith(
        themeMode: themeMode,
      );
      state = state.copyWith(appSettings: updatedAppSettings);

      // Save to persistent storage
      await _saveSettings();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateLanguage(String language) async {
    try {
      final updatedAppSettings = state.appSettings.copyWith(language: language);
      state = state.copyWith(appSettings: updatedAppSettings);

      // Save to persistent storage
      await _saveSettings();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> toggleAutoSave() async {
    try {
      final updatedAppSettings = state.appSettings.copyWith(
        autoSave: !state.appSettings.autoSave,
      );
      state = state.copyWith(appSettings: updatedAppSettings);

      // Save to persistent storage
      await _saveSettings();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> toggleAnalytics() async {
    try {
      final updatedAppSettings = state.appSettings.copyWith(
        analyticsEnabled: !state.appSettings.analyticsEnabled,
      );
      state = state.copyWith(appSettings: updatedAppSettings);

      // Save to persistent storage
      await _saveSettings();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateNotificationSetting(String setting, bool value) async {
    try {
      NotificationSettings updatedNotificationSettings;

      switch (setting) {
        case 'outfitSuggestions':
          updatedNotificationSettings = state.notificationSettings.copyWith(
            outfitSuggestions: value,
          );
          break;
        case 'trendAlerts':
          updatedNotificationSettings = state.notificationSettings.copyWith(
            trendAlerts: value,
          );
          break;
        case 'nearbyActivity':
          updatedNotificationSettings = state.notificationSettings.copyWith(
            nearbyActivity: value,
          );
          break;
        case 'weeklyInsights':
          updatedNotificationSettings = state.notificationSettings.copyWith(
            weeklyInsights: value,
          );
          break;
        case 'pushNotifications':
          updatedNotificationSettings = state.notificationSettings.copyWith(
            pushNotifications: value,
          );
          break;
        case 'emailNotifications':
          updatedNotificationSettings = state.notificationSettings.copyWith(
            emailNotifications: value,
          );
          break;
        default:
          throw Exception('Unknown notification setting: $setting');
      }

      state = state.copyWith(notificationSettings: updatedNotificationSettings);

      // Save to persistent storage
      await _saveSettings();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updatePrivacySetting(String setting, bool value) async {
    try {
      PrivacySettings updatedPrivacySettings;

      switch (setting) {
        case 'profileVisible':
          updatedPrivacySettings = state.privacySettings.copyWith(
            profileVisible: value,
          );
          break;
        case 'locationSharing':
          updatedPrivacySettings = state.privacySettings.copyWith(
            locationSharing: value,
          );
          break;
        case 'outfitSharing':
          updatedPrivacySettings = state.privacySettings.copyWith(
            outfitSharing: value,
          );
          break;
        case 'dataCollection':
          updatedPrivacySettings = state.privacySettings.copyWith(
            dataCollection: value,
          );
          break;
        case 'thirdPartySharing':
          updatedPrivacySettings = state.privacySettings.copyWith(
            thirdPartySharing: value,
          );
          break;
        default:
          throw Exception('Unknown privacy setting: $setting');
      }

      state = state.copyWith(privacySettings: updatedPrivacySettings);

      // Save to persistent storage
      await _saveSettings();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> _saveSettings() async {
    try {
      // Mock settings save - replace with actual implementation
      await Future.delayed(const Duration(milliseconds: 500));

      // Here you would save to SharedPreferences, secure storage, or backend
      // For now, just simulate the save operation
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> resetToDefaults() async {
    try {
      state = state.copyWith(isLoading: true);

      // Reset to default settings
      const defaultAppSettings = AppSettings();
      const defaultNotificationSettings = NotificationSettings();
      const defaultPrivacySettings = PrivacySettings();

      state = state.copyWith(
        appSettings: defaultAppSettings,
        notificationSettings: defaultNotificationSettings,
        privacySettings: defaultPrivacySettings,
        isLoading: false,
      );

      // Save to persistent storage
      await _saveSettings();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> exportSettings() async {
    try {
      // Mock settings export - replace with actual implementation
      await Future.delayed(const Duration(seconds: 1));

      // Here you would export settings to a file or cloud storage
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> importSettings() async {
    try {
      state = state.copyWith(isLoading: true);

      // Mock settings import - replace with actual implementation
      await Future.delayed(const Duration(seconds: 1));

      // Here you would import settings from a file or cloud storage

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
final settingsViewModelProvider =
    StateNotifierProvider<SettingsViewModel, SettingsModel>(
      (ref) => SettingsViewModel(),
    );
