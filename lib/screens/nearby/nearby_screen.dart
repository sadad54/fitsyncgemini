// lib/screens/nearby/nearby_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitsyncgemini/widgets/nearby/nearby_map_widget.dart';
import 'package:fitsyncgemini/services/location_service.dart';
import 'package:fitsyncgemini/models/nearby_model.dart';
import 'package:fitsyncgemini/constants/app_colors.dart';

class NearbyScreen extends ConsumerStatefulWidget {
  const NearbyScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends ConsumerState<NearbyScreen> {
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

      // Check if we have location permission
      final hasPermission = await _locationService.hasLocationPermission();
      if (!hasPermission) {
        setState(() {
          _error = 'Location permission required for nearby features';
          _isLoading = false;
        });
        return;
      }

      final location =
          await _locationService.getCurrentLocationWithGeolocator();
      if (location != null) {
        setState(() {
          _userLocation = location;
          _isLoading = false;
        });
      } else {
        // Use mock location as fallback
        setState(() {
          _userLocation = _locationService.getMockLocation();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        // Use mock location as fallback
        _userLocation = _locationService.getMockLocation();
      });
    }
  }

  Future<void> _requestLocationPermission() async {
    final hasPermission = await _locationService.hasLocationPermission();
    if (!hasPermission) {
      // Show permission rationale dialog
      _showLocationPermissionDialog();
    } else {
      _getUserLocation();
    }
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Location Permission'),
            content: const Text(
              'This app needs access to your location to show nearby fashion content, '
              'style influencers, and fashion events around you.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Use mock location instead
                  setState(() {
                    _userLocation = _locationService.getMockLocation();
                    _isLoading = false;
                    _error = null;
                  });
                },
                child: const Text('Use Demo Location'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _locationService.openLocationSettings();
                },
                child: const Text('Settings'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _getUserLocation();
                },
                child: const Text('Allow'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header
          _buildHeader(),

          // Content
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    // Fallback to dashboard
                    Future.microtask(
                      () => Navigator.of(
                        context,
                      ).pushReplacementNamed('/dashboard'),
                    );
                  }
                },
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nearby',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _userLocation?.fullLocation ?? 'Loading location...',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _getUserLocation,
              ),
              IconButton(
                icon: const Icon(Icons.location_on),
                onPressed: _requestLocationPermission,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Getting your location...'),
          ],
        ),
      );
    }

    if (_error != null && _userLocation == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 24),
              Text(
                'Location Access Required',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'To show nearby fashion content, we need access to your location. '
                'You can also use our demo location to explore the features.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _userLocation = _locationService.getMockLocation();
                          _error = null;
                        });
                      },
                      icon: const Icon(Icons.map),
                      label: const Text('Use Demo'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _requestLocationPermission,
                      icon: const Icon(Icons.location_on),
                      label: const Text('Allow Location'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (_userLocation == null) {
      return const Center(child: Text('Location not available'));
    }

    return NearbyMapWidget(
      userLocation: _userLocation!,
      radiusKm: 5.0,
      onPersonTap: () {
        debugPrint('Person tapped');
        _showFeatureSnackBar('Person details');
      },
      onEventTap: () {
        debugPrint('Event tapped');
        _showFeatureSnackBar('Event details');
      },
      onHotspotTap: () {
        debugPrint('Hotspot tapped');
        _showFeatureSnackBar('Hotspot details');
      },
    );
  }

  void _showFeatureSnackBar(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: AppColors.pink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
