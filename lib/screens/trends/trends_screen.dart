// lib/screens/trends/trends_screen_new.dart
import 'package:flutter/material.dart';
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
  String selectedScope = 'global';
  String selectedTimeframe = 'week';

  final List<Map<String, dynamic>> scopes = [
    {'id': 'global', 'label': 'Global', 'icon': LucideIcons.globe},
    {'id': 'local', 'label': 'New York', 'icon': LucideIcons.mapPin},
  ];

  final List<Map<String, dynamic>> timeframes = [
    {'id': 'day', 'label': 'Today'},
    {'id': 'week', 'label': 'This Week'},
    {'id': 'month', 'label': 'This Month'},
  ];

  final List<Map<String, dynamic>> trendingNow = [
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

  final List<Map<String, dynamic>> fashionInsights = [
    {
      'category': 'Colors',
      'trending': ['Sage Green', 'Warm Beige', 'Soft Lavender'],
      'declining': ['Hot Pink', 'Electric Blue'],
    },
    {
      'category': 'Silhouettes',
      'trending': ['Oversized', 'High-waisted', 'Cropped'],
      'declining': ['Bodycon', 'Low-rise'],
    },
    {
      'category': 'Fabrics',
      'trending': ['Corduroy', 'Velvet', 'Organic Cotton'],
      'declining': ['Polyester Blends', 'Shiny Materials'],
    },
  ];

  final List<Map<String, dynamic>> influencerSpotlight = [
    {
      'name': 'Emma Chamberlain',
      'handle': '@emmachamberlain',
      'trendSetter': 'Vintage Mix',
      'followers': '12.2M',
      'engagement': '8.4%',
      'recentTrend': 'Thrifted Designer Mix',
    },
    {
      'name': 'Wisdom Kaye',
      'handle': '@wisdomkaye',
      'trendSetter': 'Gender-Fluid Fashion',
      'followers': '2.1M',
      'engagement': '12.1%',
      'recentTrend': 'Colorful Maximalism',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [_buildSliverAppBar(), _buildSliverContent()],
      ),
    );
  }

  Widget _buildTrendImage(String imageUrl, String title) {
    // Create a simple colored container with an icon as fallback
    final colors = [
      AppColors.pink,
      AppColors.teal,
      AppColors.purple,
      AppColors.blue,
    ];
    final color = colors[title.hashCode % colors.length];

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: color.withOpacity(0.1),
      child: Icon(LucideIcons.shirt, color: color, size: 32),
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
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trends',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            'What\'s hot in fashion',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
      actions: [
        IconButton(icon: const Icon(LucideIcons.filter), onPressed: () {}),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            children: [
              // Scope Selectors
              Row(
                children:
                    scopes.map((scope) {
                      final isSelected = selectedScope == scope['id'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              selectedScope = scope['id'];
                            });
                          },
                          icon: Icon(scope['icon'], size: 16),
                          label: Text(scope['label']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isSelected ? AppColors.pink : Colors.white,
                            foregroundColor:
                                isSelected
                                    ? Colors.white
                                    : Colors.grey.shade700,
                            elevation: 0,
                            side: BorderSide(
                              color:
                                  isSelected
                                      ? AppColors.pink
                                      : Colors.grey.shade300,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 12),
              // Timeframe Selectors
              Row(
                children:
                    timeframes.map((timeframe) {
                      final isSelected = selectedTimeframe == timeframe['id'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              selectedTimeframe = timeframe['id'];
                            });
                          },
                          icon: const Icon(LucideIcons.calendar, size: 16),
                          label: Text(timeframe['label']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isSelected ? AppColors.teal : Colors.white,
                            foregroundColor:
                                isSelected
                                    ? Colors.white
                                    : Colors.grey.shade700,
                            elevation: 0,
                            side: BorderSide(
                              color:
                                  isSelected
                                      ? AppColors.teal
                                      : Colors.grey.shade300,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverContent() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTrendingAlert(),
            const SizedBox(height: 24),
            _buildTrendingNowSection(),
            const SizedBox(height: 24),
            _buildFashionInsights(),
            const SizedBox(height: 24),
            _buildInfluencerSpotlight(),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingAlert() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.pink.withOpacity(0.1),
            AppColors.teal.withOpacity(0.1),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.pink,
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.zap, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trending Alert',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '3 new trends detected in your style category',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('View All'),
          ),
        ],
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 600));
  }

  Widget _buildTrendingNowSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Trending Now',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...trendingNow.map((trend) => _buildTrendCard(trend)).toList(),
      ],
    );
  }

  Widget _buildTrendCard(Map<String, dynamic> trend) {
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
      child: Row(
        children: [
          // Image
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: _buildTrendImage(trend['image'], trend['title']),
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          trend['title'],
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            trend['trend'] == 'up'
                                ? LucideIcons.trendingUp
                                : LucideIcons.trendingDown,
                            size: 16,
                            color:
                                trend['trend'] == 'up'
                                    ? Colors.green.shade600
                                    : Colors.red.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            trend['growth'],
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color:
                                  trend['trend'] == 'up'
                                      ? Colors.green.shade600
                                      : Colors.red.shade600,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(LucideIcons.share, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    trend['description'],
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    children:
                        (trend['tags'] as List<String>).map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(LucideIcons.eye, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        trend['engagement'].toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        LucideIcons.heart,
                        size: 12,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        trend['posts'].toString(),
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
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: trend['id'] * 100));
  }

  Widget _buildFashionInsights() {
    return Container(
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(LucideIcons.trendingUp, color: AppColors.teal, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Fashion Insights',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          ...fashionInsights
              .map((insight) => _buildInsightItem(insight))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildInsightItem(Map<String, dynamic> insight) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.pink, width: 4)),
      ),
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            insight['category'],
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          // Trending items
          Text(
            'Trending:',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            children:
                (insight['trending'] as List<String>).map((item) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.trendingUp,
                          size: 12,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 8),
          // Declining items
          Text(
            'Declining:',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            children:
                (insight['declining'] as List<String>).map((item) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.trendingDown,
                          size: 12,
                          color: Colors.red.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfluencerSpotlight() {
    return Container(
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(LucideIcons.zap, color: AppColors.purple, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Trendsetter Spotlight',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          ...influencerSpotlight
              .map((influencer) => _buildInfluencerItem(influencer))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildInfluencerItem(Map<String, dynamic> influencer) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  influencer['name'],
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  influencer['handle'],
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                Text(
                  'Setting: ${influencer['recentTrend']}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.pink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                influencer['followers'],
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                '${influencer['engagement']} engagement',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
