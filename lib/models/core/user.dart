class User {
  final String id;
  final String username;
  final String? email;
  final String? fullName;
  final String? avatarUrl;
  final String? profilePictureUrl;
  final String? bio;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool? isVerified;
  final String? status; // 'online', 'offline', 'away'
  final Map<String, dynamic>? profile;
  final DateTime? lastActive;

  User({
    required this.id,
    required this.username,
    this.email,
    this.fullName,
    this.avatarUrl,
    this.profilePictureUrl,
    this.bio,
    this.createdAt,
    this.updatedAt,
    this.isVerified,
    this.status,
    this.profile,
    this.lastActive,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      username: map['username'] as String? ?? 'Anonymous',
      email: map['email'] as String?,
      fullName: map['full_name'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      profilePictureUrl: map['profile_picture_url'] as String?,
      bio: map['bio'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      isVerified: map['is_verified'] as bool? ?? false,
      status: map['status'] as String? ?? 'offline',
      profile: map['profile'] as Map<String, dynamic>?,
      lastActive: map['last_active'] != null
          ? DateTime.parse(map['last_active'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'profile_picture_url': profilePictureUrl,
      'bio': bio,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_verified': isVerified,
      'status': status,
      'profile': profile,
      'last_active': lastActive?.toIso8601String(),
    };
  }

  // Convenience getter for display name
  String get displayName => fullName ?? username;

  // Convenience getter for profile picture
  String? get profilePicture => profilePictureUrl ?? avatarUrl;

  // JSON serialization methods
  factory User.fromJson(Map<String, dynamic> json) => User.fromMap(json);
  Map<String, dynamic> toJson() => toMap();

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? fullName,
    String? avatarUrl,
    String? profilePictureUrl,
    String? bio,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVerified,
    String? status,
    Map<String, dynamic>? profile,
    DateTime? lastActive,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVerified: isVerified ?? this.isVerified,
      status: status ?? this.status,
      profile: profile ?? this.profile,
      lastActive: lastActive ?? this.lastActive,
    );
  }
}

// Legacy UserProfile class for backward compatibility
class UserProfile {
  final String id;
  final String username;
  final String? avatarUrl;
  final String? profilePictureUrl;

  UserProfile({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.profilePictureUrl,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'],
      username: map['username'] ?? 'Anonymous',
      avatarUrl: map['avatar_url'],
      profilePictureUrl: map['profile_picture_url'],
    );
  }

  // Convert UserProfile to User
  User toUser() {
    return User(
      id: id,
      username: username,
      avatarUrl: avatarUrl,
      profilePictureUrl: profilePictureUrl,
      lastActive: null,
    );
  }
}
