// lib/screens/trends/trends_screen_new.dart
import 'package:flutter/material.dart';
import 'package:fitsyncgemini/services/MLAPI_service.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fitsyncgemini/constants/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key});

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  String _selectedTimeframe = 'week';
  bool _isLoadingTrendingNow = false;
  bool _isLoadingFashionInsights = false;
  bool _isLoadingInfluencerSpotlight = false;

  // Backend data
  List<Map<String, dynamic>> _trendingNow = [];
  List<Map<String, dynamic>> _fashionInsights = [];
  List<Map<String, dynamic>> _influencerSpotlight = [];

  final List<Map<String, dynamic>> _timeframes = [
    {'id': 'week', 'label': 'This Week'},
    {'id': 'month', 'label': 'This Month'},
  ];

  @override
  void initState() {
    super.initState();
    _loadTrendsData();
  }

  // Load all trends data from backend
  Future<void> _loadTrendsData() async {
    await Future.wait([
      _loadTrendingNow(),
      _loadFashionInsights(),
      _loadInfluencerSpotlight(),
    ]);
  }

  // Load trending now data from backend
  Future<void> _loadTrendingNow() async {
    if (_isLoadingTrendingNow) return;

    setState(() {
      _isLoadingTrendingNow = true;
    });

    try {
      // Note: Trending now endpoint might not be implemented yet
      // For now, we'll use default trending data
      setState(() {
        _trendingNow = [
          {
            'id': 1,
            'title': 'Y2K Revival',
            'growth': '+23%',
            'trend': 'up',
            'description':
                'Low-rise jeans, metallic fabrics, and butterfly accessories making a comeback',
            'image': 'https://picsum.photos/400/400?random=1',
            'tags': ['retro', 'metallic', 'bold'],
            'engagement': 15420,
            'posts': 342,
          },
          {
            'id': 2,
            'title': 'Dark Academia',
            'growth': '+18%',
            'trend': 'up',
            'description':
                'Tweed blazers, plaid skirts, and vintage-inspired pieces for intellectual elegance',
            'image': 'https://picsum.photos/400/400?random=2',
            'tags': ['vintage', 'academic', 'sophisticated'],
            'engagement': 12890,
            'posts': 267,
          },
          {
            'id': 3,
            'title': 'Oversized Blazers',
            'growth': '+12%',
            'trend': 'up',
            'description':
                'Power dressing with relaxed silhouettes for modern professional wear',
            'image': 'https://picsum.photos/400/400?random=3',
            'tags': ['professional', 'oversized', 'power'],
            'engagement': 9876,
            'posts': 189,
          },
          {
            'id': 4,
            'title': 'Neon Colors',
            'growth': '-8%',
            'trend': 'down',
            'description':
                'Bright fluorescent colors losing momentum as neutrals take center stage',
            'image': 'https://picsum.photos/400/400?random=4',
            'tags': ['bright', 'bold', 'statement'],
            'engagement': 5432,
            'posts': 98,
          },
        ];
      });
    } catch (e) {
      print('❌ Failed to load trending now: $e');
      // Keep empty list if backend fails
    } finally {
      setState(() {
        _isLoadingTrendingNow = false;
      });
    }
  }

  // Load fashion insights from backend
  Future<void> _loadFashionInsights() async {
    if (_isLoadingFashionInsights) return;

    setState(() {
      _isLoadingFashionInsights = true;
    });

    try {
      // Note: Fashion insights endpoint might not be implemented yet
      // For now, we'll use default insights data
      setState(() {
        _fashionInsights = [
          {
            'id': 1,
            'title': 'Sustainable Fashion on the Rise',
            'description':
                'Consumers are increasingly choosing eco-friendly clothing options',
            'percentage': 67,
            'trend': 'up',
            'icon': LucideIcons.leaf,
            'color': Colors.green,
          },
          {
            'id': 2,
            'title': 'Minimalist Wardrobes',
            'description':
                'Capsule wardrobes and versatile pieces gaining popularity',
            'percentage': 45,
            'trend': 'up',
            'icon': LucideIcons.minimize2,
            'color': Colors.blue,
          },
          {
            'id': 3,
            'title': 'Second-Hand Shopping',
            'description':
                'Thrift stores and vintage shopping becoming mainstream',
            'percentage': 78,
            'trend': 'up',
            'icon': LucideIcons.repeat,
            'color': Colors.orange,
          },
        ];
      });
    } catch (e) {
      print('❌ Failed to load fashion insights: $e');
      // Keep empty list if backend fails
    } finally {
      setState(() {
        _isLoadingFashionInsights = false;
      });
    }
  }

  // Load influencer spotlight from backend
  Future<void> _loadInfluencerSpotlight() async {
    if (_isLoadingInfluencerSpotlight) return;

    setState(() {
      _isLoadingInfluencerSpotlight = true;
    });

    try {
      // Note: Influencer spotlight endpoint might not be implemented yet
      // For now, we'll use default influencer data
      setState(() {
        _influencerSpotlight = [
          {
            'id': 1,
            'name': 'Emma Chen',
            'handle': '@emmastyle',
            'followers': '2.4M',
            'specialty': 'Minimalist Fashion',
            'avatar': 'https://picsum.photos/100/100?random=10',
            'recentPost': 'https://picsum.photos/300/400?random=11',
            'engagement': '4.2%',
          },
          {
            'id': 2,
            'name': 'Marcus Rodriguez',
            'handle': '@marcusfashion',
            'followers': '1.8M',
            'specialty': 'Streetwear',
            'avatar': 'https://picsum.photos/100/100?random=12',
            'recentPost': 'https://picsum.photos/300/400?random=13',
            'engagement': '3.8%',
          },
        ];
      });
    } catch (e) {
      print('❌ Failed to load influencer spotlight: $e');
      // Keep empty list if backend fails
    } finally {
      setState(() {
        _isLoadingInfluencerSpotlight = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Trends',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: () => _loadTrendsData(),
          ),
          IconButton(
            icon: const Icon(LucideIcons.share2),
            onPressed: () {
              // Implement share functionality
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadTrendsData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeframe Selector
              Container(
                margin: const EdgeInsets.all(16),
                child: Row(
                  children:
                      _timeframes.map((timeframe) {
                        final isSelected =
                            _selectedTimeframe == timeframe['id'];
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedTimeframe = timeframe['id'];
                                });
                                _loadTrendsData(); // Reload data for new timeframe
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    isSelected ? Colors.black : Colors.white,
                                foregroundColor:
                                    isSelected ? Colors.white : Colors.black,
                                elevation: isSelected ? 2 : 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                timeframe['label'],
                                style: TextStyle(
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),

              // Trending Now Section
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Trending Now',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_trendingNow.length} trends',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              if (_isLoadingTrendingNow)
                const Center(child: CircularProgressIndicator())
              else if (_trendingNow.isEmpty)
                _buildEmptyState('No trending styles found')
              else
                ..._trendingNow.map((trend) => _buildTrendCard(trend)).toList(),

              const SizedBox(height: 24),

              // Fashion Insights Section
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Fashion Insights',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_fashionInsights.length} insights',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              if (_isLoadingFashionInsights)
                const Center(child: CircularProgressIndicator())
              else if (_fashionInsights.isEmpty)
                _buildEmptyState('No fashion insights available')
              else
                ..._fashionInsights
                    .map((insight) => _buildInsightCard(insight))
                    .toList(),

              const SizedBox(height: 24),

              // Influencer Spotlight Section
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Influencer Spotlight',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_influencerSpotlight.length} influencers',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              if (_isLoadingInfluencerSpotlight)
                const Center(child: CircularProgressIndicator())
              else if (_influencerSpotlight.isEmpty)
                _buildEmptyState('No influencers to spotlight')
              else
                ..._influencerSpotlight
                    .map((influencer) => _buildInfluencerCard(influencer))
                    .toList(),

              const SizedBox(height: 100), // Bottom padding
            ],
          ),
        ),
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
          Icon(LucideIcons.trendingUp, size: 48, color: Colors.grey.shade400),
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
            'Check back later for the latest trends',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendCard(Map<String, dynamic> trend) {
    final isUpTrend = trend['trend'] == 'up';

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
              trend['image'],
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: double.infinity,
                  height: 200,
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
                // Header with title and growth
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        trend['title'],
                        style: const TextStyle(
                          fontSize: 18,
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
                        color:
                            isUpTrend
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isUpTrend
                                ? LucideIcons.trendingUp
                                : LucideIcons.trendingDown,
                            size: 16,
                            color: isUpTrend ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            trend['growth'],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isUpTrend ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Description
                Text(
                  trend['description'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 12),

                // Tags
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children:
                      (trend['tags'] as List).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '#$tag',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                ),

                const SizedBox(height: 12),

                // Stats
                Row(
                  children: [
                    Icon(
                      LucideIcons.users,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${trend['engagement']} engagement',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      LucideIcons.image,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${trend['posts']} posts',
                      style: TextStyle(
                        fontSize: 12,
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
    );
  }

  Widget _buildInsightCard(Map<String, dynamic> insight) {
    final isUpTrend = insight['trend'] == 'up';

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
          // Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: insight['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(insight['icon'], color: insight['color'], size: 24),
          ),

          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight['title'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight['description'],
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      isUpTrend
                          ? LucideIcons.trendingUp
                          : LucideIcons.trendingDown,
                      size: 16,
                      color: isUpTrend ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${insight['percentage']}% of users',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
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

  Widget _buildInfluencerCard(Map<String, dynamic> influencer) {
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
          // Recent post image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Image.network(
              influencer['recentPost'],
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: double.infinity,
                  height: 200,
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
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(influencer['avatar']),
                  onBackgroundImageError: (exception, stackTrace) {
                    // Handle error
                  },
                ),

                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        influencer['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        influencer['handle'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        influencer['specialty'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Stats
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      influencer['followers'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'followers',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      influencer['engagement'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      'engagement',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Follow influencer
                    },
                    icon: const Icon(LucideIcons.plus, size: 16),
                    label: const Text('Follow'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () {
                    // View profile
                  },
                  icon: const Icon(LucideIcons.externalLink),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
