// lib/viewmodels/nearby_viewmodel.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitsyncgemini/models/nearby_model.dart';

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
      // Mock nearby people - replace with actual implementation
      final nearbyPeople = [
        const NearbyPerson(
          id: '1',
          name: 'Jessica Chen',
          avatar: 'JC',
          distance: '0.3 mi',
          style: 'Minimalist',
          mutualConnections: 5,
          recentOutfit: 'https://picsum.photos/200/200?random=1',
          isOnline: true,
        ),
        const NearbyPerson(
          id: '2',
          name: 'Maya Patel',
          avatar: 'MP',
          distance: '0.8 mi',
          style: 'Bohemian',
          mutualConnections: 12,
          recentOutfit: 'https://picsum.photos/200/200?random=2',
          isOnline: true,
        ),
        const NearbyPerson(
          id: '3',
          name: 'Alex Rivera',
          avatar: 'AR',
          distance: '1.2 mi',
          style: 'Professional',
          mutualConnections: 3,
          recentOutfit: 'https://picsum.photos/200/200?random=3',
          isOnline: false,
        ),
      ];

      state = state.copyWith(nearbyPeople: nearbyPeople);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _loadNearbyEvents() async {
    try {
      // Mock nearby events - replace with actual implementation
      final nearbyEvents = [
        const NearbyEvent(
          id: '1',
          title: 'Style Swap Meet',
          location: 'Central Park',
          distance: '0.5 mi',
          date: 'Today, 3:00 PM',
          attendees: 24,
          image: 'https://picsum.photos/400/300?random=4',
          category: 'Community',
        ),
        const NearbyEvent(
          id: '2',
          title: 'Vintage Fashion Market',
          location: 'Brooklyn Flea',
          distance: '2.1 mi',
          date: 'Tomorrow, 10:00 AM',
          attendees: 156,
          image: 'https://picsum.photos/400/300?random=5',
          category: 'Shopping',
        ),
      ];

      state = state.copyWith(nearbyEvents: nearbyEvents);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _loadHotspots() async {
    try {
      // Mock hotspots - replace with actual implementation
      final hotspots = [
        const NearbyHotspot(
          id: '1',
          name: 'SoHo District',
          type: 'Shopping Area',
          distance: '1.8 mi',
          popularStyles: ['Minimalist', 'Professional'],
          rating: 4.8,
          checkIns: 342,
        ),
        const NearbyHotspot(
          id: '2',
          name: 'Williamsburg',
          type: 'Creative Hub',
          distance: '3.2 mi',
          popularStyles: ['Bohemian', 'Eclectic'],
          rating: 4.6,
          checkIns: 198,
        ),
      ];

      state = state.copyWith(hotspots: hotspots);
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
