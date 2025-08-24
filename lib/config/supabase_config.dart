import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // TODO: Replace with your actual Supabase credentials
  static const String supabaseUrl = 'https://eixnacajmchafxkbtmnr.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVpeG5hY2FqbWNoYWZ4a2J0bW5yIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU4NDk1NTksImV4cCI6MjA3MTQyNTU1OX0.dLRdQXKI-VIhXu26y7Uld6oCmr6Zxx-EBOCxp7U2h2g';

  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      print('Supabase initialized successfully');
    } catch (e) {
      print('Error initializing Supabase: $e');
      rethrow;
    }
  }

  static SupabaseClient get client => Supabase.instance.client;

  // Database table names
  static const String usersTable = 'users';
  static const String communityPostsTable = 'community_posts';
  static const String commentsTable = 'comments';
  static const String styleChallengesTable = 'style_challenges';
  static const String challengeParticipantsTable = 'challenge_participants';
  static const String postLikesTable = 'post_likes';
  static const String commentLikesTable = 'comment_likes';
  static const String userFollowsTable = 'user_follows';
  static const String notificationsTable = 'notifications';
  static const String userNotificationSettingsTable =
      'user_notification_settings';

  // Storage bucket names
  static const String communityImagesBucket = 'community-images';
  static const String userAvatarsBucket = 'user-avatars';

  // Real-time channel names
  static const String communityPostsChannel = 'community_posts';
  static const String userNotificationsChannel = 'user_notifications';
  static const String postCommentsChannel = 'post_comments';

  // RPC function names
  static const String getTopContributorsFunction = 'get_top_contributors';
  static const String getUserStatsFunction = 'get_user_stats';
  static const String getCommunityStatsFunction = 'get_community_stats';
}
