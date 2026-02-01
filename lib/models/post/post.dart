import 'package:gamer_flick/models/core/profile.dart';

class Post {
  final String id;
  final String userId;
  final String content;
  final List<String>? mediaUrls;
  final String? gameTag;
  final String? location;
  final bool isPublic;
  final List<String>? mentions;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Profile? user;
  final int? likeCount;
  final int? commentCount;
  final bool pinned;

  Post({
    required this.id,
    required this.userId,
    required this.content,
    this.mediaUrls,
    this.gameTag,
    this.location,
    required this.isPublic,
    this.mentions,
    this.metadata,
    required this.createdAt,
    this.updatedAt,
    this.user,
    this.likeCount,
    this.commentCount,
    this.pinned = false,
  });

  factory Post.fromMap(Map<String, dynamic> map) {
    try {
      final post = Post(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        content: map['content'] as String? ?? '',
        mediaUrls: (map['media_urls'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        gameTag: map['game_tag'] as String?,
        location: map['location'] as String?,
        isPublic: map['is_public'] as bool? ?? true,
        mentions: (map['mentions'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        metadata: map['metadata'] as Map<String, dynamic>? ?? {},
        likeCount: map['like_count'] as int? ?? 0,
        commentCount: map['comment_count'] as int? ?? 0,
        pinned: map['pinned'] as bool? ?? false,
        createdAt: map['created_at'] != null
            ? DateTime.parse(map['created_at'] as String)
            : DateTime.now(),
        updatedAt: map['updated_at'] != null
            ? DateTime.parse(map['updated_at'] as String)
            : DateTime.now(),
        user: map['profiles'] != null
            ? Profile.fromMap(Map<String, dynamic>.from(map['profiles']))
            : null,
      );
      return post;
    } catch (e) {
      rethrow;
    }
  }

  factory Post.fromJson(Map<String, dynamic> json) => Post.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'content': content,
      'media_urls': mediaUrls,
      'game_tag': gameTag,
      'location': location,
      'is_public': isPublic,
      'mentions': mentions,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'profiles': user?.toMap(),
      'like_count': likeCount,
      'comment_count': commentCount,
      'pinned': pinned,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  bool get isVideo =>
      mediaUrls != null &&
      mediaUrls!.isNotEmpty &&
      (mediaUrls!.first.endsWith('.mp4') || mediaUrls!.first.endsWith('.mov'));

  bool get isImage =>
      mediaUrls != null &&
      mediaUrls!.isNotEmpty &&
      (mediaUrls!.first.endsWith('.jpg') ||
          mediaUrls!.first.endsWith('.jpeg') ||
          mediaUrls!.first.endsWith('.png') ||
          mediaUrls!.first.endsWith('.gif') ||
          mediaUrls!.first.endsWith('.webp'));

  Null get likes => null;
}
