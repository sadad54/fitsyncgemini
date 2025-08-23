import '../models/comment_model.dart';

class CommentsService {
  // Get comments for a specific post
  Future<List<Comment>> getComments(
    int postId, {
    int page = 1,
    int limit = 20,
  }) async {
    // TODO: Replace with actual API call
    await Future.delayed(const Duration(milliseconds: 600));

    // Mock data
    return [
      Comment(
        id: 1,
        postId: postId,
        username: 'style_sarah',
        avatar: 'https://api.dicebear.com/7.x/avataaars/png?seed=style_sarah',
        content: 'Love this outfit! The color combination is perfect 👌',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        likes: 12,
        liked: false,
        verified: true,
        replyCount: 3,
      ),
      Comment(
        id: 2,
        postId: postId,
        username: 'fashion_mike',
        avatar: 'https://api.dicebear.com/7.x/avataaars/png?seed=fashion_mike',
        content: 'Where did you get those shoes? They look amazing!',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        likes: 8,
        liked: true,
        verified: false,
        replyCount: 1,
      ),
      Comment(
        id: 3,
        postId: postId,
        username: 'boho_emma',
        avatar: 'https://api.dicebear.com/7.x/avataaars/png?seed=boho_emma',
        content: 'This is giving me major inspiration for my next look!',
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        likes: 15,
        liked: false,
        verified: true,
        replyCount: 0,
      ),
    ];
  }

  // Get replies for a specific comment
  Future<List<Comment>> getReplies(
    int commentId, {
    int page = 1,
    int limit = 10,
  }) async {
    // TODO: Replace with actual API call
    await Future.delayed(const Duration(milliseconds: 400));

    // Mock data
    return [
      Comment(
        id: 4,
        postId: 1,
        username: 'style_sarah',
        avatar: 'https://api.dicebear.com/7.x/avataaars/png?seed=style_sarah',
        content: 'Thanks! I got them from Zara last week',
        createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
        likes: 5,
        liked: false,
        verified: true,
        replyCount: 0,
      ),
      Comment(
        id: 5,
        postId: 1,
        username: 'fashion_mike',
        avatar: 'https://api.dicebear.com/7.x/avataaars/png?seed=fashion_mike',
        content: 'Perfect! I\'ll check them out',
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        likes: 2,
        liked: false,
        verified: false,
        replyCount: 0,
      ),
    ];
  }

  // Add a new comment
  Future<Comment> addComment(int postId, String content) async {
    // TODO: Replace with actual API call
    await Future.delayed(const Duration(milliseconds: 800));

    return Comment(
      id: DateTime.now().millisecondsSinceEpoch,
      postId: postId,
      username: 'current_user',
      avatar: 'https://api.dicebear.com/7.x/avataaars/png?seed=current_user',
      content: content,
      createdAt: DateTime.now(),
      likes: 0,
      liked: false,
      verified: false,
      replyCount: 0,
    );
  }

  // Add a reply to a comment
  Future<Comment> addReply(int commentId, String content) async {
    // TODO: Replace with actual API call
    await Future.delayed(const Duration(milliseconds: 600));

    return Comment(
      id: DateTime.now().millisecondsSinceEpoch,
      postId: 1, // This should be the post ID
      username: 'current_user',
      avatar: 'https://api.dicebear.com/7.x/avataaars/png?seed=current_user',
      content: content,
      createdAt: DateTime.now(),
      likes: 0,
      liked: false,
      verified: false,
      replyCount: 0,
    );
  }

  // Like/unlike a comment
  Future<void> toggleCommentLike(int commentId) async {
    // TODO: Replace with actual API call
    await Future.delayed(const Duration(milliseconds: 300));
  }

  // Delete a comment
  Future<void> deleteComment(int commentId) async {
    // TODO: Replace with actual API call
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // Report a comment
  Future<void> reportComment(int commentId, String reason) async {
    // TODO: Replace with actual API call
    await Future.delayed(const Duration(milliseconds: 400));
  }

  // Edit a comment
  Future<Comment> editComment(int commentId, String newContent) async {
    // TODO: Replace with actual API call
    await Future.delayed(const Duration(milliseconds: 600));

    return Comment(
      id: commentId,
      postId: 1,
      username: 'current_user',
      avatar: 'https://api.dicebear.com/7.x/avataaars/png?seed=current_user',
      content: newContent,
      createdAt: DateTime.now(),
      likes: 0,
      liked: false,
      verified: false,
      replyCount: 0,
    );
  }

  // Get comment statistics
  Future<Map<String, dynamic>> getCommentStats(int postId) async {
    // TODO: Replace with actual API call
    await Future.delayed(const Duration(milliseconds: 300));

    return {
      'totalComments': 156,
      'totalLikes': 892,
      'averageLikesPerComment': 5.7,
      'topCommenters': [
        {'username': 'style_sarah', 'comments': 23},
        {'username': 'fashion_mike', 'comments': 18},
        {'username': 'boho_emma', 'comments': 15},
      ],
    };
  }
}
