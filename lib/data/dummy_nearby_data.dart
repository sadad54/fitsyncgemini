// lib/data/dummy_nearby_data.dart
// This file contains dummy data for the nearby screen
// Easy to replace with real API data when backend is ready

import 'package:fitsyncgemini/models/nearby_model.dart';

class DummyNearbyData {
  static LocationInfo getDummyLocation() {
    return const LocationInfo(
      city: 'New York',
      state: 'NY',
      country: 'USA',
      isLive: false, // Set to false to use dummy data
      latitude: 40.7128,
      longitude: -74.0060,
    );
  }

  static List<NearbyPerson> getDummyPeople() {
    return [
      const NearbyPerson(
        id: 'person_1',
        name: 'Alex Chen',
        avatar: 'https://api.dicebear.com/7.x/avataaars/png?seed=alex',
        distance: '0.3 km',
        style: 'Minimalist',
        mutualConnections: 5,
        recentOutfit: 'Black turtleneck, dark jeans',
        isOnline: true,
      ),
      const NearbyPerson(
        id: 'person_2',
        name: 'Jamie Rodriguez',
        avatar: 'https://api.dicebear.com/7.x/avataaars/png?seed=jamie',
        distance: '0.8 km',
        style: 'Streetwear',
        mutualConnections: 2,
        recentOutfit: 'Oversized hoodie, cargo pants',
        isOnline: false,
      ),
      const NearbyPerson(
        id: 'person_3',
        name: 'Sarah Kim',
        avatar: 'https://api.dicebear.com/7.x/avataaars/png?seed=sarah',
        distance: '1.2 km',
        style: 'Boho',
        mutualConnections: 8,
        recentOutfit: 'Flowy dress, sandals',
        isOnline: true,
      ),
    ];
  }

  static List<NearbyEvent> getDummyEvents() {
    return [
      const NearbyEvent(
        id: 'event_1',
        title: 'Sustainable Fashion Show',
        location: 'Fashion District',
        distance: '1.2 km',
        date: '2024-02-15T18:00:00Z',
        attendees: 85,
        image:
            'https://via.placeholder.com/300x200/FF6B9D/FFFFFF?text=Fashion+Show',
        category: 'Fashion Show',
      ),
      const NearbyEvent(
        id: 'event_2',
        title: 'Vintage Pop-up Market',
        location: 'Downtown Plaza',
        distance: '2.1 km',
        date: '2024-02-18T12:00:00Z',
        attendees: 120,
        image:
            'https://via.placeholder.com/300x200/4ECDC4/FFFFFF?text=Vintage+Market',
        category: 'Shopping',
      ),
      const NearbyEvent(
        id: 'event_3',
        title: 'Street Style Photography',
        location: 'Brooklyn Bridge',
        distance: '3.5 km',
        date: '2024-02-20T14:00:00Z',
        attendees: 45,
        image:
            'https://via.placeholder.com/300x200/9B59B6/FFFFFF?text=Photography',
        category: 'Photography',
      ),
    ];
  }

  static List<NearbyHotspot> getDummyHotspots() {
    return [
      const NearbyHotspot(
        id: 'hotspot_1',
        name: 'Urban Style Gallery',
        type: 'Boutique',
        distance: '0.7 km',
        popularStyles: ['streetwear', 'contemporary'],
        rating: 4.8,
        checkIns: 156,
      ),
      const NearbyHotspot(
        id: 'hotspot_2',
        name: 'Minimalist Corner',
        type: 'Concept Store',
        distance: '1.5 km',
        popularStyles: ['minimalist', 'sustainable'],
        rating: 4.6,
        checkIns: 89,
      ),
      const NearbyHotspot(
        id: 'hotspot_3',
        name: 'Vintage Haven',
        type: 'Thrift Store',
        distance: '2.3 km',
        popularStyles: ['vintage', 'retro'],
        rating: 4.9,
        checkIns: 234,
      ),
    ];
  }

