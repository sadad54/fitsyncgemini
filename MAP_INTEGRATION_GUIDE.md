# Google Maps Integration Guide for FitSync

This guide explains how to integrate Google Maps with the nearby screen functionality, showing users, events, and hotspots as map overlays.

## Prerequisites

### 1. Google Maps Setup

1. **Get Google Maps API Key**:
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Create or select a project
   - Enable Google Maps SDK for Android/iOS
   - Create API credentials (API Key)
   - Restrict the key to your app's package name

2. **Add Dependencies**:
   ```yaml
   # pubspec.yaml
   dependencies:
     google_maps_flutter: ^2.5.0
     location: ^5.0.3
     permission_handler: ^11.0.1
   ```

### 2. Platform Configuration

#### Android (android/app/src/main/AndroidManifest.xml)
```xml
<application>
    <!-- Add your Google Maps API key -->
    <meta-data
        android:name="com.google.android.geo.API_KEY"
        android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE" />
    
    <!-- Location permissions -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
</application>
```

#### iOS (ios/Runner/AppDelegate.swift)
```swift
import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY_HERE")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

#### iOS Permissions (ios/Runner/Info.plist)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs access to location to show nearby fashion content.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs access to location to show nearby fashion content.</string>
```

## Implementation Steps

### 1. Location Service

Create a location service to handle user's current location:

```dart
// lib/services/location_service.dart
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  final Location _location = Location();
  
  Future<LocationInfo?> getCurrentLocation() async {
    try {
      // Check and request permissions
      final permission = await Permission.location.request();
      if (permission != PermissionStatus.granted) {
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
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }
}
```

### 2. Update Nearby Screen

Update your nearby screen to use the map widget:

```dart
// lib/screens/nearby/nearby_screen.dart
import 'package:flutter/material.dart';
import 'package:fitsyncgemini/widgets/nearby/nearby_map_widget.dart';
import 'package:fitsyncgemini/services/location_service.dart';
import 'package:fitsyncgemini/models/nearby_model.dart';

class NearbyScreen extends StatefulWidget {
  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  final LocationService _locationService = LocationService();
  LocationInfo? _userLocation;
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }
  
  Future<void> _getUserLocation() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      final location = await _locationService.getCurrentLocation();
      if (location != null) {
        setState(() {
          _userLocation = location;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Unable to get your location';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nearby'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _getUserLocation,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
  
  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text('Error: $_error'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _getUserLocation,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    if (_userLocation == null) {
      return Center(child: Text('Location not available'));
    }
    
    return NearbyMapWidget(
      userLocation: _userLocation!,
      radiusKm: 5.0,
      onPersonTap: () {
        // Handle person tap
        print('Person tapped');
      },
      onEventTap: () {
        // Handle event tap
        print('Event tapped');
      },
      onHotspotTap: () {
        // Handle hotspot tap
        print('Hotspot tapped');
      },
    );
  }
}
```

### 3. Custom Map Markers

Create custom markers for different types of content:

```dart
// lib/utils/map_utils.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;

class MapUtils {
  static Future<BitmapDescriptor> createCustomMarker({
    required String iconPath,
    required int size,
    Color? backgroundColor,
  }) async {
    try {
      final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(pictureRecorder);
      
      // Draw background circle
      if (backgroundColor != null) {
        final Paint backgroundPaint = Paint()..color = backgroundColor;
        canvas.drawCircle(
          Offset(size / 2, size / 2),
          size / 2,
          backgroundPaint,
        );
      }
      
      // Load and draw icon
      final ByteData data = await rootBundle.load(iconPath);
      final ui.Codec codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: (size * 0.6).round(),
        targetHeight: (size * 0.6).round(),
      );
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      
      canvas.drawImage(
        frameInfo.image,
        Offset(size * 0.2, size * 0.2),
        Paint(),
      );
      
      final ui.Picture picture = pictureRecorder.endRecording();
      final ui.Image image = await picture.toImage(size, size);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      
      return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
    } catch (e) {
      // Fallback to default marker
      return BitmapDescriptor.defaultMarker;
    }
  }
  
  static BitmapDescriptor getMarkerForType(String type) {
    switch (type) {
      case 'person':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case 'event':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      case 'hotspot':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      default:
        return BitmapDescriptor.defaultMarker;
    }
  }
}
```

### 4. Map Clustering (For Many Markers)

For handling many markers efficiently, use map clustering:

