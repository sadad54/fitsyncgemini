class UserProfile {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? profileImageUrl;
  final String? styleArchetype;
  final Map<String, dynamic> quizResults;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.profileImageUrl,
    this.styleArchetype,
    this.quizResults = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => '$firstName $lastName';
  String get initials => '${firstName[0]}${lastName[0]}';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'styleArchetype': styleArchetype,
      'quizResults': quizResults,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map, String id) {
    return UserProfile(
      id: id,
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      email: map['email'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      styleArchetype: map['styleArchetype'],
      quizResults: Map<String, dynamic>.from(map['quizResults'] ?? {}),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  UserProfile copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? profileImageUrl,
    String? styleArchetype,
    Map<String, dynamic>? quizResults,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      styleArchetype: styleArchetype ?? this.styleArchetype,
      quizResults: quizResults ?? this.quizResults,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
