class Highlight {
  final String id;
  final String userId;
  final String gameId;
  final String title;
  final String videoUrl;
  final String? thumbnailUrl;
  final String? description;
  final int? duration;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Highlight({
    required this.id,
    required this.userId,
    required this.gameId,
    required this.title,
    required this.videoUrl,
    this.thumbnailUrl,
    this.description,
    this.duration,
    this.metadata,
    required this.createdAt,
    this.updatedAt,
  });

  factory Highlight.fromMap(Map<String, dynamic> map) {
    return Highlight(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      gameId: map['game_id'] as String,
      title: map['title'] as String,
      videoUrl: map['video_url'] as String,
      thumbnailUrl: map['thumbnail_url'] as String?,
      description: map['description'] as String?,
      duration: map['duration'] as int?,
      metadata: map['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  factory Highlight.fromJson(Map<String, dynamic> json) =>
      Highlight.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'game_id': gameId,
      'title': title,
      'video_url': videoUrl,
      'thumbnail_url': thumbnailUrl,
      'description': description,
      'duration': duration,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() => toMap();
}
