import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/community_model.dart';
import '../models/comment_model.dart';
import '../models/user_profile_model.dart';

class SupabaseService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Community Posts
  static Future<List<CommunityPost>> getCommunityPosts({
    int page = 1,
    int limit = 20,
    String? challengeId,
  }) async {
    try {
      var query = _supabase
          .from('community_posts')
          .select('''
            *,
            user:users(username, display_name, avatar, verified),
            challenge:style_challenges(title)
          ''')
          .order('created_at', ascending: false)
          .range((page - 1) * limit, page * limit - 1);

      if (challengeId != null) {
        query = query.eq('challenge_id', challengeId);
      }

      final response = await query;
      return (response as List)
          .map((post) => CommunityPost.fromJson(post))
          .toList();
    } catch (e) {
      print('Error fetching community posts: $e');
      return [];
    }
  }

  static Future<CommunityPost> createPost({
    required String userId,
    required String imageUrl,
    required String caption,
    String? challengeId,
  }) async {
    try {
      final response =
          await _supabase
              .from('community_posts')
              .insert({
                'user_id': userId,
                'image_url': imageUrl,
                'caption': caption,
                'challenge_id': challengeId,
              })
              .select('''
            *,
            user:users(username, display_name, avatar, verified),
            challenge:style_challenges(title)
          ''')
              .single();

      return CommunityPost.fromJson(response);
    } catch (e) {
      throw Exception('Error creating post: $e');
    }
  }

  static Future<void> togglePostLike(String postId, String userId) async {
    try {
      // Check if user already liked the post
      final existingLike =
          await _supabase
              .from('post_likes')
              .select()
              .eq('post_id', postId)
              .eq('user_id', userId)
              .single();

      if (existingLike != null) {
        // Unlike
        await _supabase
            .from('post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', userId);
      } else {
        // Like
        await _supabase.from('post_likes').insert({
          'post_id': postId,
          'user_id': userId,
        });
      }
    } catch (e) {
      throw Exception('Error toggling post like: $e');
    }
  }

  // Comments
  static Future<List<Comment>> getComments(
    String postId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _supabase
          .from('comments')
          .select('''
            *,
            user:users(username, display_name, avatar, verified)
          ''')
          .eq('post_id', postId)
          .order('created_at', ascending: false)
          .range((page - 1) * limit, page * limit - 1);

      return (response as List)
          .map((comment) => Comment.fromJson(comment))
          .toList();
    } catch (e) {
      print('Error fetching comments: $e');
      return [];
    }
  }

  static Future<Comment> addComment({
    required String postId,
    required String userId,
    required String content,
  }) async {
    try {
      final response =
          await _supabase
              .from('comments')
              .insert({
                'post_id': postId,
                'user_id': userId,
                'content': content,
              })
              .select('''
            *,
            user:users(username, display_name, avatar, verified)
          ''')
              .single();

      return Comment.fromJson(response);
    } catch (e) {
      throw Exception('Error adding comment: $e');
    }
  }

  static Future<void> toggleCommentLike(String commentId, String userId) async {
    try {
      final existingLike =
          await _supabase
              .from('comment_likes')
              .select()
              .eq('comment_id', commentId)
              .eq('user_id', userId)
              .single();

      if (existingLike != null) {
        await _supabase
            .from('comment_likes')
            .delete()
            .eq('comment_id', commentId)
            .eq('user_id', userId);
      } else {
        await _supabase.from('comment_likes').insert({
          'comment_id': commentId,
          'user_id': userId,
        });
      }
    } catch (e) {
      throw Exception('Error toggling comment like: $e');
    }
  }

  // Style Challenges
  static Future<List<StyleChallenge>> getActiveChallenges() async {
    try {
      final response = await _supabase
          .from('style_challenges')
          .select()
          .gte('end_date', DateTime.now().toIso8601String())
          .order('created_at', ascending: false);

      return (response as List)
          .map((challenge) => StyleChallenge.fromJson(challenge))
          .toList();
    } catch (e) {
      print('Error fetching challenges: $e');
      return [];
    }
  }

  static Future<void> joinChallenge(String challengeId, String userId) async {
    try {
      await _supabase.from('challenge_participants').upsert({
        'challenge_id': challengeId,
        'user_id': userId,
        'joined_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Error joining challenge: $e');
    }
  }

  // User Profiles
  static Future<UserProfile> getUserProfile(String username) async {
    try {
      final response =
          await _supabase
              .from('users')
              .select('''
            *,
            followers:user_follows!followed_id(count),
            following:user_follows!follower_id(count),
            posts:community_posts(count)
          ''')
              .eq('username', username)
              .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      throw Exception('Error fetching user profile: $e');
    }
  }

  static Future<void> followUser(String followerId, String followedId) async {
    try {
      await _supabase.from('user_follows').insert({
        'follower_id': followerId,
        'followed_id': followedId,
      });
    } catch (e) {
      throw Exception('Error following user: $e');
    }
  }

  static Future<void> unfollowUser(String followerId, String followedId) async {
    try {
      await _supabase
          .from('user_follows')
          .delete()
          .eq('follower_id', followerId)
          .eq('followed_id', followedId);
    } catch (e) {
      throw Exception('Error unfollowing user: $e');
    }
  }

  // Image Upload
  static Future<String> uploadImage(String filePath, String fileName) async {
    try {
      final file = await _supabase.storage
          .from('community-images')
          .upload(fileName, File(filePath));

      final imageUrl = _supabase.storage
          .from('community-images')
          .getPublicUrl(file);

      return imageUrl;
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  // Real-time subscriptions
  static RealtimeChannel subscribeToPosts() {
    return _supabase
        .channel('community_posts')
        .on(
          RealtimeListenTypes.postgresChanges,
          ChannelFilter(
            event: 'INSERT',
            schema: 'public',
            table: 'community_posts',
          ),
          (payload, [ref]) {
            // Handle new post
            print('New post: ${payload['new']}');
          },
        )
        .on(
          RealtimeListenTypes.postgresChanges,
          ChannelFilter(
            event: 'UPDATE',
            schema: 'public',
            table: 'community_posts',
          ),
          (payload, [ref]) {
            // Handle post update
            print('Post updated: ${payload['new']}');
          },
        );
  }

  static RealtimeChannel subscribeToComments(String postId) {
    return _supabase.channel('post_comments:$postId').on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(
        event: 'INSERT',
        schema: 'public',
        table: 'comments',
        filter: 'post_id=eq.$postId',
      ),
      (payload, [ref]) {
        // Handle new comment
        print('New comment: ${payload['new']}');
      },
    );
  }

  static RealtimeChannel subscribeToNotifications(String userId) {
    return _supabase.channel('user_notifications:$userId').on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(
        event: 'INSERT',
        schema: 'public',
        table: 'notifications',
        filter: 'user_id=eq.$userId',
      ),
      (payload, [ref]) {
        // Handle new notification
        print('New notification: ${payload['new']}');
      },
    );
  }

  // Community Statistics
  static Future<Map<String, dynamic>> getCommunityStats() async {
    try {
      final membersCount = await _supabase
          .from('users')
          .select('id', count: CountOption.exact);

      final postsToday = await _supabase
          .from('community_posts')
          .select('id', count: CountOption.exact)
          .gte(
            'created_at',
            DateTime.now().subtract(Duration(days: 1)).toIso8601String(),
          );

      final activeChallenges = await _supabase
          .from('style_challenges')
          .select('id', count: CountOption.exact)
          .gte('end_date', DateTime.now().toIso8601String());

      return {
        'totalMembers': membersCount.count ?? 0,
        'postsToday': postsToday.count ?? 0,
        'activeChallenges': activeChallenges.count ?? 0,
      };
    } catch (e) {
      print('Error fetching community stats: $e');
      return {'totalMembers': 0, 'postsToday': 0, 'activeChallenges': 0};
    }
  }

  // Top Contributors
  static Future<List<TopContributor>> getTopContributors() async {
    try {
      final response = await _supabase.rpc('get_top_contributors').limit(10);

      return (response as List)
          .map((contributor) => TopContributor.fromJson(contributor))
          .toList();
    } catch (e) {
      print('Error fetching top contributors: $e');
      return [];
    }
  }
}
