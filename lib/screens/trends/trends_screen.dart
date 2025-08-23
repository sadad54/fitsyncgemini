// lib/screens/trends/trends_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fitsyncgemini/widgets/common/fitsync_assets.dart';
import 'package:fitsyncgemini/services/MLAPI_service.dart';
import 'package:fitsyncgemini/services/location_service.dart';
import 'package:fitsyncgemini/constants/app_colors.dart';

class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key});

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  String _selectedScope = 'global';
  String _selectedTimeframe = 'week';
  bool _isLoadingTrendingNow = false;
  bool _isLoadingFashionInsights = false;
  bool _isLoadingInfluencerSpotlight = false;
  String _localLabel = 'New York';
  final LocationService _locationService = LocationService();

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
    _autoSetLocalScope();
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'Filter Trends',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'Scope',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildScopeButton(
                        'global',
                        'Global',
                        LucideIcons.globe,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildScopeButton(
                        'local',
                        _localLabel,
                        LucideIcons.mapPin,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Text(
                  'Timeframe',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildTimeframeButton('day', 'Today')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildTimeframeButton('week', 'This Week')),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTimeframeButton('month', 'This Month'),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _autoSetLocalScope() async {
    try {
      final hasPerm = await _locationService.hasLocationPermission();
      if (!hasPerm) {
        await _locationService.getCurrentLocationWithGeolocator();
      }
      final loc = await _locationService.getCurrentLocationWithGeolocator();
      if (loc != null) {
        setState(() {
          _localLabel = loc.city.isNotEmpty ? loc.city : 'Local';
          _selectedScope = 'local';
        });
        await _loadTrendsData();
      }
    } catch (_) {
      // Keep global if permission denied
    }
  }

  Widget _buildScopeButton(String id, String label, IconData icon) {
    final bool isSelected = _selectedScope == id;
    return ElevatedButton.icon(
      onPressed: () {
        setState(() => _selectedScope = id);
        _loadTrendsData();
      },
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isSelected
                ? AppColors.primary
                : Theme.of(context).colorScheme.surface,
        foregroundColor:
            isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
        elevation: isSelected ? 2 : 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color:
                isSelected
                    ? AppColors.primary
                    : Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeframeButton(String id, String label) {
    final bool isSelected = _selectedTimeframe == id;
    return ElevatedButton.icon(
      onPressed: () {
        setState(() => _selectedTimeframe = id);
        _loadTrendsData();
      },
      icon: const Icon(LucideIcons.calendar, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isSelected
                ? AppColors.secondary
                : Theme.of(context).colorScheme.surface,
        foregroundColor:
            isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
        elevation: isSelected ? 2 : 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color:
                isSelected
                    ? AppColors.secondary
                    : Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
      ),
    );
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
      final resp = await MLAPIService.getFashionInsights(
        scope: _selectedScope,
        timeframe: _selectedTimeframe,
      );
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.background,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar with back button
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: scheme.surface,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(LucideIcons.arrowLeft, color: scheme.onSurface),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/dashboard');
                }
              },
            ),
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    LucideIcons.trendingUp,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Trends',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(LucideIcons.filter, color: scheme.onSurface),
                onPressed: _openFilterSheet,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [scheme.surface, scheme.surface.withOpacity(0.8)],
                  ),
                ),
              ),
            ),
          ),

          // Filter Section
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: scheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "What's hot in fashion",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildScopeButton(
                          'global',
                          'Global',
                          LucideIcons.globe,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildScopeButton(
                          'local',
                          _localLabel,
                          LucideIcons.mapPin,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildTimeframeButton('day', 'Today')),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTimeframeButton('week', 'This Week'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTimeframeButton('month', 'This Month'),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
          ),

          // Trending Now Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Trending Now',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_trendingNow.length} trends',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms, delay: 100.ms),
          ),

          // Trending Cards
          if (_isLoadingTrendingNow)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          else if (_trendingNow.isEmpty)
            SliverToBoxAdapter(
              child: _buildEmptyState('No trending styles found'),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildTrendCard(_trendingNow[index])
                    .animate()
                    .fadeIn(duration: 300.ms, delay: (200 + index * 100).ms)
                    .slideX(begin: 0.1, end: 0),
                childCount: _trendingNow.length,
              ),
            ),

          // Fashion Insights Section
          SliverToBoxAdapter(
            child: _buildFashionInsightsCard().animate().fadeIn(
              duration: 300.ms,
              delay: 400.ms,
            ),
          ),

          // Influencer Spotlight Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Influencer Spotlight',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_influencerSpotlight.length} influencers',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms, delay: 500.ms),
          ),

          // Influencer Cards
          if (_isLoadingInfluencerSpotlight)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          else if (_influencerSpotlight.isEmpty)
            SliverToBoxAdapter(
              child: _buildEmptyState('No influencers to spotlight'),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _buildInfluencerCard(_influencerSpotlight[index])
                        .animate()
                        .fadeIn(duration: 300.ms, delay: (600 + index * 100).ms)
                        .slideX(begin: 0.1, end: 0),
                childCount: _influencerSpotlight.length,
              ),
            ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              LucideIcons.trendingUp,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for the latest trends',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: scheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendCard(Map<String, dynamic> trend) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isUpTrend = trend['trend'] == 'up';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with gradient overlay
          Stack(
            children: [
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
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            scheme.surface,
                            scheme.surface.withOpacity(0.8),
                          ],
                        ),
                      ),
                      child: Icon(
                        LucideIcons.image,
                        size: 48,
                        color: scheme.onSurface.withOpacity(0.3),
                      ),
                    );
                  },
                ),
              ),
              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
              ),
              // Trend indicator
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isUpTrend ? AppColors.success : AppColors.error,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isUpTrend
                            ? LucideIcons.trendingUp
                            : LucideIcons.trendingDown,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        trend['growth'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  trend['title'],
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 8),

                // Description
                Text(
                  trend['description'],
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurface.withOpacity(0.7),
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
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '#$tag',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
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
                      color: scheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${trend['engagement']} engagement',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      LucideIcons.image,
                      size: 16,
                      color: scheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${trend['posts']} posts',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withOpacity(0.5),
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

  Widget _buildFashionInsightsCard() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Fashion Insights',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.tertiary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_fashionInsights.length} insights',
                  style: TextStyle(
                    color: AppColors.tertiary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingFashionInsights)
            const Center(child: CircularProgressIndicator())
          else if (_fashionInsights.isEmpty)
            _buildEmptyState('No fashion insights available')
          else
            Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: scheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.tertiary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            LucideIcons.barChart3,
                            color: AppColors.tertiary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Fashion Insights',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ..._fashionInsights.asMap().entries.map((entry) {
                      final insight = entry.value;
                      final category = (insight['category'] ?? '').toString();
                      final trending =
                          (insight['trending'] as List).cast<String>();
                      final declining =
                          (insight['declining'] as List).cast<String>();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: scheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _capitalize(category),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Trending
                            Row(
                              children: [
                                Icon(
                                  LucideIcons.trendingUp,
                                  size: 16,
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Trending:',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurface.withOpacity(0.7),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children:
                                  trending
                                      .map(
                                        (t) => _chip(
                                          t,
                                          bg: AppColors.success.withOpacity(
                                            0.1,
                                          ),
                                          fg: AppColors.success,
                                          icon: LucideIcons.trendingUp,
                                        ),
                                      )
                                      .toList(),
                            ),
                            const SizedBox(height: 12),
                            // Declining
                            Row(
                              children: [
                                Icon(
                                  LucideIcons.trendingDown,
                                  size: 16,
                                  color: AppColors.error,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Declining:',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurface.withOpacity(0.7),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children:
                                  declining
                                      .map(
                                        (d) => _chip(
                                          d,
                                          bg: AppColors.error.withOpacity(0.1),
                                          fg: AppColors.error,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfluencerCard(Map<String, dynamic> influencer) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent post image with gradient overlay
          Stack(
            children: [
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
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            scheme.surface,
                            scheme.surface.withOpacity(0.8),
                          ],
                        ),
                      ),
                      child: Icon(
                        LucideIcons.image,
                        size: 48,
                        color: scheme.onSurface.withOpacity(0.3),
                      ),
                    );
                  },
                ),
              ),
              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.secondary, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.network(
                      influencer['avatar'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: scheme.surfaceVariant,
                          child: Icon(
                            LucideIcons.user,
                            color: scheme.onSurface.withOpacity(0.5),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        influencer['name'],
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        influencer['handle'],
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        influencer['specialty'],
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withOpacity(0.5),
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
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'followers',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      influencer['engagement'],
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                    Text(
                      'engagement',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withOpacity(0.5),
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Following ${influencer['name']}'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                    icon: const Icon(LucideIcons.plus, size: 16),
                    label: const Text('Follow'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () {
                    // View profile
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Opening ${influencer['name']}\'s profile',
                        ),
                        backgroundColor: AppColors.secondary,
                      ),
                    );
                  },
                  icon: const Icon(LucideIcons.externalLink),
                  style: IconButton.styleFrom(
                    backgroundColor: scheme.surfaceVariant,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
