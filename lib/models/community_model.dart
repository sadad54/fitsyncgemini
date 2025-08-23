class CommunityModel {
  final int totalMembers;
  final int postsToday;
  final int activeChallenges;
  final List<StyleChallenge> challenges;
  final List<CommunityPost> posts;
  final List<TopContributor> topContributors;

  CommunityModel({
    required this.totalMembers,
    required this.postsToday,
    required this.activeChallenges,
    required this.challenges,
    required this.posts,
    required this.topContributors,
  });

  factory CommunityModel.fromJson(Map<String, dynamic> json) {
    return CommunityModel(
      totalMembers: json['totalMembers'] ?? 0,
      postsToday: json['postsToday'] ?? 0,
      activeChallenges: json['activeChallenges'] ?? 0,
      challenges: (json['challenges'] as List?)
              ?.map((e) => StyleChallenge.fromJson(e))
              .toList() ??
          [],
      posts: (json['posts'] as List?)
              ?.map((e) => CommunityPost.fromJson(e))
              .toList() ??
          [],
      topContributors: (json['topContributors'] as List?)
              ?.map((e) => TopContributor.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalMembers': totalMembers,
      'postsToday': postsToday,
      'activeChallenges': activeChallenges,
      'challenges': challenges.map((e) => e.toJson()).toList(),
      'posts': posts.map((e) => e.toJson()).toList(),
      'topContributors': topContributors.map((e) => e.toJson()).toList(),
    };
  }
}

class StyleChallenge {
  final int id;
  final String title;
  final String description;
  final int participants;
  final int daysLeft;
  final String image;
  final String color;
  final bool active;

  StyleChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.participants,
    required this.daysLeft,
    required this.image,
    required this.color,
    required this.active,
  });

  factory StyleChallenge.fromJson(Map<String, dynamic> json) {
    return StyleChallenge(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      participants: json['participants'] ?? 0,
      daysLeft: json['daysLeft'] ?? 0,
      image: json['image'] ?? '',
      color: json['color'] ?? '',
      active: json['active'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'participants': participants,
      'daysLeft': daysLeft,
      'image': image,
      'color': color,
      'active': active,
    };
  }
}

class CommunityPost {
  final int id;
  final String username;
  final String avatar;
  final String image;
  final String caption;
  final int likes;
  final int comments;
  final String timeAgo;
  final bool verified;
  final String challenge;
  final bool liked;

  CommunityPost({
    required this.id,
    required this.username,
    required this.avatar,
    required this.image,
    required this.caption,
    required this.likes,
    required this.comments,
    required this.timeAgo,
    required this.verified,
    required this.challenge,
    required this.liked,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      avatar: json['avatar'] ?? '',
      image: json['image'] ?? '',
      caption: json['caption'] ?? '',
      likes: json['likes'] ?? 0,
      comments: json['comments'] ?? 0,
      timeAgo: json['timeAgo'] ?? '',
      verified: json['verified'] ?? false,
      challenge: json['challenge'] ?? '',
      liked: json['liked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'avatar': avatar,
      'image': image,
      'caption': caption,
      'likes': likes,
      'comments': comments,
      'timeAgo': timeAgo,
      'verified': verified,
      'challenge': challenge,
      'liked': liked,
    };
  }

  CommunityPost copyWith({
    int? id,
    String? username,
    String? avatar,
    String? image,
    String? caption,
    int? likes,
    int? comments,
    String? timeAgo,
    bool? verified,
    String? challenge,
    bool? liked,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      username: username ?? this.username,
      avatar: avatar ?? this.avatar,
      image: image ?? this.image,
      caption: caption ?? this.caption,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      timeAgo: timeAgo ?? this.timeAgo,
      verified: verified ?? this.verified,
      challenge: challenge ?? this.challenge,
      liked: liked ?? this.liked,
    );
  }
}

class TopContributor {
  final String username;
  final String avatar;
  final int points;
  final int rank;
  final bool verified;
  final String style;

  TopContributor({
    required this.username,
    required this.avatar,
    required this.points,
    required this.rank,
    required this.verified,
    required this.style,
  });

  factory TopContributor.fromJson(Map<String, dynamic> json) {
    return TopContributor(
      username: json['username'] ?? '',
      avatar: json['avatar'] ?? '',
      points: json['points'] ?? 0,
      rank: json['rank'] ?? 0,
      verified: json['verified'] ?? false,
      style: json['style'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'avatar': avatar,
      'points': points,
      'rank': rank,
      'verified': verified,
      'style': style,
    };
  }
}