  // Map data format for easy replacement
  static Map<String, dynamic> getDummyMapData() {
    final userLat = 40.7128;
    final userLng = -74.0060;

    return {
      'people': [
        {
          'id': 'person_1',
          'name': 'Alex Chen',
          'avatar': 'https://api.dicebear.com/7.x/avataaars/png?seed=alex',
          'distance': '0.3 km',
          'style': 'Minimalist',
          'mutualConnections': 5,
          'recentOutfit': 'Black turtleneck, dark jeans',
          'isOnline': true,
          'latitude': userLat + 0.002,
          'longitude': userLng + 0.001,
        },
        {
          'id': 'person_2',
          'name': 'Jamie Rodriguez',
          'avatar': 'https://api.dicebear.com/7.x/avataaars/png?seed=jamie',
          'distance': '0.8 km',
          'style': 'Streetwear',
          'mutualConnections': 2,
          'recentOutfit': 'Oversized hoodie, cargo pants',
          'isOnline': false,
          'latitude': userLat - 0.003,
          'longitude': userLng + 0.004,
        },
        {
          'id': 'person_3',
          'name': 'Sarah Kim',
          'avatar': 'https://api.dicebear.com/7.x/avataaars/png?seed=sarah',
          'distance': '1.2 km',
          'style': 'Boho',
          'mutualConnections': 8,
          'recentOutfit': 'Flowy dress, sandals',
          'isOnline': true,
          'latitude': userLat + 0.005,
          'longitude': userLng - 0.003,
        },
      ],
      'events': [
        {
          'id': 'event_1',
          'title': 'Sustainable Fashion Show',
          'location': 'Fashion District',
          'distance': '1.2 km',
          'date': '2024-02-15T18:00:00Z',
          'attendees': 85,
          'image':
              'https://via.placeholder.com/300x200/FF6B9D/FFFFFF?text=Fashion+Show',
          'category': 'Fashion Show',
          'latitude': userLat + 0.005,
          'longitude': userLng - 0.002,
        },
        {
          'id': 'event_2',
          'title': 'Vintage Pop-up Market',
          'location': 'Downtown Plaza',
          'distance': '2.1 km',
          'date': '2024-02-18T12:00:00Z',
          'attendees': 120,
          'image':
              'https://via.placeholder.com/300x200/4ECDC4/FFFFFF?text=Vintage+Market',
          'category': 'Shopping',
          'latitude': userLat - 0.008,
          'longitude': userLng - 0.006,
        },
        {
          'id': 'event_3',
          'title': 'Street Style Photography',
          'location': 'Brooklyn Bridge',
          'distance': '3.5 km',
          'date': '2024-02-20T14:00:00Z',
          'attendees': 45,
          'image':
              'https://via.placeholder.com/300x200/9B59B6/FFFFFF?text=Photography',
          'category': 'Photography',
          'latitude': userLat + 0.010,
          'longitude': userLng + 0.008,
        },
      ],
      'hotspots': [
        {
          'id': 'hotspot_1',
          'name': 'Urban Style Gallery',
          'type': 'Boutique',
          'distance': '0.7 km',
          'popularStyles': ['streetwear', 'contemporary'],
          'rating': 4.8,
          'checkIns': 156,
          'latitude': userLat - 0.001,
          'longitude': userLng + 0.003,
        },
        {
          'id': 'hotspot_2',
          'name': 'Minimalist Corner',
          'type': 'Concept Store',
          'distance': '1.5 km',
          'popularStyles': ['minimalist', 'sustainable'],
          'rating': 4.6,
          'checkIns': 89,
          'latitude': userLat + 0.006,
          'longitude': userLng + 0.007,
        },
        {
          'id': 'hotspot_3',
          'name': 'Vintage Haven',
          'type': 'Thrift Store',
          'distance': '2.3 km',
          'popularStyles': ['vintage', 'retro'],
          'rating': 4.9,
          'checkIns': 234,
          'latitude': userLat - 0.012,
          'longitude': userLng - 0.009,
        },
      ],
    };
  }
}
