import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fitsyncgemini/constants/app_colors.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _greeting = '';
  int _selectedTabIndex = 0;

  // Placeholder data
  final List<Map<String, dynamic>> _stylePosts = [
    {
      'id': '1',
      'username': 'style_sarah',
      'avatar': 'https://picsum.photos/150/150?random=1',
      'image': 'https://picsum.photos/400/300?random=2',
      'caption': 'Minimalist vibes for the office ✨ #minimalist #officewear',
      'likes': 234,
      'comments': 12,
      'timeAgo': '2h ago',
      'style': 'minimalist',
      'verified': true,
    },
    {
      'id': '2',
      'username': 'fashion_mike',
      'avatar': 'https://picsum.photos/150/150?random=3',
      'image': 'https://picsum.photos/400/300?random=4',
      'caption': 'Streetwear essentials 🏙️ #streetwear #urban',
      'likes': 567,
      'comments': 28,
      'timeAgo': '4h ago',
      'style': 'streetwear',
      'verified': true,
    },
    {
      'id': '3',
      'username': 'trendy_emma',
      'avatar': 'https://picsum.photos/150/150?random=5',
      'image': 'https://picsum.photos/400/300?random=6',
      'caption': 'Boho chic for summer ☀️ #boho #summerstyle',
      'likes': 189,
      'comments': 8,
      'timeAgo': '6h ago',
      'style': 'boho',
      'verified': false,
    },
  ];

  final List<Map<String, dynamic>> _trendingStyles = [
    {'name': 'Minimalist', 'posts': 1247, 'growth': '+23%'},
    {'name': 'Streetwear', 'posts': 892, 'growth': '+18%'},
    {'name': 'Boho', 'posts': 567, 'growth': '+12%'},
    {'name': 'Preppy', 'posts': 445, 'growth': '+8%'},
  ];

  // Core features prioritized
  final List<Map<String, dynamic>> _coreFeatures = [
    {
      'icon': LucideIcons.camera,
      'title': 'Virtual Try-On',
      'subtitle': 'See how clothes look on you',
      'color': Colors.blue,
      'route': '/try-on',
      'gradient': [Colors.blue, Colors.cyan],
    },
    {
      'icon': LucideIcons.sparkles,
      'title': 'AI Outfit Generator',
      'subtitle': 'Get personalized outfit suggestions',
      'color': Colors.purple,
      'route': '/outfit-suggestions',
      'gradient': [Colors.purple, Colors.pink],
    },
    {
      'icon': LucideIcons.shirt,
      'title': 'Wardrobe Manager',
      'subtitle': 'Organize your clothing collection',
      'color': Colors.green,
      'route': '/closet',
      'gradient': [Colors.green, Colors.teal],
    },
    {
      'icon': LucideIcons.trendingUp,
      'title': 'Style Analytics',
      'subtitle': 'Track your fashion journey',
      'color': Colors.orange,
      'route': '/trends',
      'gradient': [Colors.orange, Colors.red],
    },
  ];

  final List<Map<String, dynamic>> _quickActions = [
    {'icon': LucideIcons.search, 'title': 'Find Items', 'color': Colors.indigo},
    {'icon': LucideIcons.plus, 'title': 'Add New Item', 'color': Colors.green},
    {'icon': LucideIcons.users, 'title': 'Community', 'color': Colors.pink},
    {'icon': LucideIcons.mapPin, 'title': 'Nearby', 'color': Colors.amber},
    {'icon': LucideIcons.settings, 'title': 'Settings', 'color': Colors.grey},
  ];

  @override
  void initState() {
    super.initState();
    _updateGreeting();
  }

  void _updateGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _greeting = 'Good morning';
    } else if (hour < 17) {
      _greeting = 'Good afternoon';
    } else {
      _greeting = 'Good evening';
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
          // Futuristic App Bar
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
                    colors: [scheme.surface, scheme.surface.withOpacity(0.8)],
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
                    LucideIcons.sparkles,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'FitSync',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(LucideIcons.search, color: scheme.onSurface),
                onPressed: () {
                  context.go('/explore');
                },
              ),
              IconButton(
                icon: Icon(LucideIcons.bell, color: scheme.onSurface),
                onPressed: () {},
              ),
              Container(
                margin: const EdgeInsets.only(right: 16),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: scheme.primary,
                  child: Text(
                    'JS',
                    style: TextStyle(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
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
                  // Greeting Section
                  _buildGreetingSection(theme, scheme),
                  const SizedBox(height: 32),

                  // Core Features - Prioritized
                  _buildCoreFeatures(theme, scheme),
                  const SizedBox(height: 32),

                  // Quick Actions
                  _buildQuickActions(theme, scheme),
                  const SizedBox(height: 32),

                  // Style Feed Tabs
                  _buildStyleFeedTabs(theme, scheme),
                  const SizedBox(height: 24),

                  // Content based on selected tab
                  _buildTabContent(theme, scheme),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(theme, scheme),
    );
  }

  Widget _buildGreetingSection(ThemeData theme, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$_greeting, John',
          style: theme.textTheme.displayLarge?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.3),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: scheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: scheme.primary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.sparkles, size: 16, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                'Minimalist Style • 47 items',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2),
      ],
    );
  }

  Widget _buildCoreFeatures(ThemeData theme, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Core Features',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemCount: _coreFeatures.length,
          itemBuilder: (context, index) {
            final feature = _coreFeatures[index];
            return _buildCoreFeatureCard(feature, theme, scheme, index);
          },
        ),
      ],
    );
  }

  Widget _buildCoreFeatureCard(
    Map<String, dynamic> feature,
    ThemeData theme,
    ColorScheme scheme,
    int index,
  ) {
    final List<Color> gradientColors =
        (feature['gradient'] as List).cast<Color>();

    return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradientColors[0].withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            onTap: () => context.go(feature['route']),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(feature['icon'], color: Colors.white, size: 24),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature['title'],
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        feature['subtitle'],
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: (100 * index).ms)
        .scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildQuickActions(ThemeData theme, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: _quickActions.length,
          itemBuilder: (context, index) {
            final action = _quickActions[index];
            return _buildQuickActionCard(action, theme, scheme, index);
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    Map<String, dynamic> action,
    ThemeData theme,
    ColorScheme scheme,
    int index,
  ) {
    return Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: scheme.outline.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: () {
              if (action['title'] == 'Nearby') {
                context.go('/nearby');
              } else if (action['title'] == 'Find Items') {
                context.go('/explore');
              } else if (action['title'] == 'Add New Item') {
                context.go('/closet');
              } else if (action['title'] == 'Community') {
                context.go('/community');
              } else if (action['title'] == 'Settings') {
                context.go('/settings');
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: action['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      action['icon'],
                      color: action['color'],
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    action['title'],
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: (100 * index).ms)
        .scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildStyleFeedTabs(ThemeData theme, ColorScheme scheme) {
    final tabs = ['For You', 'Trending', 'Following', 'Nearby'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Style Feed',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: scheme.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: tabs.length,
            itemBuilder: (context, index) {
              final isSelected = _selectedTabIndex == index;
              return GestureDetector(
                onTap: () {
                  if (tabs[index] == 'Nearby') {
                    context.go('/nearby');
                  } else {
                    setState(() => _selectedTabIndex = index);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.all(4),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? scheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      tabs[index],
                      style: theme.textTheme.labelMedium?.copyWith(
                        color:
                            isSelected
                                ? scheme.onPrimary
                                : scheme.onSurfaceVariant,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent(ThemeData theme, ColorScheme scheme) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildForYouFeed(theme, scheme);
      case 1:
        return _buildTrendingFeed(theme, scheme);
      case 2:
        return _buildFollowingFeed(theme, scheme);
      case 3:
        return _buildNearbyFeed(theme, scheme);
      default:
        return _buildForYouFeed(theme, scheme);
    }
  }

  Widget _buildForYouFeed(ThemeData theme, ColorScheme scheme) {
    return Column(
      children:
          _stylePosts
              .map((post) => _buildStylePost(post, theme, scheme))
              .toList(),
    );
  }

  Widget _buildTrendingFeed(ThemeData theme, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trending Styles',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        ..._trendingStyles.map(
          (style) => _buildTrendingStyleCard(style, theme, scheme),
        ),
      ],
    );
  }

  Widget _buildFollowingFeed(ThemeData theme, ColorScheme scheme) {
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
            'Follow your favorite stylists',
            style: theme.textTheme.titleMedium?.copyWith(
              color: scheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyFeed(ThemeData theme, ColorScheme scheme) {
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
            'Discover local style inspiration',
            style: theme.textTheme.titleMedium?.copyWith(
              color: scheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStylePost(
    Map<String, dynamic> post,
    ThemeData theme,
    ColorScheme scheme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withOpacity(0.3), width: 1),
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
                  onBackgroundImageError: (exception, stackTrace) {
                    // Handle avatar loading error silently
                  },
                  child:
                      post['avatar'] == null
                          ? Text(
                            post['username'][0].toUpperCase(),
                            style: TextStyle(
                              color: scheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                          : null,
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
                          if (post['verified'] == true) ...[
                            const SizedBox(width: 4),
                            Icon(
                              LucideIcons.checkCircle,
                              size: 16,
                              color: scheme.primary,
                            ),
                          ],
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
                    color: scheme.primary.withOpacity(0.1),
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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Image.network(
              post['image'],
              width: double.infinity,
              height: 300,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: double.infinity,
                  height: 300,
                  color: scheme.surfaceVariant,
                  child: Icon(
                    LucideIcons.image,
                    size: 64,
                    color: scheme.onSurface.withOpacity(0.5),
                  ),
                );
              },
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
                        color: scheme.onSurface.withOpacity(0.8),
                      ),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: Icon(
                        LucideIcons.messageCircle,
                        color: scheme.onSurface.withOpacity(0.8),
                      ),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: Icon(
                        LucideIcons.share2,
                        color: scheme.onSurface.withOpacity(0.8),
                      ),
                      onPressed: () {},
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        LucideIcons.bookmark,
                        color: scheme.onSurface.withOpacity(0.8),
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
                    color: scheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3);
  }

  Widget _buildTrendingStyleCard(
    Map<String, dynamic> style,
    ThemeData theme,
    ColorScheme scheme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              LucideIcons.trendingUp,
              color: scheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  style['name'],
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                Text(
                  '${style['posts']} posts',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: scheme.tertiary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              style['growth'],
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.tertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(ThemeData theme, ColorScheme scheme) {
    return FloatingActionButton(
      onPressed: () => context.go('/try-on'),
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 0,
      child: const Icon(LucideIcons.camera, size: 24),
    );
  }
}
