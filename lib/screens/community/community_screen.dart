import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/community_model.dart';
import '../../viewmodels/community_viewmodel.dart';
import '../../widgets/community/community_post_card.dart';
import '../../widgets/community/challenge_card.dart';
import '../../widgets/community/leaderboard_item.dart';
import '../../widgets/community/comments_section.dart';
import '../../widgets/community/image_upload_widget.dart';
import '../../providers/providers.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Load community data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(communityViewModelProvider).loadCommunityData();
    });
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
    final communityViewModel = ref.watch(communityViewModelProvider);
    final communityData = communityViewModel.communityData;

    if (communityViewModel.isLoading) {
      return Scaffold(
        backgroundColor: scheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (communityData == null) {
      return Scaffold(
        backgroundColor: scheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.users,
                size: 64,
                color: scheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load community data',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => communityViewModel.loadCommunityData(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: scheme.surface,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePostModal(context),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        child: const Icon(LucideIcons.plus),
      ),
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
                    LucideIcons.users,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Community',
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
                icon: Icon(LucideIcons.plus, color: scheme.onSurface),
                onPressed: () => _showCreatePostModal(context),
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
                  // Community Stats
                  _buildCommunityStats(theme, scheme, communityData),
                  const SizedBox(height: 32),

                  // Style Challenges
                  _buildStyleChallenges(theme, scheme, communityData),
                  const SizedBox(height: 32),

                  // Top Contributors
                  _buildTopContributors(theme, scheme, communityData),
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
                        _buildFeedTab(theme, scheme, communityData),
                        _buildChallengesTab(theme, scheme, communityData),
                        _buildLeaderboardTab(theme, scheme, communityData),
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

  Widget _buildCommunityStats(
    ThemeData theme,
    ColorScheme scheme,
    CommunityModel data,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary.withValues(alpha: 0.1),
            scheme.tertiary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  '${(data.totalMembers / 1000).toStringAsFixed(1)}K',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
                Text(
                  'Members',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: scheme.outline.withValues(alpha: 0.3),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '${data.postsToday}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.secondary,
                  ),
                ),
                Text(
                  'Posts Today',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: scheme.outline.withValues(alpha: 0.3),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '${data.activeChallenges}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.tertiary,
                  ),
                ),
                Text(
                  'Active Challenges',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.3);
  }

  Widget _buildStyleChallenges(
    ThemeData theme,
    ColorScheme scheme,
    CommunityModel data,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Style Challenges',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'View All',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: data.challenges.length,
            itemBuilder: (context, index) {
              final challenge = data.challenges[index];
              return ChallengeCard(
                challenge: challenge,
                isHorizontal: true,
                onJoin: () => _joinChallenge(challenge.id),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTopContributors(
    ThemeData theme,
    ColorScheme scheme,
    CommunityModel data,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Contributors',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        ...data.topContributors.map(
          (contributor) =>
              LeaderboardItem(contributor: contributor, onTap: () {}),
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
          Tab(text: 'Feed'),
          Tab(text: 'Challenges'),
          Tab(text: 'Leaderboard'),
        ],
      ),
    );
  }

  Widget _buildFeedTab(
    ThemeData theme,
    ColorScheme scheme,
    CommunityModel data,
  ) {
    return ListView.builder(
      itemCount: data.posts.length,
      itemBuilder: (context, index) {
        final post = data.posts[index];
        return CommunityPostCard(
          post: post,
          onLike: () => _toggleLike(post.id),
          onComment: () => _showCommentsModal(context, post.id, post.comments),
          onShare: () {},
          onBookmark: () {},
          onUserTap: () {},
        );
      },
    );
  }

  Widget _buildChallengesTab(
    ThemeData theme,
    ColorScheme scheme,
    CommunityModel data,
  ) {
    return ListView.builder(
      itemCount: data.challenges.length,
      itemBuilder: (context, index) {
        final challenge = data.challenges[index];
        return ChallengeCard(
          challenge: challenge,
          onJoin: () => _joinChallenge(challenge.id),
        );
      },
    );
  }

  Widget _buildLeaderboardTab(
    ThemeData theme,
    ColorScheme scheme,
    CommunityModel data,
  ) {
    return ListView.builder(
      itemCount: data.topContributors.length,
      itemBuilder: (context, index) {
        final contributor = data.topContributors[index];
        return LeaderboardItem(contributor: contributor, onTap: () {});
      },
    );
  }

  void _toggleLike(int postId) {
    ref.read(communityViewModelProvider).togglePostLike(postId);
  }

  void _joinChallenge(int challengeId) {
    ref.read(communityViewModelProvider).joinChallenge(challengeId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Joined challenge!'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _showCreatePostModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder:
                (context, scrollController) => ImageUploadWidget(
                  onImageSelected: (imageUrl) {
                    _showPostDetailsModal(context, imageUrl);
                  },
                  onCancel: () => Navigator.of(context).pop(),
                ),
          ),
    );
  }

  void _showCommentsModal(BuildContext context, int postId, int commentCount) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.8,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder:
                (context, scrollController) => CommentsSection(
                  postId: postId,
                  commentCount: commentCount,
                  onCommentAdded: () {
                    // Refresh the post data
                    ref.read(communityViewModelProvider).loadCommunityData();
                  },
                ),
          ),
    );
  }

  void _showPostDetailsModal(BuildContext context, String imageUrl) {
    final captionController = TextEditingController();
    String? selectedChallenge;
    final communityData = ref.read(communityViewModelProvider).communityData;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Create Post',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            final caption = captionController.text.trim();
                            if (caption.isNotEmpty) {
                              ref
                                  .read(communityViewModelProvider)
                                  .createPost(
                                    imageUrl,
                                    caption,
                                    selectedChallenge,
                                  );
                              Navigator.of(context).pop();
                            }
                          },
                          child: const Text('Share'),
                        ),
                      ],
                    ),
                  ),

                  // Image Preview
                  Container(
                    height: 300,
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(imageUrl, fit: BoxFit.cover),
                    ),
                  ),

                  // Caption Input
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: captionController,
                      decoration: const InputDecoration(
                        hintText: 'Write a caption...',
                        border: InputBorder.none,
                      ),
                      maxLines: 3,
                    ),
                  ),

                  // Challenge Selection
                  if (communityData?.challenges.isNotEmpty == true) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Join a Challenge (Optional)',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: communityData!.challenges.length,
                              itemBuilder: (context, index) {
                                final challenge =
                                    communityData.challenges[index];
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedChallenge = challenge.title;
                                    });
                                  },
                                  child: Container(
                                    width: 200,
                                    margin: const EdgeInsets.only(right: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color:
                                            selectedChallenge == challenge.title
                                                ? Theme.of(
                                                  context,
                                                ).colorScheme.primary
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .outline
                                                    .withValues(alpha: 0.3),
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          challenge.title,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.labelMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          challenge.description,
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
    );
  }
}
