class Reel {
  final String id;
  final String userId;
  final String? caption;
  final String videoUrl;
  final String? thumbnailUrl;
  final String? gameTag;
  final int? duration;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int? viewCount;
  final int? likeCount;
  final int? commentCount;
  final int? shareCount;
  final bool? isLiked;
  final bool? isSaved;
  final Map<String, dynamic>? user;

  Reel({
    required this.id,
    required this.userId,
    this.caption,
    required this.videoUrl,
    this.thumbnailUrl,
    this.gameTag,
    this.duration,
    this.metadata,
    required this.createdAt,
    this.updatedAt,
    this.viewCount,
    this.likeCount,
    this.commentCount,
    this.shareCount,
    this.isLiked,
    this.isSaved,
    this.user,
  });

  factory Reel.fromMap(Map<String, dynamic> map) {
    return Reel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      caption: map['caption'] as String?,
      videoUrl: map['video_url'] as String,
      thumbnailUrl: map['thumbnail_url'] as String?,
      gameTag: map['game_tag'] as String?,
      duration: map['duration'] as int?,
      metadata: map['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      viewCount: map['view_count'] as int? ?? 0,
      likeCount: map['likes'] != null && (map['likes'] as List).isNotEmpty
          ? (map['likes'][0]['count'] as int?)
          : 0,
      commentCount:
          map['comments'] != null && (map['comments'] as List).isNotEmpty
              ? (map['comments'][0]['count'] as int?)
              : 0,
      shareCount: map['share_count'] as int? ?? 0,
      isLiked: map['is_liked'] as bool? ?? false,
      isSaved: map['is_saved'] as bool? ?? false,
      user: map['user'] as Map<String, dynamic>?,
    );
  }

  factory Reel.fromJson(Map<String, dynamic> json) => Reel.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'caption': caption,
      'video_url': videoUrl,
      'thumbnail_url': thumbnailUrl,
      'game_tag': gameTag,
      'duration': duration,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'view_count': viewCount,
      'like_count': likeCount,
      'comment_count': commentCount,
      'share_count': shareCount,
      'is_liked': isLiked,
      'is_saved': isSaved,
      'user': user,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  bool get isVideo => videoUrl.endsWith('.mp4') || videoUrl.endsWith('.mov');
  String? get username => user?['username'] as String?;
  String? get avatarUrl => user?['avatar_url'] as String?;
  String? get profilePictureUrl => user?['profile_picture_url'] as String?;

  Reel copyWith({
    String? id,
    String? userId,
    String? caption,
    String? videoUrl,
    String? thumbnailUrl,
    String? gameTag,
    int? duration,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? viewCount,
    int? likeCount,
    int? commentCount,
    int? shareCount,
    bool? isLiked,
    bool? isSaved,
    Map<String, dynamic>? user,
  }) {
    return Reel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      caption: caption ?? this.caption,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      gameTag: gameTag ?? this.gameTag,
      duration: duration ?? this.duration,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      user: user ?? this.user,
    );
  }
}
