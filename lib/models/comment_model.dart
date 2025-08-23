class Comment {
  final int id;
  final int postId;
  final String username;
  final String avatar;
  final String content;
  final DateTime createdAt;
  final int likes;
  final bool liked;
  final bool verified;
  final List<Comment> replies;
  final int replyCount;

  Comment({
    required this.id,
    required this.postId,
    required this.username,
    required this.avatar,
    required this.content,
    required this.createdAt,
    this.likes = 0,
    this.liked = false,
    this.verified = false,
    this.replies = const [],
    this.replyCount = 0,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? 0,
      postId: json['postId'] ?? 0,
      username: json['username'] ?? '',
      avatar: json['avatar'] ?? '',
      content: json['content'] ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      likes: json['likes'] ?? 0,
      liked: json['liked'] ?? false,
      verified: json['verified'] ?? false,
      replies:
          (json['replies'] as List?)
              ?.map((e) => Comment.fromJson(e))
              .toList() ??
          [],
      replyCount: json['replyCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'username': username,
      'avatar': avatar,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'likes': likes,
      'liked': liked,
      'verified': verified,
      'replies': replies.map((e) => e.toJson()).toList(),
      'replyCount': replyCount,
    };
  }

  Comment copyWith({
    int? id,
    int? postId,
    String? username,
    String? avatar,
    String? content,
    DateTime? createdAt,
    int? likes,
    bool? liked,
    bool? verified,
    List<Comment>? replies,
    int? replyCount,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      username: username ?? this.username,
      avatar: avatar ?? this.avatar,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      liked: liked ?? this.liked,
      verified: verified ?? this.verified,
      replies: replies ?? this.replies,
      replyCount: replyCount ?? this.replyCount,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
