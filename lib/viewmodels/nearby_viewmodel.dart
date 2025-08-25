// lib/viewmodels/nearby_viewmodel.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitsyncgemini/models/nearby_model.dart';
import 'package:fitsyncgemini/services/backend_api.dart';

class NearbyViewModel extends StateNotifier<NearbyModel> {
  NearbyViewModel()
    : super(
        const NearbyModel(
          locationInfo: LocationInfo(
            city: 'Manhattan',
            state: 'New York',
            country: 'USA',
            latitude: 40.7589,
            longitude: -73.9851,
          ),
        ),
      ) {
    _initializeNearby();
  }

  Future<void> _initializeNearby() async {
    state = state.copyWith(isLoading: true);

    try {
      await Future.wait([
        _loadNearbyPeople(),
        _loadNearbyEvents(),
        _loadHotspots(),
      ]);

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _loadNearbyPeople() async {
    try {
      final loc = state.locationInfo;
      final data = await BackendApi.getNearby(
        lat: loc.latitude,
        lon: loc.longitude,
        radius: 5000,
      );
      final places = (data['places'] as List<dynamic>? ?? []).take(10);
      final mapped =
          places
              .map(
                (p) => NearbyPerson(
                  id: (p['id'] ?? '').toString(),
                  name: p['name']?.toString() ?? 'Place',
                  avatar: (p['name']?.toString() ?? 'P').substring(0, 1),
                  distance: '${(p['distance_km'] ?? 1.0).toString()} km',
                  style: p['category']?.toString() ?? 'Fashion',
                  mutualConnections: 0,
                  recentOutfit: '',
                  isOnline: false,
                ),
              )
              .toList();

      state = state.copyWith(nearbyPeople: mapped);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _loadNearbyEvents() async {
    try {
      // Placeholder: map places as events for now
      final loc = state.locationInfo;
      final data = await BackendApi.getNearby(
        lat: loc.latitude,
        lon: loc.longitude,
        radius: 5000,
      );
      final places = (data['places'] as List<dynamic>? ?? []).take(5);
      final events =
          places
              .map(
                (p) => NearbyEvent(
                  id: (p['id'] ?? '').toString(),
                  title: p['name']?.toString() ?? 'Fashion Event',
                  location: p['address']?.toString() ?? '',
                  distance: '—',
                  date: '',
                  attendees: 0,
                  image: '',
                  category: 'Shopping',
                ),
              )
              .toList();
      state = state.copyWith(nearbyEvents: events);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _loadHotspots() async {
    try {
      final loc = state.locationInfo;
      final data = await BackendApi.getNearby(
        lat: loc.latitude,
        lon: loc.longitude,
        radius: 5000,
      );
      final places = (data['places'] as List<dynamic>? ?? []);
      final hs =
          places
              .map(
                (p) => NearbyHotspot(
                  id: (p['id'] ?? '').toString(),
                  name: p['name']?.toString() ?? 'Shop',
                  type: p['category']?.toString() ?? 'Fashion',
                  distance: '—',
                  popularStyles: const <String>[],
                  rating:
                      (p['rating'] is num)
                          ? (p['rating'] as num).toDouble()
                          : 0.0,
                  checkIns: 0,
                ),
              )
              .toList();
      state = state.copyWith(hotspots: hs);
    } catch (e) {
      // Handle error
    }
  }

  void setActiveTab(String tab) {
    state = state.copyWith(activeTab: tab);
  }

  Future<void> updateLocation(double latitude, double longitude) async {
    try {
      state = state.copyWith(isLoading: true);

      // Mock location update - replace with actual implementation
      await Future.delayed(const Duration(seconds: 1));

      // Mock location info - replace with actual geocoding
      const locationInfo = LocationInfo(
        city: 'Manhattan',
        state: 'New York',
        country: 'USA',
        latitude: 40.7589,
        longitude: -73.9851,
      );

      state = state.copyWith(locationInfo: locationInfo, isLoading: false);

      // Reload nearby data with new location
      await _initializeNearby();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> connectWithPerson(String personId) async {
    try {
      // Mock connection - replace with actual implementation
      await Future.delayed(const Duration(seconds: 1));

      // Update the person's connection status
      final updatedPeople =
          state.nearbyPeople.map((person) {
            if (person.id == personId) {
              // Mock connection success
              return person;
            }
            return person;
          }).toList();

      state = state.copyWith(nearbyPeople: updatedPeople);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> joinEvent(String eventId) async {
    try {
      // Mock event joining - replace with actual implementation
      await Future.delayed(const Duration(seconds: 1));

      // Update event attendees count
      final updatedEvents =
          state.nearbyEvents.map((event) {
            if (event.id == eventId) {
              return NearbyEvent(
                id: event.id,
                title: event.title,
                location: event.location,
                distance: event.distance,
                date: event.date,
                attendees: event.attendees + 1,
                image: event.image,
                category: event.category,
              );
            }
            return event;
          }).toList();

      state = state.copyWith(nearbyEvents: updatedEvents);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> checkInHotspot(String hotspotId) async {
    try {
      // Mock check-in - replace with actual implementation
      await Future.delayed(const Duration(seconds: 1));

      // Update hotspot check-ins count
      final updatedHotspots =
          state.hotspots.map((hotspot) {
            if (hotspot.id == hotspotId) {
              return NearbyHotspot(
                id: hotspot.id,
                name: hotspot.name,
                type: hotspot.type,
                distance: hotspot.distance,
                popularStyles: hotspot.popularStyles,
                rating: hotspot.rating,
                checkIns: hotspot.checkIns + 1,
              );
            }
            return hotspot;
          }).toList();

      state = state.copyWith(hotspots: updatedHotspots);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> refreshNearby() async {
    await _initializeNearby();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final nearbyViewModelProvider =
    StateNotifierProvider<NearbyViewModel, NearbyModel>(
      (ref) => NearbyViewModel(),
    );
