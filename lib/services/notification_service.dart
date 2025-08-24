import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<void> initialize() async {
    try {
      // Initialize Supabase notifications
      print('NotificationService initialized with Supabase');
    } catch (e) {
      print('Error initializing NotificationService: $e');
    }
  }

  // Show local notification
  static void _showLocalNotification(String title, String body) {
    // You can integrate with flutter_local_notifications here
    print('Local notification: $title - $body');
  }

  // Create notification in Supabase
  static Future<void> _createNotification({
    required String userId,
    required String type,
    required String title,
    String? body,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'type': type,
        'title': title,
        'body': body,
        'data': data,
        'read': false,
      });
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  // Community-specific notification methods
  static Future<void> showLikeNotification({
    required String username,
    required String postId,
  }) async {
    try {
      // Get post owner ID
      final postResponse =
          await _supabase
              .from('community_posts')
              .select('user_id')
              .eq('id', postId)
              .single();

      if (postResponse != null) {
        final postOwnerId = postResponse['user_id'] as String;

        // Check if user wants like notifications
        final settings = await getNotificationSettings(postOwnerId);
        if (settings['likes_enabled'] == true) {
          await _createNotification(
            userId: postOwnerId,
            type: 'like',
            title: 'New Like',
            body: '$username liked your post',
            data: {'post_id': postId, 'username': username},
          );
        }
      }
    } catch (e) {
      print('Error showing like notification: $e');
    }
  }

  static Future<void> showCommentNotification({
    required String username,
    required String postId,
    required String comment,
  }) async {
    try {
      // Get post owner ID
      final postResponse =
          await _supabase
              .from('community_posts')
              .select('user_id')
              .eq('id', postId)
              .single();

      if (postResponse != null) {
        final postOwnerId = postResponse['user_id'] as String;

        // Check if user wants comment notifications
        final settings = await getNotificationSettings(postOwnerId);
        if (settings['comments_enabled'] == true) {
          await _createNotification(
            userId: postOwnerId,
            type: 'comment',
            title: 'New Comment',
            body:
                '$username commented: ${comment.length > 50 ? comment.substring(0, 50) + '...' : comment}',
            data: {'post_id': postId, 'username': username, 'comment': comment},
          );
        }
      }
    } catch (e) {
      print('Error showing comment notification: $e');
    }
  }

  static Future<void> showChallengeNotification({
    required String challengeName,
    required int daysLeft,
  }) async {
    try {
      // Get all users participating in the challenge
      final participantsResponse = await _supabase
          .from('challenge_participants')
          .select('user_id')
          .eq('challenge_id', challengeName);

      if (participantsResponse != null) {
        for (final participant in participantsResponse) {
          final userId = participant['user_id'] as String;

          // Check if user wants challenge notifications
          final settings = await getNotificationSettings(userId);
          if (settings['challenges_enabled'] == true) {
            await _createNotification(
              userId: userId,
              type: 'challenge',
              title: 'Challenge Reminder',
              body: '$challengeName ends in $daysLeft days',
              data: {'challenge_name': challengeName, 'days_left': daysLeft},
            );
          }
        }
      }
    } catch (e) {
      print('Error showing challenge notification: $e');
    }
  }

  static Future<void> showMentionNotification({
    required String username,
    required String postId,
  }) async {
    try {
      // Get mentioned user ID (you'll need to implement mention detection)
      // For now, we'll assume the mentioned user is the current user
      final currentUser = _supabase.auth.currentUser;
      if (currentUser != null) {
        final mentionedUserId = currentUser.id;

        // Check if user wants mention notifications
        final settings = await getNotificationSettings(mentionedUserId);
        if (settings['mentions_enabled'] == true) {
          await _createNotification(
            userId: mentionedUserId,
            type: 'mention',
            title: 'You were mentioned',
            body: '$username mentioned you in a post',
            data: {'post_id': postId, 'username': username},
          );
        }
      }
    } catch (e) {
      print('Error showing mention notification: $e');
    }
  }

  static Future<void> showFollowNotification({required String username}) async {
    try {
      // Get the user being followed
      final currentUser = _supabase.auth.currentUser;
      if (currentUser != null) {
        final followedUserId = currentUser.id;

        // Check if user wants follow notifications
        final settings = await getNotificationSettings(followedUserId);
        if (settings['follows_enabled'] == true) {
          await _createNotification(
            userId: followedUserId,
            type: 'follow',
            title: 'New Follower',
            body: '$username started following you',
            data: {'username': username},
          );
        }
      }
    } catch (e) {
      print('Error showing follow notification: $e');
    }
  }

  // Subscribe to real-time notifications
  static Future<void> subscribeToNotifications(String userId) async {
    try {
      // TODO: Implement real-time notifications when Supabase Flutter supports it
      print('Subscribed to notifications for user: $userId');
    } catch (e) {
      print('Error subscribing to notifications: $e');
    }
  }

  // Unsubscribe from notifications
  static Future<void> unsubscribeFromNotifications(String userId) async {
    try {
      // TODO: Implement real-time unsubscription when Supabase Flutter supports it
      print('Unsubscribed from notifications for user: $userId');
    } catch (e) {
      print('Error unsubscribing from notifications: $e');
    }
  }

  // Get notification settings from Supabase
  static Future<Map<String, dynamic>> getNotificationSettings(
    String userId,
  ) async {
    try {
      final response =
          await _supabase
              .from('user_notification_settings')
              .select()
              .eq('user_id', userId)
              .single();

      return response ??
          {
            'likes_enabled': true,
            'comments_enabled': true,
            'challenges_enabled': true,
            'mentions_enabled': true,
            'follows_enabled': true,
          };
    } catch (e) {
      print('Error fetching notification settings: $e');
      return {
        'likes_enabled': true,
        'comments_enabled': true,
        'challenges_enabled': true,
        'mentions_enabled': true,
        'follows_enabled': true,
      };
    }
  }

  // Update notification settings in Supabase
  static Future<void> updateNotificationSettings(
    String userId,
    Map<String, bool> settings,
  ) async {
    try {
      await _supabase.from('user_notification_settings').upsert({
        'user_id': userId,
        ...settings,
        'updated_at': DateTime.now().toIso8601String(),
      });

      print('Notification settings updated for user: $userId');
    } catch (e) {
      print('Error updating notification settings: $e');
    }
  }

  // Mark notification as read
  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({
            'read': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId);

      print('Notification marked as read: $notificationId');
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  static Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      await _supabase
          .from('notifications')
          .update({
            'read': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('read', false);

      print('All notifications marked as read for user: $userId');
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  // Get unread notifications count
  static Future<int> getUnreadNotificationsCount(String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('read', false);

      return response.length;
    } catch (e) {
      print('Error getting unread notifications count: $e');
      return 0;
    }
  }

  // Get notifications list
  static Future<List<Map<String, dynamic>>> getNotifications(
    String userId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range((page - 1) * limit, page * limit - 1);

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      print('Error getting notifications: $e');
      return [];
    }
  }

  // Delete notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await _supabase.from('notifications').delete().eq('id', notificationId);

      print('Notification deleted: $notificationId');
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  // Delete all notifications for user
  static Future<void> deleteAllNotifications(String userId) async {
    try {
      await _supabase.from('notifications').delete().eq('user_id', userId);

      print('All notifications deleted for user: $userId');
    } catch (e) {
      print('Error deleting all notifications: $e');
    }
  }

  // Get notification by type
  static Future<List<Map<String, dynamic>>> getNotificationsByType(
    String userId,
    String type, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .eq('type', type)
          .order('created_at', ascending: false)
          .range((page - 1) * limit, page * limit - 1);

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      print('Error getting notifications by type: $e');
      return [];
    }
  }

  // Dispose resources
  static Future<void> dispose() async {
    try {
      print('NotificationService disposed');
    } catch (e) {
      print('Error disposing NotificationService: $e');
    }
  }
}
