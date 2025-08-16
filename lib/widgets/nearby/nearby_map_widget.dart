// lib/widgets/nearby/nearby_map_widget.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:fitsyncgemini/services/MLAPI_service.dart';
import 'package:fitsyncgemini/models/nearby_model.dart';
import 'package:fitsyncgemini/utils/map_utils.dart';
import 'package:fitsyncgemini/constants/app_colors.dart';

class NearbyMapWidget extends StatefulWidget {
  final LocationInfo userLocation;
  final double radiusKm;
  final VoidCallback? onPersonTap;
  final VoidCallback? onEventTap;
  final VoidCallback? onHotspotTap;

  const NearbyMapWidget({
    Key? key,
    required this.userLocation,
    this.radiusKm = 5.0,
    this.onPersonTap,
    this.onEventTap,
    this.onHotspotTap,
  }) : super(key: key);

  @override
  State<NearbyMapWidget> createState() => _NearbyMapWidgetState();
}

class _NearbyMapWidgetState extends State<NearbyMapWidget> {
  late GoogleMapController _mapController;
  bool _mapReady = false;
  Set<Marker> _markers = {};
  bool _isLoading = true;
  String? _error;

  // Cached custom marker icons
  BitmapDescriptor? _userIcon;
  BitmapDescriptor? _personIcon;
  BitmapDescriptor? _eventIcon;
  BitmapDescriptor? _hotspotIcon;

  // Filter toggles
  bool _showPeople = true;
  bool _showEvents = true;
  bool _showHotspots = true;

  // Keep last data to re-apply filters without refetch
  Map<String, dynamic>? _lastMapData;

  @override
  void initState() {
    super.initState();
    _loadNearbyData();
  }

  @override
  void didUpdateWidget(covariant NearbyMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final coordsChanged =
        oldWidget.userLocation.latitude != widget.userLocation.latitude ||
        oldWidget.userLocation.longitude != widget.userLocation.longitude;
    final liveFlagChanged =
        oldWidget.userLocation.isLive != widget.userLocation.isLive;
    if (coordsChanged || liveFlagChanged) {
      _lastMapData = null;
      _loadNearbyData();
    }
  }

  Future<void> _loadNearbyData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get combined nearby data for map overlay
      Map<String, dynamic> mapData;
      // If using demo (non-live) location, skip API and use mock data directly
      if (!widget.userLocation.isLive) {
        debugPrint('Using demo mock data for Nearby map');
        mapData = _getMockMapData();
      } else {
        try {
          mapData = await MLAPIService.getNearbyMap(
            lat: widget.userLocation.latitude,
            lng: widget.userLocation.longitude,
            radiusKm: widget.radiusKm,
            limitPeople: 10,
            limitEvents: 10,
            limitHotspots: 10,
          );
        } catch (e) {
          debugPrint('API call failed, using mock data: $e');
          // Use mock data as fallback
          mapData = _getMockMapData();
        }
      }

      if (!mounted) return;
      _lastMapData = mapData;

      // Ensure icons loaded once
      if (_userIcon == null) {
        _userIcon = await MapUtils.createIconMarker(
          icon: Icons.my_location,
          backgroundColor: AppColors.blue,
        );
      }
      if (_personIcon == null) {
        _personIcon = await MapUtils.createIconMarker(
          icon: Icons.person_pin_circle,
          backgroundColor: AppColors.teal,
        );
      }
      if (_eventIcon == null) {
        _eventIcon = await MapUtils.createIconMarker(
          icon: Icons.event,
          backgroundColor: AppColors.purple,
        );
      }
      if (_hotspotIcon == null) {
        _hotspotIcon = await MapUtils.createIconMarker(
          icon: Icons.local_fire_department,
          backgroundColor: AppColors.pink,
        );
      }

      if (!mounted) return;
      // Build markers with current filter state
      final Set<Marker> newMarkers = {};

