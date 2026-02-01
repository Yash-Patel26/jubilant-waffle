class TournamentMedia {
  final String id;
  final String tournamentId;
  final String userId;
  final String mediaUrl;
  final String? caption;
  final String mediaType; // 'image', 'video', 'document'
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isApproved;
  final bool isFlagged;
  final String? flaggedReason;
  final Map<String, dynamic>? user;

  TournamentMedia({
    required this.id,
    required this.tournamentId,
    required this.userId,
    required this.mediaUrl,
    this.caption,
    required this.mediaType,
    required this.createdAt,
    this.updatedAt,
    this.isApproved = false,
    this.isFlagged = false,
    this.flaggedReason,
    this.user,
  });

  factory TournamentMedia.fromMap(Map<String, dynamic> map) {
    return TournamentMedia(
      id: map['id'] as String,
      tournamentId: map['tournament_id'] as String,
      userId: map['user_id'] as String,
      mediaUrl: map['media_url'] as String,
      caption: map['caption'] as String?,
      mediaType: map['media_type'] as String? ?? 'image',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      isApproved: map['is_approved'] as bool? ?? false,
      isFlagged: map['is_flagged'] as bool? ?? false,
      flaggedReason: map['flagged_reason'] as String?,
      user: map['user'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tournament_id': tournamentId,
      'user_id': userId,
      'media_url': mediaUrl,
      'caption': caption,
      'media_type': mediaType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_approved': isApproved,
      'is_flagged': isFlagged,
      'flagged_reason': flaggedReason,
      'user': user,
    };
  }

  bool get isVideo =>
      mediaType == 'video' ||
      mediaUrl.endsWith('.mp4') ||
      mediaUrl.endsWith('.mov');

  bool get isImage =>
      mediaType == 'image' ||
      (mediaUrl.endsWith('.jpg') ||
          mediaUrl.endsWith('.jpeg') ||
          mediaUrl.endsWith('.png') ||
          mediaUrl.endsWith('.gif') ||
          mediaUrl.endsWith('.webp'));

  bool get isDocument =>
      mediaType == 'document' ||
      (mediaUrl.endsWith('.pdf') ||
          mediaUrl.endsWith('.doc') ||
          mediaUrl.endsWith('.docx'));
}
