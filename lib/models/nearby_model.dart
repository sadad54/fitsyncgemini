// lib/models/nearby_model.dart
import 'package:flutter/material.dart';

class NearbyModel {
  final String activeTab;
  final LocationInfo locationInfo;
  final List<NearbyPerson> nearbyPeople;
  final List<NearbyEvent> nearbyEvents;
  final List<NearbyHotspot> hotspots;
  final bool isLoading;
  final String? error;

  const NearbyModel({
    this.activeTab = 'people',
    required this.locationInfo,
    this.nearbyPeople = const [],
    this.nearbyEvents = const [],
    this.hotspots = const [],
    this.isLoading = false,
    this.error,
  });

  NearbyModel copyWith({
    String? activeTab,
    LocationInfo? locationInfo,
    List<NearbyPerson>? nearbyPeople,
    List<NearbyEvent>? nearbyEvents,
    List<NearbyHotspot>? hotspots,
    bool? isLoading,
    String? error,
  }) {
    return NearbyModel(
      activeTab: activeTab ?? this.activeTab,
      locationInfo: locationInfo ?? this.locationInfo,
      nearbyPeople: nearbyPeople ?? this.nearbyPeople,
      nearbyEvents: nearbyEvents ?? this.nearbyEvents,
      hotspots: hotspots ?? this.hotspots,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class LocationInfo {
  final String city;
  final String state;
  final String country;
  final bool isLive;
  final double latitude;
  final double longitude;

  const LocationInfo({
    required this.city,
    required this.state,
    required this.country,
    this.isLive = true,
    required this.latitude,
    required this.longitude,
  });

  String get fullLocation => '$city, $state';
}

class NearbyPerson {
  final String id;
  final String name;
  final String avatar;
  final String distance;
  final String style;
  final int mutualConnections;
  final String recentOutfit;
  final bool isOnline;

  const NearbyPerson({
    required this.id,
    required this.name,
    required this.avatar,
    required this.distance,
    required this.style,
    required this.mutualConnections,
    required this.recentOutfit,
    this.isOnline = false,
  });
}

class NearbyEvent {
  final String id;
  final String title;
  final String location;
  final String distance;
  final String date;
  final int attendees;
  final String image;
  final String category;

  const NearbyEvent({
    required this.id,
    required this.title,
    required this.location,
    required this.distance,
    required this.date,
    required this.attendees,
    required this.image,
    required this.category,
  });
}

class NearbyHotspot {
  final String id;
  final String name;
  final String type;
  final String distance;
  final List<String> popularStyles;
  final double rating;
  final int checkIns;

  const NearbyHotspot({
    required this.id,
    required this.name,
    required this.type,
    required this.distance,
    required this.popularStyles,
    required this.rating,
    required this.checkIns,
  });
}
