// lib/screens/trends/trends_screen_new.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fitsyncgemini/widgets/common/fitsync_assets.dart';
import 'package:fitsyncgemini/constants/app_colors.dart';
import 'package:fitsyncgemini/services/MLAPI_service.dart';

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
      final resp = await MLAPIService.getFashionInsights();
      final insights = resp['insights'] as List<dynamic>?;
      if (insights != null) {
        setState(() {
          _fashionInsights =
              insights
                  .map(
                    (e) => {
                      'category': e['category'] ?? '',
                      'trending': List<String>.from(e['trending'] ?? const []),
                      'declining': List<String>.from(
                        e['declining'] ?? const [],
                      ),
                    },
                  )
                  .toList();
        });
      }
    } catch (e) {
      // Keep empty list if backend fails
      debugPrint('❌ Failed to load fashion insights: $e');
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              // Fallback to dashboard route
              // ignore: use_build_context_synchronously
              // Using WidgetsBinding to ensure context is valid
              Future.microtask(() {
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/dashboard');
                }
              });
            }
          },
        ),
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

              // Fashion Insights Section (React parity)
              _buildFashionInsightsSection(),

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
          FitSyncFeatureIcon(type: 'trends', size: 32, container: 60),
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

  // Old card builder removed; replaced by React-styled section

  Widget _buildFashionInsightsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Fashion Insights',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                '${_fashionInsights.length} insights',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_isLoadingFashionInsights)
            const Center(child: CircularProgressIndicator())
          else if (_fashionInsights.isEmpty)
            _buildEmptyState('No fashion insights available')
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(
                          LucideIcons.trendingUp,
                          color: AppColors.teal,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Fashion Insights',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._fashionInsights.asMap().entries.map((entry) {
                      final insight = entry.value;
                      final category = (insight['category'] ?? '').toString();
                      final trending =
                          (insight['trending'] as List).cast<String>();
                      final declining =
                          (insight['declining'] as List).cast<String>();
                      return Container(
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(color: AppColors.pink, width: 4),
                          ),
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.only(left: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _capitalize(category),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Trending
                            const Text(
                              'Trending:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children:
                                  trending
                                      .map(
                                        (t) => _chip(
                                          t,
                                          bg: const Color(0xFFE6F4EA),
                                          fg: const Color(0xFF166534),
                                          icon: LucideIcons.trendingUp,
                                        ),
                                      )
                                      .toList(),
                            ),
                            const SizedBox(height: 8),
                            // Declining
                            const Text(
                              'Declining:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children:
                                  declining
                                      .map(
                                        (d) => _chip(
                                          d,
                                          bg: const Color(0xFFFEE2E2),
                                          fg: const Color(0xFF991B1B),
                                          icon: LucideIcons.trendingDown,
                                        ),
                                      )
                                      .toList(),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _capitalize(String v) {
    if (v.isEmpty) return v;
    return v[0].toUpperCase() + v.substring(1);
  }

  Widget _chip(
    String text, {
    required Color bg,
    required Color fg,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, color: fg)),
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
