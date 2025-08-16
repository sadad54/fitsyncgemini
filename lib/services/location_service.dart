// lib/services/location_service.dart
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart' as perm;
import 'package:geolocator/geolocator.dart';
import 'package:fitsyncgemini/models/nearby_model.dart';

class LocationService {
  final loc.Location _location = loc.Location();

  /// Get current location with proper permission handling
  Future<LocationInfo?> getCurrentLocation() async {
    try {
      // Check and request permissions
      final permission = await perm.Permission.location.request();
      if (permission != perm.PermissionStatus.granted) {
        throw Exception('Location permission denied');
      }

      // Check if location service is enabled
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          throw Exception('Location service disabled');
        }
      }

      // Get current location
      final locationData = await _location.getLocation();

      // Convert to your LocationInfo model
      return LocationInfo(
        city: 'Current Location', // You can reverse geocode this
        state: '',
        country: '',
        latitude: locationData.latitude!,
        longitude: locationData.longitude!,
        isLive: true,
        fullLocation: 'Current Location', // Add this field
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  /// Get current location using Geolocator (alternative implementation)
  Future<LocationInfo?> getCurrentLocationWithGeolocator() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return LocationInfo(
        city: 'Current Location',
        state: '',
        country: '',
        latitude: position.latitude,
        longitude: position.longitude,
        isLive: true,
        fullLocation:
            'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}',
      );
    } catch (e) {
      print('Error getting location with Geolocator: $e');
      return null;
    }
  }

  /// Calculate distance between two coordinates using Haversine formula
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) /
        1000; // Convert to kilometers
  }

  /// Check if location permissions are granted
  Future<bool> hasLocationPermission() async {
    final permission = await perm.Permission.location.status;
    return permission == perm.PermissionStatus.granted;
  }

  /// Open app settings for permission management
  Future<void> openLocationSettings() async {
    await perm.openAppSettings();
  }

  /// Get mock location for testing
  LocationInfo getMockLocation() {
    return const LocationInfo(
      city: 'San Francisco',
      state: 'CA',
      country: 'USA',
      latitude: 37.7749,
      longitude: -122.4194,
      isLive: false,
      fullLocation: 'San Francisco, CA, USA',
    );
  }

  /// Listen to location changes
  Stream<LocationInfo?> getLocationStream() async* {
    await for (loc.LocationData locationData in _location.onLocationChanged) {
      yield LocationInfo(
        city: 'Current Location',
        state: '',
        country: '',
        latitude: locationData.latitude!,
        longitude: locationData.longitude!,
        isLive: true,
        fullLocation: 'Live Location',
      );
    }
  }
}
