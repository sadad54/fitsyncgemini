// lib/models/settings_model.dart
import 'package:flutter/material.dart';

class SettingsModel {
  final AppSettings appSettings;
  final NotificationSettings notificationSettings;
  final PrivacySettings privacySettings;
  final bool isLoading;
  final String? error;

  const SettingsModel({
    required this.appSettings,
    required this.notificationSettings,
    required this.privacySettings,
    this.isLoading = false,
    this.error,
  });

  SettingsModel copyWith({
    AppSettings? appSettings,
    NotificationSettings? notificationSettings,
    PrivacySettings? privacySettings,
    bool? isLoading,
    String? error,
  }) {
    return SettingsModel(
      appSettings: appSettings ?? this.appSettings,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      privacySettings: privacySettings ?? this.privacySettings,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class AppSettings {
  final ThemeMode themeMode;
  final String language;
  final bool autoSave;
  final bool analyticsEnabled;
  final String appVersion;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.language = 'en',
    this.autoSave = true,
    this.analyticsEnabled = true,
    this.appVersion = '1.0.0',
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? language,
    bool? autoSave,
    bool? analyticsEnabled,
    String? appVersion,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      autoSave: autoSave ?? this.autoSave,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
      appVersion: appVersion ?? this.appVersion,
    );
  }
}

class NotificationSettings {
  final bool outfitSuggestions;
  final bool trendAlerts;
  final bool nearbyActivity;
  final bool weeklyInsights;
  final bool pushNotifications;
  final bool emailNotifications;

  const NotificationSettings({
    this.outfitSuggestions = true,
    this.trendAlerts = true,
    this.nearbyActivity = true,
    this.weeklyInsights = true,
    this.pushNotifications = true,
    this.emailNotifications = false,
  });

  NotificationSettings copyWith({
    bool? outfitSuggestions,
    bool? trendAlerts,
    bool? nearbyActivity,
    bool? weeklyInsights,
    bool? pushNotifications,
    bool? emailNotifications,
  }) {
    return NotificationSettings(
      outfitSuggestions: outfitSuggestions ?? this.outfitSuggestions,
      trendAlerts: trendAlerts ?? this.trendAlerts,
      nearbyActivity: nearbyActivity ?? this.nearbyActivity,
      weeklyInsights: weeklyInsights ?? this.weeklyInsights,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
    );
  }
}

class PrivacySettings {
  final bool profileVisible;
  final bool locationSharing;
  final bool outfitSharing;
  final bool dataCollection;
  final bool thirdPartySharing;

  const PrivacySettings({
    this.profileVisible = true,
    this.locationSharing = true,
    this.outfitSharing = true,
    this.dataCollection = true,
    this.thirdPartySharing = false,
  });

  PrivacySettings copyWith({
    bool? profileVisible,
    bool? locationSharing,
    bool? outfitSharing,
    bool? dataCollection,
    bool? thirdPartySharing,
  }) {
    return PrivacySettings(
      profileVisible: profileVisible ?? this.profileVisible,
      locationSharing: locationSharing ?? this.locationSharing,
      outfitSharing: outfitSharing ?? this.outfitSharing,
      dataCollection: dataCollection ?? this.dataCollection,
      thirdPartySharing: thirdPartySharing ?? this.thirdPartySharing,
    );
  }
} 