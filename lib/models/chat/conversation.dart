class Conversation {
  final String id;
  final String type;
  final String? name;
  final String? createdBy;
  final String? lastMessage;
  final DateTime updatedAt;
  final DateTime createdAt;
  final String? user1Id;
  final String? user2Id;

  Conversation({
    required this.id,
    required this.type,
    this.name,
    this.createdBy,
    this.lastMessage,
    required this.updatedAt,
    required this.createdAt,
    this.user1Id,
    this.user2Id,
  });

  factory Conversation.fromMap(Map<String, dynamic> map) {
    return Conversation(
      id: map['id'] as String,
      type: map['type'] as String,
      name: map['name'] as String?,
      createdBy: map['created_by'] as String?,
      lastMessage: null, // last_message column doesn't exist in current schema
      updatedAt: DateTime.parse(map['updated_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      user1Id: map['user1_id'] as String?,
      user2Id: map['user2_id'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'created_by': createdBy,
      'last_message': lastMessage,
      'updated_at': updatedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'user1_id': user1Id,
      'user2_id': user2Id,
    };
  }
}
