import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedCategoryIndex = 0;

  // Placeholder data
  final List<Map<String, dynamic>> _trendingPosts = [
    {
      'id': 1,
      'username': 'fashion_forward',
      'avatar':
          'https://api.dicebear.com/7.x/avataaars/png?seed=fashion_forward',
      'image':
          'https://via.placeholder.com/400x300/FF6B9D/FFFFFF?text=Minimalist+Look',
      'caption':
          'Minimalist office look that speaks volumes ✨ #minimalist #officewear #style',
      'likes': 1247,
      'comments': 89,
      'timeAgo': '1h ago',
      'style': 'minimalist',
      'verified': true,
    },
    {
      'id': 2,
      'username': 'street_style_mike',
      'avatar':
          'https://api.dicebear.com/7.x/avataaars/png?seed=street_style_mike',
      'image':
          'https://via.placeholder.com/400x300/4ECDC4/FFFFFF?text=Streetwear+Vibes',
      'caption':
          'Urban vibes for the city streets 🏙️ #streetwear #urban #fashion',
      'likes': 892,
      'comments': 45,
      'timeAgo': '3h ago',
      'style': 'streetwear',
      'verified': false,
    },
    {
      'id': 3,
      'username': 'boho_emma',
      'avatar': 'https://api.dicebear.com/7.x/avataaars/png?seed=boho_emma',
      'image':
          'https://via.placeholder.com/400x300/9B59B6/FFFFFF?text=Boho+Spirit',
      'caption': 'Summer boho vibes ☀️ #boho #summer #chic',
      'likes': 567,
      'comments': 23,
      'timeAgo': '5h ago',
      'style': 'boho',
      'verified': true,
    },
  ];

  final List<Map<String, dynamic>> _styleCategories = [
    {'name': 'All', 'icon': LucideIcons.grid, 'color': Colors.blue},
    {'name': 'Minimalist', 'icon': LucideIcons.minus, 'color': Colors.grey},
    {'name': 'Streetwear', 'icon': LucideIcons.zap, 'color': Colors.orange},
    {'name': 'Boho', 'icon': LucideIcons.flower, 'color': Colors.pink},
    {'name': 'Preppy', 'icon': LucideIcons.bookOpen, 'color': Colors.green},
    {'name': 'Grunge', 'icon': LucideIcons.music, 'color': Colors.purple},
  ];

  final List<Map<String, dynamic>> _featuredCreators = [
    {
      'username': 'style_sarah',
      'avatar': 'https://api.dicebear.com/7.x/avataaars/png?seed=style_sarah',
      'followers': '12.5K',
      'posts': 234,
      'verified': true,
      'style': 'minimalist',
    },
    {
      'username': 'fashion_mike',
      'avatar': 'https://api.dicebear.com/7.x/avataaars/png?seed=fashion_mike',
      'followers': '8.9K',
      'posts': 156,
      'verified': false,
      'style': 'streetwear',
    },
    {
      'username': 'trendy_emma',
      'avatar': 'https://api.dicebear.com/7.x/avataaars/png?seed=trendy_emma',
      'followers': '15.2K',
      'posts': 312,
      'verified': true,
      'style': 'boho',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: scheme.surface,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.surface,
                      scheme.surface.withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
            ),
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [scheme.primary, scheme.tertiary],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    LucideIcons.compass,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Explore',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
            leading: IconButton(
              icon: Icon(LucideIcons.chevronLeft, color: scheme.onSurface),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/dashboard');
                }
              },
            ),
            actions: [
              IconButton(
                icon: Icon(LucideIcons.search, color: scheme.onSurface),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(LucideIcons.bell, color: scheme.onSurface),
                onPressed: () {},
              ),
            ],
          ),

          // Main Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Style Categories
                  _buildStyleCategories(theme, scheme),
                  const SizedBox(height: 32),

                  // Featured Creators
                  _buildFeaturedCreators(theme, scheme),
                  const SizedBox(height: 32),

                  // Content Tabs
                  _buildContentTabs(theme, scheme),
                  const SizedBox(height: 24),

                  // Tab Content
                  SizedBox(
                    height: 600, // Fixed height for demo
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTrendingTab(theme, scheme),
                        _buildFollowingTab(theme, scheme),
                        _buildNearbyTab(theme, scheme),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleCategories(ThemeData theme, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Style Categories',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _styleCategories.length,
            itemBuilder: (context, index) {
              final category = _styleCategories[index];
              final isSelected = _selectedCategoryIndex == index;

              return GestureDetector(
                onTap: () => setState(() => _selectedCategoryIndex = index),
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? scheme.primary : scheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          isSelected
                              ? scheme.primary
                              : scheme.outline.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        category['icon'],
                        color:
                            isSelected ? scheme.onPrimary : category['color'],
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category['name'],
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              isSelected ? scheme.onPrimary : scheme.onSurface,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: (50 * index).ms).slideX(begin: 0.2);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedCreators(ThemeData theme, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Featured Creators',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _featuredCreators.length,
            itemBuilder: (context, index) {
              final creator = _featuredCreators[index];

              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: scheme.outline.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundImage: NetworkImage(creator['avatar']),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        creator['username'],
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: scheme.onSurface,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (creator['verified']) ...[
                                      const SizedBox(width: 2),
                                      Icon(
                                        LucideIcons.checkCircle,
                                        size: 12,
                                        color: scheme.primary,
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  creator['followers'],
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurface.withValues(
                                      alpha: 0.6,
                                    ),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            side: BorderSide(color: scheme.primary),
                            minimumSize: const Size(0, 28),
                          ),
                          child: Text(
                            'Follow',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: 0.3);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContentTabs(ThemeData theme, ColorScheme scheme) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: scheme.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        labelColor: scheme.onPrimary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        labelStyle: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'Trending'),
          Tab(text: 'Following'),
          Tab(text: 'Nearby'),
        ],
      ),
    );
  }

  Widget _buildTrendingTab(ThemeData theme, ColorScheme scheme) {
    return ListView.builder(
      itemCount: _trendingPosts.length,
      itemBuilder: (context, index) {
        final post = _trendingPosts[index];
        return _buildSocialPost(post, theme, scheme);
      },
    );
  }

  Widget _buildFollowingTab(ThemeData theme, ColorScheme scheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.users,
            size: 64,
            color: scheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Follow creators to see their posts',
            style: theme.textTheme.titleMedium?.copyWith(
              color: scheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Discover amazing style inspiration',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyTab(ThemeData theme, ColorScheme scheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.mapPin,
            size: 64,
            color: scheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Enable location to see nearby posts',
            style: theme.textTheme.titleMedium?.copyWith(
              color: scheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Find style inspiration in your area',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialPost(
    Map<String, dynamic> post,
    ThemeData theme,
    ColorScheme scheme,
  ) {
    return Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: scheme.outline.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(post['avatar']),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                post['username'],
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: scheme.onSurface,
                                ),
                              ),
                              if (post['verified'])
                                Icon(
                                  LucideIcons.checkCircle,
                                  size: 14,
                                  color: scheme.primary,
                                ),
                            ],
                          ),
                          Text(
                            post['timeAgo'],
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        post['style'],
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Image.network(
                  post['image'],
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.cover,
                ),
              ),

              // Actions
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            LucideIcons.heart,
                            color: scheme.onSurface.withValues(alpha: 0.8),
                          ),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: Icon(
                            LucideIcons.messageCircle,
                            color: scheme.onSurface.withValues(alpha: 0.8),
                          ),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: Icon(
                            LucideIcons.share2,
                            color: scheme.onSurface.withValues(alpha: 0.8),
                          ),
                          onPressed: () {},
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            LucideIcons.bookmark,
                            color: scheme.onSurface.withValues(alpha: 0.8),
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                    Text(
                      '${post['likes']} likes',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface,
                        ),
                        children: [
                          TextSpan(
                            text: post['username'],
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const TextSpan(text: ' '),
                          TextSpan(text: post['caption']),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'View all ${post['comments']} comments',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: (200 * (post['id'] as int)).ms)
        .slideY(begin: 0.3);
  }
}
