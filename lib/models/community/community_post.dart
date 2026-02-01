import 'package:gamer_flick/models/community/community.dart';
import 'package:gamer_flick/models/core/profile.dart';

enum PostType { text, image, video, link, poll, gallery }

class CommunityPost {
  final String id;
  final String communityId;
  final String authorId;
  final String title;
  final String content;
  final PostType postType;
  final List<String> imageUrls;
  final List<String> imageCaptions;
  final String? linkUrl;
  final String? linkDomain;
  final Map<String, dynamic>? pollData;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool pinned;
  final bool locked;
  final bool spoiler;
  final bool nsfw;
  final bool contestMode;
  final bool stickied;
  final bool archived;
  final bool removed;
  final String? removalReason;
  final String? flair;
  final String? flairColor;
  final int upvotes;
  final int downvotes;
  final int score;
  final int commentCount;
  final int viewCount;
  final int shareCount;
  final double upvoteRatio;
  final List<String> awards;
  final Map<String, dynamic>? metadata;
  final Community? community;
  final Profile? author;
  final bool isEdited;
  final DateTime? editedAt;
  final String? editReason;

  CommunityPost({
    required this.id,
    required this.communityId,
    required this.authorId,
    required this.title,
    required this.content,
    this.postType = PostType.text,
    required this.imageUrls,
    required this.imageCaptions,
    this.linkUrl,
    this.linkDomain,
    this.pollData,
    required this.createdAt,
    this.updatedAt,
    this.pinned = false,
    this.locked = false,
    this.spoiler = false,
    this.nsfw = false,
    this.contestMode = false,
    this.stickied = false,
    this.archived = false,
    this.removed = false,
    this.removalReason,
    this.flair,
    this.flairColor,
    this.upvotes = 0,
    this.downvotes = 0,
    this.score = 0,
    this.commentCount = 0,
    this.viewCount = 0,
    this.shareCount = 0,
    this.upvoteRatio = 1.0,
    this.awards = const [],
    this.metadata,
    this.community,
    this.author,
    this.isEdited = false,
    this.editedAt,
    this.editReason,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id'] as String,
      communityId: json['community_id'] as String,
      authorId: json['author_id'] as String,
      title: json['title'] as String? ?? '',
      content: json['content'] as String,
      postType: _parsePostType(json['post_type'] as String?),
      imageUrls: List<String>.from(json['image_urls'] ?? []),
      imageCaptions: List<String>.from(json['image_captions'] ?? []),
      linkUrl: json['link_url'] as String?,
      linkDomain: json['link_domain'] as String?,
      pollData: json['poll_data'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      pinned: json['pinned'] as bool? ?? false,
      locked: json['locked'] as bool? ?? false,
      spoiler: json['spoiler'] as bool? ?? false,
      nsfw: json['nsfw'] as bool? ?? false,
      contestMode: json['contest_mode'] as bool? ?? false,
      stickied: json['stickied'] as bool? ?? false,
      archived: json['archived'] as bool? ?? false,
      removed: json['removed'] as bool? ?? false,
      removalReason: json['removal_reason'] as String?,
      flair: json['flair'] as String?,
      flairColor: json['flair_color'] as String?,
      upvotes: json['upvotes'] as int? ?? 0,
      downvotes: json['downvotes'] as int? ?? 0,
      score: json['score'] as int? ?? 0,
      commentCount: json['comment_count'] as int? ?? 0,
      viewCount: json['view_count'] as int? ?? 0,
      shareCount: json['share_count'] as int? ?? 0,
      upvoteRatio: (json['upvote_ratio'] as num?)?.toDouble() ?? 1.0,
      awards: List<String>.from(json['awards'] ?? []),
      metadata: json['metadata'] as Map<String, dynamic>?,
      community: json['communities'] != null
          ? Community.fromJson(json['communities'] as Map<String, dynamic>)
          : null,
      author: json['profiles'] != null
          ? Profile.fromJson(json['profiles'] as Map<String, dynamic>)
          : null,
      isEdited: json['is_edited'] as bool? ?? false,
      editedAt: json['edited_at'] != null
          ? DateTime.parse(json['edited_at'] as String)
          : null,
      editReason: json['edit_reason'] as String?,
    );
  }

  static PostType _parsePostType(String? type) {
    switch (type) {
      case 'image':
        return PostType.image;
      case 'video':
        return PostType.video;
      case 'link':
        return PostType.link;
      case 'poll':
        return PostType.poll;
      case 'gallery':
        return PostType.gallery;
      default:
        return PostType.text;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'community_id': communityId,
      'author_id': authorId,
      'title': title,
      'content': content,
      'post_type': _postTypeToString(postType),
      'image_urls': imageUrls,
      'image_captions': imageCaptions,
      'link_url': linkUrl,
      'link_domain': linkDomain,
      'poll_data': pollData,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'pinned': pinned,
      'locked': locked,
      'spoiler': spoiler,
      'nsfw': nsfw,
      'contest_mode': contestMode,
      'stickied': stickied,
      'archived': archived,
      'removed': removed,
      'removal_reason': removalReason,
      'flair': flair,
      'flair_color': flairColor,
      'upvotes': upvotes,
      'downvotes': downvotes,
      'score': score,
      'comment_count': commentCount,
      'view_count': viewCount,
      'share_count': shareCount,
      'upvote_ratio': upvoteRatio,
      'awards': awards,
      'metadata': metadata,
      'is_edited': isEdited,
      'edited_at': editedAt?.toIso8601String(),
      'edit_reason': editReason,
    };
  }

  String _postTypeToString(PostType type) {
    switch (type) {
      case PostType.text:
        return 'text';
      case PostType.image:
        return 'image';
      case PostType.video:
        return 'video';
      case PostType.link:
        return 'link';
      case PostType.poll:
        return 'poll';
      case PostType.gallery:
        return 'gallery';
    }
  }

  CommunityPost copyWith({
    String? id,
    String? communityId,
    String? authorId,
    String? title,
    String? content,
    PostType? postType,
    List<String>? imageUrls,
    List<String>? imageCaptions,
    String? linkUrl,
    String? linkDomain,
    Map<String, dynamic>? pollData,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? pinned,
    bool? locked,
    bool? spoiler,
    bool? nsfw,
    bool? contestMode,
    bool? stickied,
    bool? archived,
    bool? removed,
    String? removalReason,
    String? flair,
    String? flairColor,
    int? upvotes,
    int? downvotes,
    int? score,
    int? commentCount,
    int? viewCount,
    int? shareCount,
    double? upvoteRatio,
    List<String>? awards,
    Map<String, dynamic>? metadata,
    Community? community,
    Profile? author,
    bool? isEdited,
    DateTime? editedAt,
    String? editReason,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      communityId: communityId ?? this.communityId,
      authorId: authorId ?? this.authorId,
      title: title ?? this.title,
      content: content ?? this.content,
      postType: postType ?? this.postType,
      imageUrls: imageUrls ?? this.imageUrls,
      imageCaptions: imageCaptions ?? this.imageCaptions,
      linkUrl: linkUrl ?? this.linkUrl,
      linkDomain: linkDomain ?? this.linkDomain,
      pollData: pollData ?? this.pollData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pinned: pinned ?? this.pinned,
      locked: locked ?? this.locked,
      spoiler: spoiler ?? this.spoiler,
      nsfw: nsfw ?? this.nsfw,
      contestMode: contestMode ?? this.contestMode,
      stickied: stickied ?? this.stickied,
      archived: archived ?? this.archived,
      removed: removed ?? this.removed,
      removalReason: removalReason ?? this.removalReason,
      flair: flair ?? this.flair,
      flairColor: flairColor ?? this.flairColor,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      score: score ?? this.score,
      commentCount: commentCount ?? this.commentCount,
      viewCount: viewCount ?? this.viewCount,
      shareCount: shareCount ?? this.shareCount,
      upvoteRatio: upvoteRatio ?? this.upvoteRatio,
      awards: awards ?? this.awards,
      metadata: metadata ?? this.metadata,
      community: community ?? this.community,
      author: author ?? this.author,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      editReason: editReason ?? this.editReason,
    );
  }
}

class CommunityPostLike {
  final String id;
  final String postId;
  final String userId;
  final int vote; // 1 for upvote, -1 for downvote, 0 for no vote
  final DateTime createdAt;