      newMarkers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(
            widget.userLocation.latitude,
            widget.userLocation.longitude,
          ),
          icon: _userIcon!,
          infoWindow: InfoWindow(
            title: 'Your Location',
            snippet: widget.userLocation.fullLocation,
          ),
        ),
      );

      if (_showPeople && mapData['people'] != null) {
        for (var personData in mapData['people']) {
          final person = NearbyPerson(
            id: personData['id'],
            name: personData['name'],
            avatar: personData['avatar'],
            distance: personData['distance'],
            style: personData['style'],
            mutualConnections: personData['mutualConnections'],
            recentOutfit: personData['recentOutfit'],
            isOnline: personData['isOnline'] ?? false,
          );

          newMarkers.add(
            Marker(
              markerId: MarkerId('person_${person.id}'),
              position: LatLng(personData['latitude'], personData['longitude']),
              icon: _personIcon!,
              infoWindow: InfoWindow(
                title: person.name,
                snippet: '${person.style} • ${person.distance}',
              ),
              onTap: () => _onPersonMarkerTap(person),
            ),
          );
        }
      }

      if (_showEvents && mapData['events'] != null) {
        for (var eventData in mapData['events']) {
          final event = NearbyEvent(
            id: eventData['id'],
            title: eventData['title'],
            location: eventData['location'],
            distance: eventData['distance'],
            date: eventData['date'],
            attendees: eventData['attendees'],
            image: eventData['image'],
            category: eventData['category'],
          );

          newMarkers.add(
            Marker(
              markerId: MarkerId('event_${event.id}'),
              position: LatLng(eventData['latitude'], eventData['longitude']),
              icon: _eventIcon!,
              infoWindow: InfoWindow(
                title: event.title,
                snippet: '${event.category} • ${event.distance}',
              ),
              onTap: () => _onEventMarkerTap(event),
            ),
          );
        }
      }

      if (_showHotspots && mapData['hotspots'] != null) {
        for (var hotspotData in mapData['hotspots']) {
          final hotspot = NearbyHotspot(
            id: hotspotData['id'],
            name: hotspotData['name'],
            type: hotspotData['type'],
            distance: hotspotData['distance'],
            popularStyles: List<String>.from(
              hotspotData['popularStyles'] ?? [],
            ),
            rating: hotspotData['rating'].toDouble(),
            checkIns: hotspotData['checkIns'],
          );

          newMarkers.add(
            Marker(
              markerId: MarkerId('hotspot_${hotspot.id}'),
              position: LatLng(
                hotspotData['latitude'],
                hotspotData['longitude'],
              ),
              icon: _hotspotIcon!,
              infoWindow: InfoWindow(
                title: hotspot.name,
                snippet: '${hotspot.type} • ${hotspot.rating}⭐',
              ),
              onTap: () => _onHotspotMarkerTap(hotspot),
            ),
          );
        }
      }

      if (!mounted) return;
      setState(() {
        _markers = newMarkers;
        _isLoading = false;
      });

      if (!mounted) return;
      if (_mapReady && newMarkers.isNotEmpty) {
        final positions = newMarkers.map((m) => m.position).toList();
        final bounds = MapUtils.getBounds(positions);
        try {
          await _mapController.animateCamera(
            CameraUpdate.newLatLngBounds(bounds, 60),
          );
        } catch (_) {}
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _applyFilters() async {
    if (_lastMapData == null) return;
    // Rebuild markers based on filter toggles
    final Set<Marker> filtered = {};

    // Always include user marker
    filtered.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: LatLng(
          widget.userLocation.latitude,
          widget.userLocation.longitude,
        ),
        icon: _userIcon ?? BitmapDescriptor.defaultMarker,
        infoWindow: InfoWindow(
          title: 'Your Location',
          snippet: widget.userLocation.fullLocation,
        ),
      ),
    );

    if (_showPeople && _lastMapData!['people'] != null) {
      for (var personData in _lastMapData!['people']) {
        filtered.add(
          Marker(
            markerId: MarkerId('person_${personData['id']}'),
            position: LatLng(personData['latitude'], personData['longitude']),
            icon: _personIcon ?? BitmapDescriptor.defaultMarker,
            infoWindow: InfoWindow(
              title: personData['name'],
              snippet: '${personData['style']} • ${personData['distance']}',
            ),
          ),
        );
      }
    }

    if (_showEvents && _lastMapData!['events'] != null) {
      for (var eventData in _lastMapData!['events']) {
        filtered.add(
          Marker(
            markerId: MarkerId('event_${eventData['id']}'),
            position: LatLng(eventData['latitude'], eventData['longitude']),
            icon: _eventIcon ?? BitmapDescriptor.defaultMarker,
            infoWindow: InfoWindow(
              title: eventData['title'],
              snippet: '${eventData['category']} • ${eventData['distance']}',
            ),
          ),
        );
      }
    }

    if (_showHotspots && _lastMapData!['hotspots'] != null) {
      for (var hotspotData in _lastMapData!['hotspots']) {
        filtered.add(
          Marker(
            markerId: MarkerId('hotspot_${hotspotData['id']}'),
            position: LatLng(hotspotData['latitude'], hotspotData['longitude']),
            icon: _hotspotIcon ?? BitmapDescriptor.defaultMarker,
            infoWindow: InfoWindow(
              title: hotspotData['name'],
              snippet: '${hotspotData['type']} • ${hotspotData['rating']}⭐',
            ),
          ),
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _markers = filtered;
    });
  }

  @override
  void dispose() {
    _mapReady = false;
    try {
      // Only dispose if initialized
      // ignore: unnecessary_null_comparison
      if (_mapController != null) {
        _mapController.dispose();
      }
    } catch (_) {}
    super.dispose();
  }

  void _onPersonMarkerTap(NearbyPerson person) {
    _showPersonBottomSheet(person);
    widget.onPersonTap?.call();
  }

  void _onEventMarkerTap(NearbyEvent event) {
    _showEventBottomSheet(event);
    widget.onEventTap?.call();
  }

  void _onHotspotMarkerTap(NearbyHotspot hotspot) {
    _showHotspotBottomSheet(hotspot);
    widget.onHotspotTap?.call();
  }

  void _showPersonBottomSheet(NearbyPerson person) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(person.avatar),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            person.name,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(
                            '${person.style} • ${person.distance}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          if (person.mutualConnections > 0)
                            Text(
                              '${person.mutualConnections} mutual connections',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                    if (person.isOnline)
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Recent Outfit',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  person.recentOutfit,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // Navigate to person's profile
                        },
                        child: const Text('View Profile'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // Send message
                        },
                        child: const Text('Message'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  void _showEventBottomSheet(NearbyEvent event) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    event.image,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) => Container(
                          height: 150,
                          color: Colors.grey[300],
                          child: const Icon(Icons.event),
                        ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  event.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  '${event.location} • ${event.distance}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '${event.attendees} attendees • ${event.category}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Join event or view details
                    },
                    child: const Text('View Event Details'),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showHotspotBottomSheet(NearbyHotspot hotspot) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hotspot.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  '${hotspot.type} • ${hotspot.distance}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 16),
                    Text(
                      ' ${hotspot.rating} • ${hotspot.checkIns} check-ins',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Popular Styles',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children:
                      hotspot.popularStyles
                          .map(
                            (style) => Chip(
                              label: Text(style),
                              backgroundColor: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.1),
                            ),
                          )
                          .toList(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Check in or view details
                    },
                    child: const Text('Check In'),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Failed to load map data',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadNearbyData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        GoogleMap(
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
            _mapReady = true;
          },
          initialCameraPosition: CameraPosition(
            target: LatLng(
              widget.userLocation.latitude,
              widget.userLocation.longitude,
            ),
            zoom: 14.0,
          ),
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: true,
          mapToolbarEnabled: false,
          circles: {
            Circle(
              circleId: const CircleId('search_radius'),
              center: LatLng(
                widget.userLocation.latitude,
                widget.userLocation.longitude,
              ),
              radius: widget.radiusKm * 1000, // Convert km to meters
              fillColor: AppColors.pink.withOpacity(0.1),
              strokeColor: AppColors.pink.withOpacity(0.3),
              strokeWidth: 2,
            ),
          },
        ),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('People'),
                      selected: _showPeople,
                      onSelected: (v) {
                        setState(() => _showPeople = v);
                        _applyFilters();
                      },
                      selectedColor: AppColors.teal.withOpacity(0.15),
                      checkmarkColor: AppColors.teal,
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Events'),
                      selected: _showEvents,
                      onSelected: (v) {
                        setState(() => _showEvents = v);
                        _applyFilters();
                      },
                      selectedColor: AppColors.purple.withOpacity(0.15),
                      checkmarkColor: AppColors.purple,
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Hotspots'),
                      selected: _showHotspots,
                      onSelected: (v) {
                        setState(() => _showHotspots = v);
                        _applyFilters();
                      },
                      selectedColor: AppColors.pink.withOpacity(0.15),
                      checkmarkColor: AppColors.pink,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Generate mock map data for testing when API is not available
  Map<String, dynamic> _getMockMapData() {
    final userLat = widget.userLocation.latitude;
    final userLng = widget.userLocation.longitude;

    return {
      'people': [
        {
          'id': 'mock_person_1',
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
          'id': 'mock_person_2',
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
      ],
      'events': [
        {
          'id': 'mock_event_1',
          'title': 'Sustainable Fashion Show',
          'location': 'Fashion District',
          'distance': '1.2 km',
          'date': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
          'attendees': 85,
          'image':
              'https://via.placeholder.com/300x200/FF6B9D/FFFFFF?text=Fashion+Show',
          'category': 'Fashion Show',
          'latitude': userLat + 0.005,
          'longitude': userLng - 0.002,
        },
        {
          'id': 'mock_event_2',
          'title': 'Vintage Pop-up Market',
          'location': 'Downtown Plaza',
          'distance': '2.1 km',
          'date': DateTime.now().add(const Duration(days: 5)).toIso8601String(),
          'attendees': 120,
          'image':
              'https://via.placeholder.com/300x200/4ECDC4/FFFFFF?text=Vintage+Market',
          'category': 'Shopping',
          'latitude': userLat - 0.008,
          'longitude': userLng - 0.006,
        },
      ],
      'hotspots': [
        {
          'id': 'mock_hotspot_1',
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
          'id': 'mock_hotspot_2',
          'name': 'Minimalist Corner',
          'type': 'Concept Store',
          'distance': '1.5 km',
          'popularStyles': ['minimalist', 'sustainable'],
          'rating': 4.6,
          'checkIns': 89,
          'latitude': userLat + 0.006,
          'longitude': userLng + 0.007,
        },
      ],
    };
  }
}
