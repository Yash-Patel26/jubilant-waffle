class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String? relatedId;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final String? senderId;
  final String? senderName;
  final String? senderAvatarUrl;
  final Map<String, dynamic> metadata;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    this.relatedId,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.senderId,
    this.senderName,
    this.senderAvatarUrl,
    this.metadata = const {},
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    NotificationType parseType(dynamic raw) {
      final s = (raw as String? ?? '').toLowerCase();
      switch (s) {
        case 'post_like':
        case 'like':
          return NotificationType.postLike;
        case 'post_comment':
        case 'comment':
          return NotificationType.postComment;
        case 'follow_request':
        case 'follow':
          return NotificationType.followRequest;
        case 'new_message':
        case 'message':
          return NotificationType.newMessage;
        case 'tournament_update':
        case 'tournament':
          return NotificationType.tournamentUpdate;
        case 'community_invite':
        case 'community_invitation':
          return NotificationType.communityInvite;
        case 'live_stream':
        case 'stream':
          return NotificationType.liveStream;
        case 'achievement':
        case 'badge':
          return NotificationType.achievement;
        case 'game_invite':
        case 'game_invitation':
          return NotificationType.gameInvite;
        case 'system_update':
        case 'system':
          return NotificationType.systemUpdate;
        default:
          // Try matching enum names like 'postLike'
          try {
            return NotificationType.values.firstWhere(
              (e) => e.toString().split('.').last.toLowerCase() == s,
            );
          } catch (_) {
            return NotificationType.other;
          }
      }
    }

    return NotificationModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      type: parseType(map['type']),
      relatedId: map['related_id'] as String?,
      title: map['title'] as String? ?? '',
      message: (map['message'] as String?) ?? (map['body'] as String? ?? ''),
      isRead: map['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
      senderId: map['sender_id'] as String?,
      senderName: map['sender_name'] as String?,
      senderAvatarUrl: map['sender_avatar_url'] as String?,
      metadata: Map<String, dynamic>.from(
        (map['metadata'] ?? map['data'] ?? {}),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.toString().split('.').last,
      'related_id': relatedId,
      'title': title,
      'message': message,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_avatar_url': senderAvatarUrl,
      'metadata': metadata,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? relatedId,
    String? title,
    String? message,
    bool? isRead,
    DateTime? createdAt,
    String? senderId,
    String? senderName,
    String? senderAvatarUrl,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      relatedId: relatedId ?? this.relatedId,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, userId: $userId, type: $type, title: $title, isRead: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

enum NotificationType {
  postComment,
  postLike,
  followRequest,
  newMessage,
  tournamentUpdate,
  communityInvite,
  liveStream,
  achievement,
  gameInvite,
  systemUpdate,
  other;

  String get displayName {
    switch (this) {
      case NotificationType.postComment:
        return 'Post Comment';
      case NotificationType.postLike:
        return 'Post Like';
      case NotificationType.followRequest:
        return 'Follow Request';
      case NotificationType.newMessage:
        return 'New Message';
      case NotificationType.tournamentUpdate:
        return 'Tournament Update';
      case NotificationType.communityInvite:
        return 'Community Invite';
      case NotificationType.liveStream:
        return 'Live Stream';
      case NotificationType.achievement:
        return 'Achievement';
      case NotificationType.gameInvite:
        return 'Game Invite';
      case NotificationType.systemUpdate:
        return 'System Update';
      case NotificationType.other:
        return 'Other';
    }
  }

  /// Returns a string key for the icon, to be mapped in the UI layer.
  String get iconKey {
    switch (this) {
      case NotificationType.postComment:
        return 'comment';
      case NotificationType.postLike:
        return 'favorite';
      case NotificationType.followRequest:
        return 'person_add';
      case NotificationType.newMessage:
        return 'mail';
      case NotificationType.tournamentUpdate:
        return 'emoji_events';
      case NotificationType.communityInvite:
        return 'group_add';
      case NotificationType.liveStream:
        return 'live_tv';
      case NotificationType.achievement:
        return 'military_tech';
      case NotificationType.gameInvite:
        return 'sports_esports';
      case NotificationType.systemUpdate:
        return 'system_update';
      case NotificationType.other:
        return 'notifications';
    }
  }

  /// Returns a string key for the color, to be mapped in the UI layer.
  String get colorKey {
    switch (this) {
      case NotificationType.postComment:
        return 'green';
      case NotificationType.postLike:
        return 'red';
      case NotificationType.followRequest:
        return 'blue';
      case NotificationType.newMessage:
        return 'purple';
      case NotificationType.tournamentUpdate:
        return 'orange';
      case NotificationType.communityInvite:
        return 'indigo';
      case NotificationType.liveStream:
        return 'pink';
      case NotificationType.achievement:
        return 'amber';
      case NotificationType.gameInvite:
        return 'teal';
      case NotificationType.systemUpdate:
        return 'grey';
      case NotificationType.other:
        return 'grey';
    }
  }
}
