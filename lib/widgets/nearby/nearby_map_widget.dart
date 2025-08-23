// lib/widgets/nearby/nearby_map_widget.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:fitsyncgemini/services/MLAPI_service.dart';
import 'package:fitsyncgemini/models/nearby_model.dart';
import 'package:fitsyncgemini/utils/map_utils.dart';
import 'package:fitsyncgemini/constants/app_colors.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fitsyncgemini/data/dummy_nearby_data.dart';

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

class _NearbyMapWidgetState extends State<NearbyMapWidget>
    with TickerProviderStateMixin {
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
  BitmapDescriptor? _storyIcon;

  // Filter toggles
  bool _showPeople = true;
  bool _showEvents = true;
  bool _showHotspots = true;
  bool _showPosts = true;

  // Keep last data to re-apply filters without refetch
  Map<String, dynamic>? _lastMapData;

  // SnapMap-inspired features
  bool _showHeatmap = false;
  bool _showLiveActivity = true;
  String _selectedView = 'map'; // 'map' or 'satellite'z

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

      // Use dummy data for now - easy to replace with real API when backend is ready
      Map<String, dynamic> mapData = DummyNearbyData.getDummyMapData();

      if (!mounted) return;
      _lastMapData = mapData;

      // Use default markers for now to avoid icon creation issues
      _userIcon = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueBlue,
      );
      _personIcon = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueGreen,
      );
      _eventIcon = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueOrange,
      );
      _hotspotIcon = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueRed,
      );

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
            id: personData['id']?.toString() ?? 'unknown',
            name: personData['name']?.toString() ?? 'Unknown User',
            avatar:
                personData['avatar']?.toString() ??
                'https://api.dicebear.com/7.x/avataaars/png?seed=default',
            distance: personData['distance']?.toString() ?? 'Unknown distance',
            style: personData['style']?.toString() ?? 'Unknown style',
            mutualConnections: personData['mutualConnections'] ?? 0,
            recentOutfit:
                personData['recentOutfit']?.toString() ?? 'No recent outfit',
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
            id: eventData['id']?.toString() ?? 'unknown',
            title: eventData['title']?.toString() ?? 'Unknown Event',
            location: eventData['location']?.toString() ?? 'Unknown Location',
            distance: eventData['distance']?.toString() ?? 'Unknown distance',
            date:
                eventData['date']?.toString() ??
                DateTime.now().toIso8601String(),
            attendees: eventData['attendees'] ?? 0,
            image:
                eventData['image']?.toString() ??
                'https://via.placeholder.com/300x200/FF6B9D/FFFFFF?text=Event',
            category: eventData['category']?.toString() ?? 'General',
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
            id: hotspotData['id']?.toString() ?? 'unknown',
            name: hotspotData['name']?.toString() ?? 'Unknown Hotspot',
            type: hotspotData['type']?.toString() ?? 'Unknown Type',
            distance: hotspotData['distance']?.toString() ?? 'Unknown distance',
            popularStyles: List<String>.from(
              hotspotData['popularStyles'] ?? [],
            ),
            rating: (hotspotData['rating'] ?? 0.0).toDouble(),
            checkIns: hotspotData['checkIns'] ?? 0,
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
      debugPrint('Error loading nearby data: $e');
      setState(() {
        _isLoading = false;
        _error = 'Failed to load map data: ${e.toString()}';
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
        icon:
            _userIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
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
            markerId: MarkerId(
              'person_${personData['id']?.toString() ?? 'unknown'}',
            ),
            position: LatLng(
              personData['latitude'] ?? 0.0,
              personData['longitude'] ?? 0.0,
            ),
            icon:
                _personIcon ??
                BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen,
                ),
            infoWindow: InfoWindow(
              title: personData['name']?.toString() ?? 'Unknown User',
              snippet:
                  '${personData['style']?.toString() ?? 'Unknown'} • ${personData['distance']?.toString() ?? 'Unknown'}',
            ),
          ),
        );
      }
    }

    if (_showEvents && _lastMapData!['events'] != null) {
      for (var eventData in _lastMapData!['events']) {
        filtered.add(
          Marker(
            markerId: MarkerId(
              'event_${eventData['id']?.toString() ?? 'unknown'}',
            ),
            position: LatLng(
              eventData['latitude'] ?? 0.0,
              eventData['longitude'] ?? 0.0,
            ),
            icon:
                _eventIcon ??
                BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueOrange,
                ),
            infoWindow: InfoWindow(
              title: eventData['title']?.toString() ?? 'Unknown Event',
              snippet:
                  '${eventData['category']?.toString() ?? 'Unknown'} • ${eventData['distance']?.toString() ?? 'Unknown'}',
            ),
          ),
        );
      }
    }

    if (_showHotspots && _lastMapData!['hotspots'] != null) {
      for (var hotspotData in _lastMapData!['hotspots']) {
        filtered.add(
          Marker(
            markerId: MarkerId(
              'hotspot_${hotspotData['id']?.toString() ?? 'unknown'}',
            ),
            position: LatLng(
              hotspotData['latitude'] ?? 0.0,
              hotspotData['longitude'] ?? 0.0,
            ),
            icon:
                _hotspotIcon ??
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(
              title: hotspotData['name']?.toString() ?? 'Unknown Hotspot',
              snippet:
                  '${hotspotData['type']?.toString() ?? 'Unknown'} • ${(hotspotData['rating'] ?? 0.0).toStringAsFixed(1)}⭐',
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (_isLoading) {
      return Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading map...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.alertCircle, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Failed to load map data',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadNearbyData,
                icon: const Icon(LucideIcons.refreshCw, size: 16),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Main Map
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
          myLocationButtonEnabled: false, // We'll add custom button
          zoomControlsEnabled: false, // We'll add custom controls
          mapToolbarEnabled: false,
          mapType:
              _selectedView == 'satellite' ? MapType.satellite : MapType.normal,
          circles: {
            Circle(
              circleId: const CircleId('search_radius'),
              center: LatLng(
                widget.userLocation.latitude,
                widget.userLocation.longitude,
              ),
              radius: widget.radiusKm * 1000, // Convert km to meters
              fillColor: AppColors.primary.withOpacity(0.1),
              strokeColor: AppColors.primary.withOpacity(0.3),
              strokeWidth: 2,
            ),
          },
        ),

        // SnapMap-inspired Filter Bar
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: _buildFilterBar(
            theme,
            scheme,
          ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0),
        ),

        // Custom Map Controls
        Positioned(
          right: 16,
          bottom: 100,
          child: Column(
                children: [
                  _buildMapControlButton(
                    icon: LucideIcons.plus,
                    onPressed:
                        () =>
                            _mapController.animateCamera(CameraUpdate.zoomIn()),
                  ),
                  const SizedBox(height: 8),
                  _buildMapControlButton(
                    icon: LucideIcons.minus,
                    onPressed:
                        () => _mapController.animateCamera(
                          CameraUpdate.zoomOut(),
                        ),
                  ),
                  const SizedBox(height: 8),
                  _buildMapControlButton(
                    icon: LucideIcons.navigation,
                    onPressed:
                        () => _mapController.animateCamera(
                          CameraUpdate.newLatLng(
                            LatLng(
                              widget.userLocation.latitude,
                              widget.userLocation.longitude,
                            ),
                          ),
                        ),
                  ),
                ],
              )
              .animate()
              .fadeIn(duration: 300.ms, delay: 200.ms)
              .slideX(begin: 0.2, end: 0),
        ),

        // Live Activity Indicator
        if (_showLiveActivity)
          Positioned(
            top: 100,
            left: 16,
            child: _buildLiveActivityIndicator(
              theme,
              scheme,
            ).animate().fadeIn(duration: 300.ms, delay: 400.ms),
          ),

        // Heatmap Toggle
        Positioned(
          bottom: 16,
          left: 16,
          child: _buildHeatmapToggle(
            theme,
            scheme,
          ).animate().fadeIn(duration: 300.ms, delay: 600.ms),
        ),
      ],
    );
  }

  Widget _buildFilterBar(ThemeData theme, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFilterChip('People', _showPeople, AppColors.secondary, () {
            setState(() => _showPeople = !_showPeople);
            _applyFilters();
          }),
          const SizedBox(width: 8),
          _buildFilterChip('Events', _showEvents, AppColors.tertiary, () {
            setState(() => _showEvents = !_showEvents);
            _applyFilters();
          }),
          const SizedBox(width: 8),
          _buildFilterChip('Hotspots', _showHotspots, AppColors.success, () {
            setState(() => _showHotspots = !_showHotspots);
            _applyFilters();
          }),
          const SizedBox(width: 8),
          _buildFilterChip('Posts', _showPosts, AppColors.warning, () {
            setState(() => _showPosts = !_showPosts);
            _applyFilters();
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    bool selected,
    Color color,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : scheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : scheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : color,
          ),
        ),
      ),
    );
  }

  Widget _buildMapControlButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Icon(icon, color: scheme.onSurface, size: 20),
        ),
      ),
    );
  }

  Widget _buildLiveActivityIndicator(ThemeData theme, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'LIVE',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapToggle(ThemeData theme, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() => _showHeatmap = !_showHeatmap);
          },
          borderRadius: BorderRadius.circular(8),
          child: Icon(
            _showHeatmap ? LucideIcons.layers : LucideIcons.layers,
            color: _showHeatmap ? AppColors.primary : scheme.onSurface,
            size: 20,
          ),
        ),
      ),
    );
  }

  // TODO: Replace with real API call when backend is ready
  // Example:
  // Map<String, dynamic> mapData = await MLAPIService.getNearbyMap(
  //   lat: widget.userLocation.latitude,
  //   lng: widget.userLocation.longitude,
  //   radiusKm: widget.radiusKm,
  //   limitPeople: 10,
  //   limitEvents: 10,
  //   limitHotspots: 10,
  // );
}
