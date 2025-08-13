import 'package:flutter/material.dart';
import 'package:fitsyncgemini/services/MLAPI_service.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  String _activeTab = 'people';
  bool _isLoadingNearbyPeople = false;
  bool _isLoadingNearbyEvents = false;
  bool _isLoadingHotspots = false;

  // Backend data
  List<Map<String, dynamic>> _nearbyPeople = [];
  List<Map<String, dynamic>> _nearbyEvents = [];
  List<Map<String, dynamic>> _hotspots = [];

  @override
  void initState() {
    super.initState();
    _loadNearbyData();
  }

  // Load all nearby data from backend
  Future<void> _loadNearbyData() async {
    await Future.wait([
      _loadNearbyPeople(),
      _loadNearbyEvents(),
      _loadHotspots(),
    ]);
  }

  // Load nearby people from backend
  Future<void> _loadNearbyPeople() async {
    if (_isLoadingNearbyPeople) return;

    setState(() {
      _isLoadingNearbyPeople = true;
    });

    try {
      // Note: Nearby people endpoint might not be implemented yet
      // For now, we'll use default nearby people data
      setState(() {
        _nearbyPeople = [
          {
            'id': 1,
            'name': 'Jessica Chen',
            'avatar': 'JC',
            'distance': '0.3 mi',
            'style': 'Minimalist',
            'mutualConnections': 5,
            'recentOutfit': 'https://picsum.photos/200/200?random=1',
            'isOnline': true,
          },
          {
            'id': 2,
            'name': 'Maya Patel',
            'avatar': 'MP',
            'distance': '0.8 mi',
            'style': 'Bohemian',
            'mutualConnections': 12,
            'recentOutfit': 'https://picsum.photos/200/200?random=2',
            'isOnline': true,
          },
          {
            'id': 3,
            'name': 'Alex Rivera',
            'avatar': 'AR',
            'distance': '1.2 mi',
            'style': 'Professional',
            'mutualConnections': 3,
            'recentOutfit': 'https://picsum.photos/200/200?random=3',
            'isOnline': false,
          },
        ];
      });
    } catch (e) {
      print('❌ Failed to load nearby people: $e');
      // Keep empty list if backend fails
    } finally {
      setState(() {
        _isLoadingNearbyPeople = false;
      });
    }
  }

  // Load nearby events from backend
  Future<void> _loadNearbyEvents() async {
    if (_isLoadingNearbyEvents) return;

    setState(() {
      _isLoadingNearbyEvents = true;
    });

    try {
      // Note: Nearby events endpoint might not be implemented yet
      // For now, we'll use default nearby events data
      setState(() {
        _nearbyEvents = [
          {
            'id': 1,
            'title': 'Style Swap Meet',
            'location': 'Central Park',
            'distance': '0.5 mi',
            'date': 'Today, 3:00 PM',
            'attendees': 24,
            'image': 'https://picsum.photos/400/300?random=4',
            'category': 'Community',
          },
          {
            'id': 2,
            'title': 'Vintage Fashion Market',
            'location': 'Brooklyn Flea',
            'distance': '2.1 mi',
            'date': 'Tomorrow, 10:00 AM',
            'attendees': 156,
            'image': 'https://picsum.photos/400/300?random=5',
            'category': 'Shopping',
          },
        ];
      });
    } catch (e) {
      print('❌ Failed to load nearby events: $e');
      // Keep empty list if backend fails
    } finally {
      setState(() {
        _isLoadingNearbyEvents = false;
      });
    }
  }

  // Load hotspots from backend
  Future<void> _loadHotspots() async {
    if (_isLoadingHotspots) return;

    setState(() {
      _isLoadingHotspots = true;
    });

    try {
      // Note: Hotspots endpoint might not be implemented yet
      // For now, we'll use default hotspots data
      setState(() {
        _hotspots = [
          {
            'id': 1,
            'name': 'SoHo District',
            'type': 'Shopping Area',
            'distance': '1.8 mi',
            'popularStyles': ['Minimalist', 'Professional'],
            'rating': 4.8,
            'checkIns': 342,
          },
          {
            'id': 2,
            'name': 'Williamsburg',
            'type': 'Creative Hub',
            'distance': '3.2 mi',
            'popularStyles': ['Bohemian', 'Eclectic'],
            'rating': 4.6,
            'checkIns': 198,
          },
        ];
      });
    } catch (e) {
      print('❌ Failed to load hotspots: $e');
      // Keep empty list if backend fails
    } finally {
      setState(() {
        _isLoadingHotspots = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Nearby',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: () => _loadNearbyData(),
          ),
          IconButton(
            icon: const Icon(LucideIcons.mapPin),
            onPressed: () {
              // Open map view
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadNearbyData();
        },
        child: Column(
          children: [
            // Location Header
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  Icon(LucideIcons.mapPin, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Manhattan, New York',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.wifi, size: 12, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          'Live',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              color: Colors.white,
              child: Row(
                children: [
                  _buildTabButton('people', 'People', LucideIcons.users),
                  _buildTabButton('events', 'Events', LucideIcons.calendar),
                  _buildTabButton('hotspots', 'Hotspots', LucideIcons.mapPin),
                ],
              ),
            ),

            // Content
            Expanded(child: _buildTabContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String tab, String label, IconData icon) {
    final isActive = _activeTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeTab = tab;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? Colors.black : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isActive ? Colors.black : Colors.grey.shade600,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? Colors.black : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_activeTab) {
      case 'people':
        return _buildPeopleTab();
      case 'events':
        return _buildEventsTab();
      case 'hotspots':
        return _buildHotspotsTab();
      default:
        return _buildPeopleTab();
    }
  }

  Widget _buildPeopleTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Nearby Style Enthusiasts',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_nearbyPeople.length} people',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          ),
          if (_isLoadingNearbyPeople)
            const Center(child: CircularProgressIndicator())
          else if (_nearbyPeople.isEmpty)
            _buildEmptyState('No nearby people found')
          else
            ..._nearbyPeople.map((person) => _buildPersonCard(person)).toList(),
          const SizedBox(height: 100), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildEventsTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Fashion Events',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_nearbyEvents.length} events',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          ),
          if (_isLoadingNearbyEvents)
            const Center(child: CircularProgressIndicator())
          else if (_nearbyEvents.isEmpty)
            _buildEmptyState('No nearby events found')
          else
            ..._nearbyEvents.map((event) => _buildEventCard(event)).toList(),
          const SizedBox(height: 100), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildHotspotsTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Style Hotspots',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_hotspots.length} hotspots',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          ),
          if (_isLoadingHotspots)
            const Center(child: CircularProgressIndicator())
          else if (_hotspots.isEmpty)
            _buildEmptyState('No hotspots found')
          else
            ..._hotspots.map((hotspot) => _buildHotspotCard(hotspot)).toList(),
          const SizedBox(height: 100), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(LucideIcons.mapPin, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try expanding your search radius',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonCard(Map<String, dynamic> person) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Stack(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey.shade200,
                child: Text(
                  person['avatar'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              if (person['isOnline'])
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person['name'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      LucideIcons.mapPin,
                      size: 12,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      person['distance'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    person['style'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${person['mutualConnections']} mutual connections',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          // Recent outfit
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                person['recentOutfit'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade200,
                    child: Icon(LucideIcons.image, color: Colors.grey.shade400),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Image.network(
              event['image'],
              width: double.infinity,
              height: 150,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: double.infinity,
                  height: 150,
                  color: Colors.grey.shade200,
                  child: Icon(
                    LucideIcons.image,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                );
              },
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        event['title'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        event['category'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Icon(
                      LucideIcons.mapPin,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      event['location'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      LucideIcons.clock,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      event['date'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Icon(
                      LucideIcons.users,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${event['attendees']} attending',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      event['distance'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Join event
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Join Event'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () {
                        // Share event
                      },
                      icon: const Icon(LucideIcons.share2),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotspotCard(Map<String, dynamic> hotspot) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(LucideIcons.mapPin, color: Colors.purple, size: 24),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hotspot['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hotspot['type'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(LucideIcons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '${hotspot['rating']}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          LucideIcons.mapPin,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          hotspot['distance'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Popular styles
          Text(
            'Popular Styles:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children:
                (hotspot['popularStyles'] as List).map((style) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      style,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Icon(LucideIcons.users, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                '${hotspot['checkIns']} check-ins',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  // Check in
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Check In'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
