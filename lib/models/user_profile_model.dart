class UserProfile {
  final String id;
  final String username;
  final String displayName;
  final String avatar;
  final String bio;
  final String location;
  final String website;
  final bool verified;
  final bool isPrivate;
  final DateTime joinedAt;
  final int followers;
  final int following;
  final int posts;
  final int points;
  final String style;
  final List<String> interests;
  final Map<String, dynamic> stats;
  final bool isFollowing;
  final bool isBlocked;

  UserProfile({
    required this.id,
    required this.username,
    required this.displayName,
    required this.avatar,
    this.bio = '',
    this.location = '',
    this.website = '',
    this.verified = false,
    this.isPrivate = false,
    required this.joinedAt,
    this.followers = 0,
    this.following = 0,
    this.posts = 0,
    this.points = 0,
    this.style = '',
    this.interests = const [],
    this.stats = const {},
    this.isFollowing = false,
    this.isBlocked = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      displayName: json['displayName'] ?? '',
      avatar: json['avatar'] ?? '',
      bio: json['bio'] ?? '',
      location: json['location'] ?? '',
      website: json['website'] ?? '',
      verified: json['verified'] ?? false,
      isPrivate: json['isPrivate'] ?? false,
      joinedAt: DateTime.parse(
        json['joinedAt'] ?? DateTime.now().toIso8601String(),
      ),
      followers: json['followers'] ?? 0,
      following: json['following'] ?? 0,
      posts: json['posts'] ?? 0,
      points: json['points'] ?? 0,
      style: json['style'] ?? '',
      interests: List<String>.from(json['interests'] ?? []),
      stats: Map<String, dynamic>.from(json['stats'] ?? {}),
      isFollowing: json['isFollowing'] ?? false,
      isBlocked: json['isBlocked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'displayName': displayName,
      'avatar': avatar,
      'bio': bio,
      'location': location,
      'website': website,
      'verified': verified,
      'isPrivate': isPrivate,
      'joinedAt': joinedAt.toIso8601String(),
      'followers': followers,
      'following': following,
      'posts': posts,
      'points': points,
      'style': style,
      'interests': interests,
      'stats': stats,
      'isFollowing': isFollowing,
      'isBlocked': isBlocked,
    };
  }

  UserProfile copyWith({
    String? id,
    String? username,
    String? displayName,
    String? avatar,
    String? bio,
    String? location,
    String? website,
    bool? verified,
    bool? isPrivate,
    DateTime? joinedAt,
    int? followers,
    int? following,
    int? posts,
    int? points,
    String? style,
    List<String>? interests,
    Map<String, dynamic>? stats,
    bool? isFollowing,
    bool? isBlocked,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatar: avatar ?? this.avatar,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      website: website ?? this.website,
      verified: verified ?? this.verified,
      isPrivate: isPrivate ?? this.isPrivate,
      joinedAt: joinedAt ?? this.joinedAt,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      posts: posts ?? this.posts,
      points: points ?? this.points,
      style: style ?? this.style,
      interests: interests ?? this.interests,
      stats: stats ?? this.stats,
      isFollowing: isFollowing ?? this.isFollowing,
      isBlocked: isBlocked ?? this.isBlocked,
    );
  }

  String get formattedFollowers {
    if (followers >= 1000000) {
      return '${(followers / 1000000).toStringAsFixed(1)}M';
    } else if (followers >= 1000) {
      return '${(followers / 1000).toStringAsFixed(1)}K';
    }
    return followers.toString();
  }

  String get formattedFollowing {
    if (following >= 1000000) {
      return '${(following / 1000000).toStringAsFixed(1)}M';
    } else if (following >= 1000) {
      return '${(following / 1000).toStringAsFixed(1)}K';
    }
    return following.toString();
  }

  String get joinedDate {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[joinedAt.month - 1]} ${joinedAt.year}';
  }
}
