import 'package:gamer_flick/models/post/post.dart';
import 'package:gamer_flick/models/core/profile.dart';

class SharedPost {
  final String id;
  final String originalPostId;
  final String sharedById;
  final String shareType;
  final String? caption;
  final String? mediaUrl;
  final DateTime createdAt;
  final Post? originalPost;
  final Profile? sharedBy;
  final List<SharedPostRecipient> recipients;

  SharedPost({
    required this.id,
    required this.originalPostId,
    required this.sharedById,
    required this.shareType,
    this.caption,
    this.mediaUrl,
    required this.createdAt,
    this.originalPost,
    this.sharedBy,
    this.recipients = const [],
  });

  factory SharedPost.fromJson(Map<String, dynamic> json) {
    return SharedPost(
      id: json['id'] as String,
      originalPostId: json['original_post_id'] as String,
      sharedById: json['shared_by_id'] as String,
      shareType: json['share_type'] as String,
      caption: json['caption'] as String?,
      mediaUrl: json['media_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      originalPost: json['original_post'] != null
          ? Post.fromJson(json['original_post'] as Map<String, dynamic>)
          : null,
      sharedBy: json['shared_by_profile'] != null
          ? Profile.fromJson(json['shared_by_profile'] as Map<String, dynamic>)
          : null,
      recipients: (json['recipients'] as List<dynamic>? ?? [])
          .map((e) => SharedPostRecipient.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SharedPostRecipient {
  final String id;
  final String sharedPostId;
  final String recipientId;
  final bool isRead;
  final DateTime? readAt;

  SharedPostRecipient({
    required this.id,
    required this.sharedPostId,
    required this.recipientId,
    required this.isRead,
    this.readAt,
  });

  factory SharedPostRecipient.fromJson(Map<String, dynamic> json) {
    return SharedPostRecipient(
      id: json['id'] as String,
      sharedPostId: json['shared_post_id'] as String,
      recipientId: json['recipient_id'] as String,
      isRead: json['is_read'] as bool,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
    );
  }
}
