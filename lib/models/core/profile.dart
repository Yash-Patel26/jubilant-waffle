import 'package:gamer_flick/models/core/user.dart';
// Added for kDebugMode

class Profile {
  final String id;
  final String username;
  final String email;
  final String? profilePictureUrl;
  final String? avatarUrl;
  final String? preferredGame;
  final String? gamingId;
  final String? fullName;
  final String? bio;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool? isVerified;
  final String? status; // 'online', 'offline', 'away'
  final DateTime? lastActive;
  final int? level;
  final Map<String, dynamic>? gameStats;

  Profile({
    required this.id,
    required this.username,
    required this.email,
    this.profilePictureUrl,
    this.avatarUrl,
    this.preferredGame,
    this.gamingId,
    this.fullName,
    this.bio,
    this.createdAt,
    this.updatedAt,
    this.isVerified,
    this.status,
    this.lastActive,
    this.level, // Added missing level parameter
    this.gameStats,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    try {
      final profile = Profile(
        id: map['id'] as String,
        username: map['username'] as String? ?? '',
        email: map['email'] as String? ?? '',
        profilePictureUrl: map['profile_picture_url'] as String?,
        avatarUrl: map['avatar_url'] as String?,
        preferredGame: map['preferred_game'] as String?,
        gamingId: map['gaming_id'] as String?,
        fullName: map['full_name'] as String?,
        bio: map['bio'] as String?,
        createdAt: map['created_at'] != null
            ? DateTime.parse(map['created_at'] as String)
            : null,
        updatedAt: map['updated_at'] != null
            ? DateTime.parse(map['updated_at'] as String)
            : null,
        isVerified: map['is_verified'] as bool? ?? false,
        status: map['status'] as String? ?? 'offline',
        lastActive: map['last_active'] != null
            ? DateTime.parse(map['last_active'] as String)
            : null,
        level: map['level'] as int? ?? 1,
        gameStats: map['game_stats'] as Map<String, dynamic>? ?? {},
      );
      return profile;
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'profile_picture_url': profilePictureUrl,
      'avatar_url': avatarUrl,
      'preferred_game': preferredGame,
      'gaming_id': gamingId,
      'full_name': fullName,
      'bio': bio,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_verified': isVerified,
      'status': status,
      'last_active': lastActive?.toIso8601String(),
      'level': level, // Added missing level to map
      'game_stats': gameStats,
    };
  }

  // Convenience getter for display name
  String get displayName => fullName ?? username;

  // Convenience getter for profile picture
  String? get profilePicture => profilePictureUrl ?? avatarUrl;

  // JSON serialization methods
  factory Profile.fromJson(Map<String, dynamic> json) => Profile.fromMap(json);
  Map<String, dynamic> toJson() => toMap();

  // Convert Profile to User
  User toUser() {
    return User(
      id: id,
      username: username,
      email: email,
      fullName: fullName,
      avatarUrl: avatarUrl,
      profilePictureUrl: profilePictureUrl,
      bio: bio,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isVerified: isVerified,
      status: status,
      lastActive: lastActive,
    );
  }

  // Copy with method for updating profile
  Profile copyWith({
    String? id,
    String? username,
    String? email,
    String? profilePictureUrl,
    String? avatarUrl,
    String? preferredGame,
    String? gamingId,
    String? fullName,
    String? bio,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVerified,
    String? status,
    DateTime? lastActive,
    int? level,
    Map<String, dynamic>? gameStats,
  }) {
    return Profile(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      preferredGame: preferredGame ?? this.preferredGame,
      gamingId: gamingId ?? this.gamingId,
      fullName: fullName ?? this.fullName,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVerified: isVerified ?? this.isVerified,
      status: status ?? this.status,
      lastActive: lastActive ?? this.lastActive,
      level: level ?? this.level,
      gameStats: gameStats ?? this.gameStats,
    );
  }
}