  CommunityPostLike({
    required this.id,
    required this.postId,
    required this.userId,
    required this.vote,
    required this.createdAt,
  });

  factory CommunityPostLike.fromJson(Map<String, dynamic> json) {
    return CommunityPostLike(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
      vote: json['vote'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'user_id': userId,
      'vote': vote,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class CommunityPostComment {
  final String id;
  final String postId;
  final String userId;
  final String content;
  final String? parentCommentId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isEdited;
  final DateTime? editedAt;
  final String? editReason;
  final bool removed;
  final String? removalReason;
  final int upvotes;
  final int downvotes;
  final int score;
  final List<String> awards;
  final Profile? author;
  final List<CommunityPostComment> replies;
  final int replyCount;
  final bool locked;
  final bool stickied;
  final bool distinguished; // 'admin', 'moderator', 'special'

  CommunityPostComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    this.parentCommentId,
    required this.createdAt,
    this.updatedAt,
    this.isEdited = false,
    this.editedAt,
    this.editReason,
    this.removed = false,
    this.removalReason,
    this.upvotes = 0,
    this.downvotes = 0,
    this.score = 0,
    this.awards = const [],
    this.author,
    this.replies = const [],
    this.replyCount = 0,
    this.locked = false,
    this.stickied = false,
    this.distinguished = false,
  });

  factory CommunityPostComment.fromJson(Map<String, dynamic> json) {
    return CommunityPostComment(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      parentCommentId: json['parent_comment_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      isEdited: json['is_edited'] as bool? ?? false,
      editedAt: json['edited_at'] != null
          ? DateTime.parse(json['edited_at'] as String)
          : null,
      editReason: json['edit_reason'] as String?,
      removed: json['removed'] as bool? ?? false,
      removalReason: json['removal_reason'] as String?,
      upvotes: json['upvotes'] as int? ?? 0,
      downvotes: json['downvotes'] as int? ?? 0,
      score: json['score'] as int? ?? 0,
      awards: List<String>.from(json['awards'] ?? []),
      author: json['profiles'] != null
          ? Profile.fromJson(json['profiles'] as Map<String, dynamic>)
          : null,
      replies: json['replies'] != null
          ? (json['replies'] as List)
              .map((reply) =>
                  CommunityPostComment.fromJson(reply as Map<String, dynamic>))
              .toList()
          : [],
      replyCount: json['reply_count'] as int? ?? 0,
      locked: json['locked'] as bool? ?? false,
      stickied: json['stickied'] as bool? ?? false,
      distinguished: json['distinguished'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'user_id': userId,
      'content': content,
      'parent_comment_id': parentCommentId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_edited': isEdited,
      'edited_at': editedAt?.toIso8601String(),
      'edit_reason': editReason,
      'removed': removed,
      'removal_reason': removalReason,
      'upvotes': upvotes,
      'downvotes': downvotes,
      'score': score,
      'awards': awards,
      'reply_count': replyCount,
      'locked': locked,
      'stickied': stickied,
      'distinguished': distinguished,
    };
  }
}
