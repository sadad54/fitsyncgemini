class StylePost {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final String imageUrl;
  final String? caption;
  final String? outfitId; // Reference to user's outfit
  final List<String> tags;
  final int likesCount;
  final int commentsCount;
  final double? latitude;
  final double? longitude;
  final String? location;
  final DateTime createdAt;

  const StylePost({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.imageUrl,
    this.caption,
    this.outfitId,
    this.tags = const [],
    this.likesCount = 0,
    this.commentsCount = 0,
    this.latitude,
    this.longitude,
    this.location,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userAvatarUrl': userAvatarUrl,
      'imageUrl': imageUrl,
      'caption': caption,
      'outfitId': outfitId,
      'tags': tags,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'latitude': latitude,
      'longitude': longitude,
      'location': location,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory StylePost.fromMap(Map<String, dynamic> map, String id) {
    return StylePost(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userAvatarUrl: map['userAvatarUrl'],
      imageUrl: map['imageUrl'] ?? '',
      caption: map['caption'],
      outfitId: map['outfitId'],
      tags: List<String>.from(map['tags'] ?? []),
      likesCount: map['likesCount'] ?? 0,
      commentsCount: map['commentsCount'] ?? 0,
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      location: map['location'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
