// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:lucide_icons/lucide_icons.dart';
// import 'package:fitsyncgemini/constants/app_colors.dart';
// import 'package:flutter_animate/flutter_animate.dart';

// class NearbyScreen extends StatefulWidget {
//   const NearbyScreen({super.key});

//   @override
//   State<NearbyScreen> createState() => _NearbyScreenState();
// }

// class _NearbyScreenState extends State<NearbyScreen> {
//   double _radiusKm = 5.0;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Theme.of(context).colorScheme.background,
//         elevation: 1,
//         shadowColor: Colors.black.withOpacity(0.1),
//         leading: IconButton(
//           icon: const Icon(LucideIcons.arrowLeft),
//           onPressed: () => context.go('/dashboard'),
//         ),
//         title: Row(
//           children: [
//             const Icon(LucideIcons.mapPin, color: AppColors.pink),
//             const SizedBox(width: 8),
//             const Text(
//               'Nearby Style',
//               style: TextStyle(fontWeight: FontWeight.bold),
//             ),
//           ],
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(LucideIcons.settings2),
//             onPressed: () => _showRadiusSettings(),
//           ),
//         ],
//       ),
//       body: CustomScrollView(
//         slivers: [
//           SliverToBoxAdapter(
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 children: [
//                   _buildLocationCard(),
//                   const SizedBox(height: 20),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       const Text(
//                         'Style Feed',
//                         style: TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       Text(
//                         'Within ${_radiusKm.toInt()}km',
//                         style: TextStyle(color: Colors.grey.shade600),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           SliverPadding(
//             padding: const EdgeInsets.symmetric(horizontal: 16.0),
//             sliver: SliverList(
//               delegate: SliverChildBuilderDelegate(
//                 (context, index) => _buildStyleFeedItem(index),
//                 childCount: 10, // Placeholder count
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildLocationCard() {
//     return Card(
//       color: AppColors.blue.withOpacity(0.05),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Row(
//           children: [
//             Container(
//               width: 48,
//               height: 48,
//               decoration: BoxDecoration(
//                 color: AppColors.blue,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: const Icon(LucideIcons.mapPin, color: Colors.white),
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Your Location',
//                     style: TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                   Text(
//                     'Port Dickson, Negeri Sembilan',
//                     style: TextStyle(color: Colors.grey.shade600),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     '${_radiusKm.toInt()}km radius • 24 active users',
//                     style: TextStyle(
//                       color: AppColors.blue,
//                       fontSize: 12,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             IconButton(
//               icon: const Icon(LucideIcons.refreshCw),
//               onPressed: () {},
//             ),
//           ],
//         ),
//       ),
//     ).animate().fadeIn();
//   }

//   Widget _buildStyleFeedItem(int index) {
//     final users = [
//       {
//         'name': 'Sarah Chen',
//         'distance': '1.2km',
//         'style': 'Minimalist',
//         'time': '2h ago',
//       },
//       {
//         'name': 'Alex Kim',
//         'distance': '2.8km',
//         'style': 'Streetwear',
//         'time': '4h ago',
//       },
//       {
//         'name': 'Maya Patel',
//         'distance': '3.5km',
//         'style': 'Old Money',
//         'time': '6h ago',
//       },
//     ];

//     final user = users[index % users.length];

//     return Card(
//       margin: const EdgeInsets.only(bottom: 16),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 CircleAvatar(
//                   radius: 20,
//                   backgroundColor: AppColors.pink,
//                   child: Text(
//                     user['name']!.split(' ').map((n) => n[0]).join(),
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         user['name']!,
//                         style: const TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                       Row(
//                         children: [
//                           Icon(
//                             LucideIcons.mapPin,
//                             size: 12,
//                             color: Colors.grey.shade600,
//                           ),
//                           const SizedBox(width: 4),
//                           Text(
//                             user['distance']!,
//                             style: TextStyle(
//                               color: Colors.grey.shade600,
//                               fontSize: 12,
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 6,
//                               vertical: 2,
//                             ),
//                             decoration: BoxDecoration(
//                               color: AppColors.teal.withOpacity(0.1),
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: Text(
//                               user['style']!,
//                               style: const TextStyle(
//                                 color: AppColors.teal,
//                                 fontSize: 10,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//                 Text(
//                   user['time']!,
//                   style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Container(
//               height: 200,
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade100,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: const Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(LucideIcons.image, size: 40, color: Colors.grey),
//                     SizedBox(height: 8),
//                     Text('Outfit Photo', style: TextStyle(color: Colors.grey)),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 12),
//             Row(
//               children: [
//                 IconButton(
//                   icon: const Icon(LucideIcons.heart, size: 20),
//                   onPressed: () {},
//                 ),
//                 const Text('12'),
//                 const SizedBox(width: 16),
//                 IconButton(
//                   icon: const Icon(LucideIcons.messageCircle, size: 20),
//                   onPressed: () {},
//                 ),
//                 const Text('3'),
//                 const Spacer(),
//                 OutlinedButton.icon(
//                   onPressed: () {},
//                   icon: const Icon(LucideIcons.copy, size: 16),
//                   label: const Text('Copy Style'),
//                   style: OutlinedButton.styleFrom(
//                     foregroundColor: AppColors.pink,
//                     side: const BorderSide(color: AppColors.pink),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     ).animate().fadeIn(delay: (index * 100).ms);
//   }

//   void _showRadiusSettings() {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder:
//           (context) => StatefulBuilder(
//             builder:
//                 (context, setModalState) => Container(
//                   padding: const EdgeInsets.all(24.0),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text(
//                         'Search Radius',
//                         style: TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 20),
//                       Text('${_radiusKm.toInt()}km'),
//                       Slider(
//                         value: _radiusKm,
//                         min: 1.0,
//                         max: 50.0,
//                         divisions: 49,
//                         activeColor: AppColors.pink,
//                         onChanged: (value) {
//                           setModalState(() {
//                             _radiusKm = value;
//                           });
//                         },
//                       ),
//                       const SizedBox(height: 20),
//                       SizedBox(
//                         width: double.infinity,
//                         child: ElevatedButton(
//                           onPressed: () {
//                             setState(() {});
//                             Navigator.pop(context);
//                           },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: AppColors.pink,
//                             foregroundColor: Colors.white,
//                           ),
//                           child: const Text('Update Radius'),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//           ),
//     );
//   }
// }
// lib/screens/nearby/nearby_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fitsyncgemini/constants/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String activeTab = 'people';

  final List<Map<String, dynamic>> nearbyPeople = [
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

  final List<Map<String, dynamic>> nearbyEvents = [
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

  final List<Map<String, dynamic>> hotspots = [
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        switch (_tabController.index) {
          case 0:
            activeTab = 'people';
            break;
          case 1:
            activeTab = 'events';
            break;
          case 2:
            activeTab = 'hotspots';
            break;
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [_buildSliverAppBar()];
        },
        body: TabBarView(
          controller: _tabController,
          children: [_buildPeopleTab(), _buildEventsTab(), _buildHotspotsTab()],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.1),
      pinned: true,
      floating: false,
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft),
        onPressed: () => context.go('/dashboard'),
      ),
      title: const Text(
        'Nearby',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(icon: const Icon(LucideIcons.navigation), onPressed: () {}),
        IconButton(icon: const Icon(LucideIcons.search), onPressed: () {}),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              // Location Info
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.mapPin,
                      size: 16,
                      color: AppColors.pink,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Manhattan, New York',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text('Live', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Tabs
              Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.pink,
                  labelColor: AppColors.pink,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(text: 'People (${nearbyPeople.length})'),
                    Tab(text: 'Events (${nearbyEvents.length})'),
                    Tab(text: 'Hotspots (${hotspots.length})'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeopleTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: nearbyPeople.length,
      itemBuilder: (context, index) {
        final person = nearbyPeople[index];
        return _buildPersonCard(person, index);
      },
    );
  }

  Widget _buildPersonCard(Map<String, dynamic> person, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar with online indicator
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.teal,
                  child: Text(
                    person['avatar'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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
            // Person info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        person['name'],
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          person['style'],
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.mapPin,
                        size: 12,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        person['distance'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        LucideIcons.users,
                        size: 12,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${person['mutualConnections']} mutual',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Recent outfit and actions
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade200,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildPersonImage(person['recentOutfit']),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    SizedBox(
                      height: 28,
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(LucideIcons.heart, size: 12),
                        label: const Text(
                          'Connect',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(LucideIcons.messageCircle, size: 12),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 100));
  }

  Widget _buildEventsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: nearbyEvents.length,
      itemBuilder: (context, index) {
        final event = nearbyEvents[index];
        return _buildEventCard(event, index);
      },
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          // Event image
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: _buildEventImage(event['image']),
            ),
          ),
          // Event details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event['title'],
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        event['category'],
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.mapPin,
                          size: 12,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${event['location']} • ${event['distance']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.clock,
                          size: 12,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          event['date'],
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.users,
                          size: 12,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${event['attendees']} attending',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(LucideIcons.calendar, size: 16),
                    label: const Text('Join Event'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.pink,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 100));
  }

  Widget _buildHotspotsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: hotspots.length,
      itemBuilder: (context, index) {
        final hotspot = hotspots[index];
        return _buildHotspotCard(hotspot, index);
      },
    );
  }

  Widget _buildHotspotCard(Map<String, dynamic> hotspot, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            hotspot['name'],
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              hotspot['type'],
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.mapPin,
                            size: 12,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            hotspot['distance'],
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(
                            LucideIcons.users,
                            size: 12,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${hotspot['checkIns']} check-ins',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        children:
                            (hotspot['popularStyles'] as List<String>).map((
                              style,
                            ) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  style,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text(
                      hotspot['rating'].toString(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.pink,
                      ),
                    ),
                    const Text(
                      'rating',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(LucideIcons.navigation, size: 16),
                label: const Text('Get Directions'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 100));
  }

  Widget _buildPersonImage(String imageUrl) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.teal.withOpacity(0.1),
      child: const Icon(LucideIcons.user, color: AppColors.teal, size: 20),
    );
  }

  Widget _buildEventImage(String imageUrl) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.purple.withOpacity(0.1),
      child: const Icon(
        LucideIcons.calendar,
        color: AppColors.purple,
        size: 40,
      ),
    );
  }
}
