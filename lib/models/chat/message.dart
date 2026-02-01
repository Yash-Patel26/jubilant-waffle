
class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String content; // Use 'content' consistently
  final String? imageUrl;
  final bool isSeen;
  final bool isDelivered;
  final List<String> reactions;
  final DateTime createdAt;
  final bool isPinned;
  final String? sharedContentId; // ID of the shared post/reel
  final String? sharedContentType; // 'post' or 'reel'

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content, // Make content required
    this.imageUrl,
    required this.isSeen,
    required this.isDelivered,
    required this.reactions,
    required this.createdAt,
    required this.isPinned,
    this.sharedContentId,
    this.sharedContentType,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as String,
      conversationId: map['conversation_id'] as String,
      senderId: map['sender_id'] as String,
      content: (map['content'] as String?) ??
          (map['text'] as String?) ??
          '', // Use 'content' field, fallback to 'text', then empty string
      imageUrl: map['image_url'] as String? ??
          map['media_url'] as String?, // Handle both field names
      isSeen: map['is_seen'] as bool? ??
          false, // Provide default if column doesn't exist
      isDelivered: map['is_delivered'] as bool? ??
          false, // Provide default if column doesn't exist
      reactions: (map['reactions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: DateTime.parse(map['created_at'] as String),
      isPinned: map['is_pinned'] as bool? ?? false,
      sharedContentId: map['shared_content_id'] as String?,
      sharedContentType: map['shared_content_type'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content, // Use 'content' consistently
      'image_url': imageUrl,
      'is_seen': isSeen,
      'is_delivered': isDelivered,
      'reactions': reactions,
      'created_at': createdAt.toIso8601String(),
      'is_pinned': isPinned,
      'shared_content_id': sharedContentId,
      'shared_content_type': sharedContentType,
    };
  }

  // JSON serialization methods
  factory Message.fromJson(Map<String, dynamic> json) => Message.fromMap(json);
  Map<String, dynamic> toJson() => toMap();

  // Copy with method for creating modified instances
  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? content,
    String? imageUrl,
    bool? isSeen,
    bool? isDelivered,
    List<String>? reactions,
    DateTime? createdAt,
    bool? isPinned,
    String? sharedContentId,
    String? sharedContentType,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      isSeen: isSeen ?? this.isSeen,
      isDelivered: isDelivered ?? this.isDelivered,
      reactions: reactions ?? this.reactions,
      createdAt: createdAt ?? this.createdAt,
      isPinned: isPinned ?? this.isPinned,
      sharedContentId: sharedContentId ?? this.sharedContentId,
      sharedContentType: sharedContentType ?? this.sharedContentType,
    );
  }

  /// Check if this message contains shared content
  bool get hasSharedContent =>
      sharedContentId != null && sharedContentType != null;

  /// Check if this message shares a post
  bool get isSharedPost => sharedContentType == 'post';

  /// Check if this message shares a reel
  bool get isSharedReel => sharedContentType == 'reel';
}
