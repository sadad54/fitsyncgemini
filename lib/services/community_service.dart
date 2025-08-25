import '../models/community_model.dart';
import 'backend_api.dart';

class CommunityService {
  Future<CommunityModel> getCommunityData() async {
    final postsJson = await BackendApi.getCommunityPosts();
    final posts =
        postsJson
            .map(
              (p) => CommunityPost(
                id: p['id'] is int ? p['id'] : 0,
                username: p['username']?.toString() ?? 'user',
                avatar: p['avatar']?.toString() ?? '',
                image: p['image_url']?.toString() ?? '',
                caption: p['content']?.toString() ?? '',
                likes: (p['likes'] ?? 0) as int,
                comments: (p['comments'] ?? 0) as int,
                timeAgo: p['created_at']?.toString() ?? '',
                verified: false,
                challenge: p['challenge']?.toString() ?? '',
                liked: p['liked'] == true,
              ),
            )
            .toList()
            .cast<CommunityPost>();

    return CommunityModel(
      totalMembers: 0,
      postsToday: 0,
      activeChallenges: 0,
      challenges: const [],
      posts: posts,
      topContributors: const [],
    );
  }

  Future<void> togglePostLike(int postId) async {
    try {
      await BackendApi.likePost(postId.toString());
    } catch (e) {
      throw Exception('Failed to toggle post like: $e');
    }
  }

  Future<void> joinChallenge(int challengeId) async {
    try {
      // TODO: Replace with actual Supabase call
      // Example: await SupabaseService.joinChallenge(challengeId.toString(), currentUserId);
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      throw Exception('Failed to join challenge: $e');
    }
  }

  Future<void> createPost({
    required String caption,
    required String imageUrl,
    String? challengeId,
  }) async {
    try {
      await BackendApi.createCommunityPost(content: caption);
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

  Future<List<CommunityPost>> getFeedPosts({
    int page = 1,
    int limit = 10,
  }) async {
    // TODO: Implement API call to get feed posts
    await Future.delayed(const Duration(milliseconds: 600));
    return [];
  }

  Future<List<StyleChallenge>> getActiveChallenges() async {
    // TODO: Implement API call to get active challenges
    await Future.delayed(const Duration(milliseconds: 400));
    return [];
  }

  Future<List<TopContributor>> getLeaderboard({int limit = 50}) async {
    // TODO: Implement API call to get leaderboard
    await Future.delayed(const Duration(milliseconds: 500));
    return [];
  }

  Future<void> followUser(String username) async {
    // TODO: Implement API call to follow user
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> unfollowUser(String username) async {
    // TODO: Implement API call to unfollow user
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> reportPost(int postId, String reason) async {
    // TODO: Implement API call to report post
    await Future.delayed(const Duration(milliseconds: 400));
  }

  Future<void> sharePost(int postId, String platform) async {
    // TODO: Implement API call to share post
    await Future.delayed(const Duration(milliseconds: 200));
  }
}
