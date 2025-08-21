import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isFollowing = false;

  // Placeholder user data
  final Map<String, dynamic> _userProfile = {
    'id': 'user_123',
    'username': 'style_sarah',
    'fullName': 'Sarah Johnson',
    'avatar':
        'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=150',
    'bio': 'Minimalist fashion enthusiast ✨ Sharing clean, timeless style',
    'location': 'New York, NY',
    'website': 'style-sarah.com',
    'followers': 1247,
    'following': 892,
    'posts': 234,
    'verified': true,
    'style': 'minimalist',
    'joined': '2022',
  };

  final List<Map<String, dynamic>> _userPosts = [
    {
      'id': '1',
      'image':
          'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400',
      'caption': 'Minimalist vibes for the office ✨ #minimalist #officewear',
      'likes': 234,
      'comments': 12,
      'timeAgo': '2h ago',
    },
    {
      'id': '2',
      'image':
          'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=400',
      'caption': 'Weekend casual look 🏙️ #casual #weekend',
      'likes': 189,
      'comments': 8,
      'timeAgo': '1d ago',
    },
    {
      'id': '3',
      'image':
          'https://images.unsplash.com/photo-1485230895905-ec40ba36b9bc?w=400',
      'caption': 'Summer essentials ☀️ #summer #essentials',
      'likes': 156,
      'comments': 5,
      'timeAgo': '3d ago',
    },
  ];

  final List<Map<String, dynamic>> _userOutfits = [
    {
      'id': '1',
      'name': 'Office Minimalist',
      'image':
          'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400',
      'likes': 89,
      'items': 4,
    },
    {
      'id': '2',
      'name': 'Weekend Casual',
      'image':
          'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=400',
      'likes': 67,
      'items': 3,
    },
    {
      'id': '3',
      'name': 'Summer Boho',
      'image':
          'https://images.unsplash.com/photo-1485230895905-ec40ba36b9bc?w=400',
      'likes': 45,
      'items': 5,
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
      backgroundColor: scheme.background,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
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
                    LucideIcons.user,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Profile',
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
                icon: Icon(LucideIcons.settings, color: scheme.onSurface),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(LucideIcons.share2, color: scheme.onSurface),
                onPressed: () {},
              ),
            ],
          ),

          // Profile Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  _buildProfileHeader(theme, scheme),
                  const SizedBox(height: 32),

                  // Stats Row
                  _buildStatsRow(theme, scheme),
                  const SizedBox(height: 24),

                  // Action Buttons
                  _buildActionButtons(theme, scheme),
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
                        _buildPostsTab(theme, scheme),
                        _buildOutfitsTab(theme, scheme),
                        _buildLikedTab(theme, scheme),
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

  Widget _buildProfileHeader(ThemeData theme, ColorScheme scheme) {
    return Row(
      children: [
        // Avatar
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: scheme.primary, width: 3),
          ),
          child: CircleAvatar(
            radius: 47,
            backgroundImage: NetworkImage(_userProfile['avatar']),
          ),
        ),
        const SizedBox(width: 20),

        // Profile Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _userProfile['username'],
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  if (_userProfile['verified'])
                    Icon(
                      LucideIcons.checkCircle,
                      size: 20,
                      color: scheme.primary,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _userProfile['fullName'],
                style: theme.textTheme.titleMedium?.copyWith(
                  color: scheme.onSurface.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _userProfile['bio'],
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    LucideIcons.mapPin,
                    size: 16,
                    color: scheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _userProfile['location'],
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.3);
  }

  Widget _buildStatsRow(ThemeData theme, ColorScheme scheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(
          'Posts',
          _userProfile['posts'].toString(),
          theme,
          scheme,
        ),
        _buildStatItem(
          'Followers',
          _userProfile['followers'].toString(),
          theme,
          scheme,
        ),
        _buildStatItem(
          'Following',
          _userProfile['following'].toString(),
          theme,
          scheme,
        ),
      ],
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3);
  }

  Widget _buildStatItem(
    String label,
    String value,
    ThemeData theme,
    ColorScheme scheme,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme, ColorScheme scheme) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _isFollowing = !_isFollowing;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _isFollowing ? scheme.surfaceVariant : scheme.primary,
              foregroundColor:
                  _isFollowing ? scheme.onSurfaceVariant : scheme.onPrimary,
            ),
            child: Text(
              _isFollowing ? 'Following' : 'Follow',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: scheme.outline),
            ),
            child: Text(
              'Message',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3);
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
          Tab(text: 'Posts'),
          Tab(text: 'Outfits'),
          Tab(text: 'Liked'),
        ],
      ),
    ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.3);
  }

  Widget _buildPostsTab(ThemeData theme, ColorScheme scheme) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _userPosts.length,
      itemBuilder: (context, index) {
        final post = _userPosts[index];
        return _buildPostGridItem(post, theme, scheme);
      },
    );
  }

  Widget _buildOutfitsTab(ThemeData theme, ColorScheme scheme) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: _userOutfits.length,
      itemBuilder: (context, index) {
        final outfit = _userOutfits[index];
        return _buildOutfitCard(outfit, theme, scheme);
      },
    );
  }

  Widget _buildLikedTab(ThemeData theme, ColorScheme scheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.heart,
            size: 64,
            color: scheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No liked posts yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: scheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Posts you like will appear here',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostGridItem(
    Map<String, dynamic> post,
    ThemeData theme,
    ColorScheme scheme,
  ) {
    return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: scheme.outline.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Image.network(
                  post['image'],
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Row(
                    children: [
                      Icon(LucideIcons.heart, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        post['likes'].toString(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: (200 * int.parse(post['id'])).ms)
        .scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildOutfitCard(
    Map<String, dynamic> outfit,
    ThemeData theme,
    ColorScheme scheme,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Image.network(
                    outfit['image'],
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      outfit['name'],
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.heart,
                          size: 14,
                          color: scheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          outfit['likes'].toString(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          LucideIcons.shirt,
                          size: 14,
                          color: scheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${outfit['items']} items',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: (300 * int.parse(outfit['id'])).ms)
        .slideY(begin: 0.3);
  }
}
