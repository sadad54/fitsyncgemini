import '../models/user_profile_model.dart';

class UserProfileService {
  // Get user profile by username
  Future<UserProfile> getUserProfile(String username) async {
    // TODO: Replace with actual API call
    await Future.delayed(const Duration(milliseconds: 800));

    // Mock data
    return UserProfile(
      id: 'user_123',
      username: username,
      displayName: 'Sarah Johnson',
      avatar: 'https://api.dicebear.com/7.x/avataaars/png?seed=$username',
      bio: 'Fashion enthusiast | Style blogger | Minimalist at heart ✨',
      location: 'New York, NY',
      website: 'https://sarahjohnson.com',
      verified: true,
      isPrivate: false,
      joinedAt: DateTime.now().subtract(const Duration(days: 365)),
      followers: 12450,
      following: 892,
      posts: 156,
      points: 2847,
      style: 'minimalist',
      interests: ['minimalism', 'sustainable fashion', 'streetwear', 'vintage'],
      stats: {
        'challenges_won': 23,
        'posts_liked': 1247,
        'comments_made': 892,
        'days_active': 365,
      },
      isFollowing: false,
      isBlocked: false,
    );
  }

  // Get current user's profile
  Future<UserProfile> getCurrentUserProfile() async {
    // TODO: Replace with actual API call
    await Future.delayed(const Duration(milliseconds: 600));

    return UserProfile(
      id: 'current_user',
      username: 'current_user',
      displayName: 'Current User',
      avatar: 'https://api.dicebear.com/7.x/avataaars/png?seed=current_user',
      bio: 'Exploring my personal style journey',
      location: 'San Francisco, CA',
      website: '',
      verified: false,
      isPrivate: false,
      joinedAt: DateTime.now().subtract(const Duration(days: 180)),
      followers: 234,
      following: 567,
      posts: 45,
      points: 892,
      style: 'eclectic',
      interests: ['streetwear', 'vintage', 'sustainable fashion'],
      stats: {
        'challenges_won': 5,
        'posts_liked': 234,
        'comments_made': 156,
        'days_active': 180,
      },
      isFollowing: false,
      isBlocked: false,
    );
  }