```dart
// Add to pubspec.yaml
dependencies:
  google_maps_cluster_manager: ^3.0.0+1

// Usage in your map widget
import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart';

class ClusterMapWidget extends StatefulWidget {
  // ... implementation
}

class _ClusterMapWidgetState extends State<ClusterMapWidget> {
  late ClusterManager _manager;
  Set<Marker> markers = Set();
  
  @override
  void initState() {
    _manager = ClusterManager<NearbyItem>(
      items,
      _updateMarkers,
      markerBuilder: _markerBuilder,
    );
    super.initState();
  }
  
  void _updateMarkers(Set<Marker> markers) {
    setState(() {
      this.markers = markers;
    });
  }
  
  Future<Marker> Function(Cluster<NearbyItem>) get _markerBuilder =>
      (cluster) async {
        return Marker(
          markerId: MarkerId(cluster.getId()),
          position: cluster.location,
          onTap: () {
            // Handle cluster tap
          },
          icon: await _getMarkerBitmap(cluster.isMultiple ? 125 : 75,
              text: cluster.isMultiple ? cluster.count.toString() : null),
        );
      };
}
```

## Backend Integration

The backend endpoints are already set up to provide coordinate data:

### API Endpoints Used

1. **Combined Map Data**: `GET /api/v1/ml/nearby/map`
   - Returns people, events, and hotspots with coordinates
   - Single API call for efficiency

2. **Individual Endpoints**:
   - `GET /api/v1/ml/nearby/people`
   - `GET /api/v1/ml/nearby/events`
   - `GET /api/v1/ml/nearby/hotspots`

### Response Format

All nearby endpoints return latitude/longitude coordinates:

```json
{
  "people": [
    {
      "id": "u_19",
      "name": "Leo",
      "latitude": 37.7862,
      "longitude": -122.4028,
      "style": "streetwear",
      "distance": "0.6 km"
    }
  ],
  "events": [
    {
      "id": "ev_77",
      "title": "Fashion Pop-up",
      "latitude": 37.7845,
      "longitude": -122.4073,
      "date": "2025-01-21T18:30:00Z"
    }
  ],
  "hotspots": [
    {
      "id": "hs_12",
      "name": "SoMa Style Hub",
      "latitude": 37.7817,
      "longitude": -122.3969,
      "rating": 4.6
    }
  ]
}
```

## Performance Optimizations

### 1. Caching Strategy

The backend implements caching for nearby data:
- Cache duration: 3 minutes for location-based data
- Rounded coordinates for cache efficiency
- Automatic cache invalidation

### 2. Efficient Data Loading

```dart
// Load data in chunks
Future<void> _loadNearbyData() async {
  // Load high-priority data first (people)
  final people = await MLAPIService.getNearbyPeople(
    lat: userLocation.latitude,
    lng: userLocation.longitude,
    limit: 10,
  );
  
  // Update UI immediately
  setState(() {
    _updatePeopleMarkers(people);
  });
  
  // Load remaining data
  final events = await MLAPIService.getNearbyEvents(/* ... */);
  final hotspots = await MLAPIService.getHotspots(/* ... */);
  
  setState(() {
    _updateEventMarkers(events);
    _updateHotspotMarkers(hotspots);
  });
}
```

### 3. Map Performance

```dart
GoogleMap(
  // Optimize map performance
  liteModeEnabled: false, // Set to true for better performance on low-end devices
  compassEnabled: true,
  mapToolbarEnabled: false,
  buildingsEnabled: true,
  trafficEnabled: false, // Disable unless needed
  
  // Limit visible markers based on zoom level
  onCameraMove: (CameraPosition position) {
    _updateVisibleMarkers(position.zoom);
  },
)
```

## Error Handling

### Common Issues and Solutions

1. **Location Permission Denied**:
   ```dart
   // Show permission rationale
   if (permission == PermissionStatus.denied) {
     showDialog(/* explain why location is needed */);
   }
   ```

2. **Network Connectivity**:
   ```dart
   try {
     final result = await MLAPIService.getNearbyMap(/* ... */);
   } catch (e) {
     // Show cached data or offline message
     _showOfflineData();
   }
   ```

3. **GPS Accuracy**:
   ```dart
   final locationData = await _location.getLocation();
   if (locationData.accuracy! > 100) {
     // Show warning about location accuracy
     _showAccuracyWarning();
   }
   ```

## Testing

### 1. Simulator Testing

For iOS Simulator, you can simulate location:
```
Device → Location → Custom Location
```

For Android Emulator:
```
Extended Controls → Location → Set coordinates
```

### 2. Mock Data

Test with mock coordinates:
```dart
// Test locations around San Francisco
final testLocations = [
  LocationInfo(city: 'SF', state: 'CA', country: 'USA', 
                latitude: 37.7749, longitude: -122.4194),
];
```

## Security Considerations

1. **API Key Security**:
   - Use separate keys for development/production
   - Restrict API keys to your app's package name
   - Monitor API usage in Google Cloud Console

2. **Location Privacy**:
   - Only request location when needed
   - Explain location usage to users
   - Allow users to opt-out of location sharing

3. **Data Validation**:
   ```dart
   bool _isValidCoordinate(double lat, double lng) {
     return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
   }
   ```

This integration provides a comprehensive map-based nearby experience that aligns with modern social discovery patterns while maintaining good performance and user privacy.