  // Follow a user
  Future<void> followUser(String username) async {
    // TODO: Replace with actual API call
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // Unfollow a user
  Future<void> unfollowUser(String username) async {
    // TODO: Replace with actual API call
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // Block a user
  Future<void> blockUser(String username) async {
    // TODO: Replace with actual API call
    await Future.delayed(const Duration(milliseconds: 400));
  }

  // Unblock a user
  Future<void> unblockUser(String username) async {
    // TODO: Replace with actual API call
    await Future.delayed(const Duration(milliseconds: 400));
  }

  // Update user profile
  Future<UserProfile> updateProfile({
    String? displayName,
    String? bio,
    String? location,
    String? website,
    String? style,
    List<String>? interests,
  }) async {
    // TODO: Replace with actual API call
    await Future.delayed(const Duration(milliseconds: 1000));

    final currentProfile = await getCurrentUserProfile();
    return currentProfile.copyWith(
      displayName: displayName,
      bio: bio,
      location: location,
      website: website,
      style: style,
      interests: interests,
    );
  }

  // Get user's posts
  Future<List<Map<String, dynamic>>> getUserPosts(
    String username, {
    int page = 1,
    int limit = 20,
  }) async {
    // TODO: Replace with actual API call
    await Future.delayed(const Duration(milliseconds: 600));

    return [
      {
        'id': 1,
        'image':
            'https://via.placeholder.com/400x500/00E5FF/FFFFFF?text=Post+1',
        'caption': 'My latest minimalist look',
        'likes': 234,
        'comments': 12,
        'createdAt': DateTime.now().subtract(const Duration(days: 2)),
      },
      {
        'id': 2,
        'image':
            'https://via.placeholder.com/400x500/8A63FF/FFFFFF?text=Post+2',
        'caption': 'Streetwear vibes today',
        'likes': 156,
        'comments': 8,
        'createdAt': DateTime.now().subtract(const Duration(days: 5)),
      },
    ];
  }

  // Get user's followers
  Future<List<UserProfile>> getFollowers(
    String username, {
    int page = 1,
    int limit = 20,
  }) async {
    // TODO: Replace with actual API call
    await Future.delayed(const Duration(milliseconds: 700));

    return [
      UserProfile(
        id: 'follower_1',
        username: 'fashion_mike',
        displayName: 'Mike Chen',
        avatar: 'https://api.dicebear.com/7.x/avataaars/png?seed=fashion_mike',
        bio: 'Streetwear enthusiast',
        joinedAt: DateTime.now().subtract(const Duration(days: 200)),
        followers: 1234,
        following: 567,
        posts: 89,
        points: 1567,
        style: 'streetwear',
        interests: ['streetwear', 'sneakers', 'urban fashion'],
        isFollowing: true,
      ),
      UserProfile(
        id: 'follower_2',
        username: 'boho_emma',
        displayName: 'Emma Wilson',
        avatar: 'https://api.dicebear.com/7.x/avataaars/png?seed=boho_emma',
        bio: 'Boho spirit ✨',
        joinedAt: DateTime.now().subtract(const Duration(days: 150)),
        followers: 2345,
        following: 789,
        posts: 123,
        points: 2156,
        style: 'boho',
        interests: ['boho', 'vintage', 'sustainable fashion'],
        isFollowing: false,
      ),
    ];
  }

  // Get user's following
  Future<List<UserProfile>> getFollowing(
    String username, {
    int page = 1,
    int limit = 20,
  }) async {
    // TODO: Replace with actual API call
    await Future.delayed(const Duration(milliseconds: 700));

    return [
      UserProfile(
        id: 'following_1',
        username: 'style_guru',
        displayName: 'Alex Rodriguez',
        avatar: 'https://api.dicebear.com/7.x/avataaars/png?seed=style_guru',
        bio: 'Fashion consultant & style expert',
        joinedAt: DateTime.now().subtract(const Duration(days: 500)),
        followers: 5678,
        following: 234,
        posts: 234,
        points: 4567,
        style: 'classic',
        interests: ['classic', 'luxury', 'tailoring'],
        isFollowing: true,
      ),
    ];
  }

  // Search users
  Future<List<UserProfile>> searchUsers(
    String query, {
    int page = 1,
    int limit = 20,
  }) async {
    // TODO: Replace with actual API call
    await Future.delayed(const Duration(milliseconds: 800));

    return [
      UserProfile(
        id: 'search_1',
        username: 'style_sarah',
        displayName: 'Sarah Johnson',
        avatar: 'https://api.dicebear.com/7.x/avataaars/png?seed=style_sarah',
        bio: 'Fashion enthusiast | Style blogger',
        joinedAt: DateTime.now().subtract(const Duration(days: 365)),
        followers: 12450,
        following: 892,
        posts: 156,
        points: 2847,
        style: 'minimalist',
        interests: ['minimalism', 'sustainable fashion'],
        isFollowing: false,
      ),
    ];
  }

  // Get user statistics
  Future<Map<String, dynamic>> getUserStats(String username) async {
    // TODO: Replace with actual API call
    await Future.delayed(const Duration(milliseconds: 400));

    return {
      'totalPosts': 156,
      'totalLikes': 12450,
      'totalComments': 892,
      'challengesWon': 23,
      'daysActive': 365,
      'averageLikesPerPost': 79.8,
      'engagementRate': 6.4,
      'topPosts': [
        {'id': 1, 'likes': 234, 'comments': 12},
        {'id': 2, 'likes': 189, 'comments': 8},
        {'id': 3, 'likes': 156, 'comments': 15},
      ],
    };
  }
}
