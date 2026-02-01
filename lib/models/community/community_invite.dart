class CommunityInvite {
  final String id;
  final String communityId;
  final String inviterId;
  final String? inviteeEmail;
  final String? inviteeUserId;
  final String inviteLinkToken;
  final String status; // 'pending', 'accepted', 'cancelled', 'expired'
  final DateTime createdAt;
  final DateTime? expiresAt;
  final DateTime? acceptedAt;
  final String? role;
  final String? message;

  CommunityInvite({
    required this.id,
    required this.communityId,
    required this.inviterId,
    this.inviteeEmail,
    this.inviteeUserId,
    required this.inviteLinkToken,
    required this.status,
    required this.createdAt,
    this.expiresAt,
    this.acceptedAt,
    this.role,
    this.message,
  });

  factory CommunityInvite.fromMap(Map<String, dynamic> map) {
    return CommunityInvite(
      id: map['id'] as String,
      communityId: map['community_id'] as String,
      inviterId: map['inviter_id'] as String,
      inviteeEmail: map['invitee_email'] as String?,
      inviteeUserId: map['invitee_user_id'] as String?,
      inviteLinkToken: map['invite_link_token'] as String,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      expiresAt: map['expires_at'] != null
          ? DateTime.parse(map['expires_at'] as String)
          : null,
      acceptedAt: map['accepted_at'] != null
          ? DateTime.parse(map['accepted_at'] as String)
          : null,
      role: map['role'] as String?,
      message: map['message'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'community_id': communityId,
      'inviter_id': inviterId,
      'invitee_email': inviteeEmail,
      'invitee_user_id': inviteeUserId,
      'invite_link_token': inviteLinkToken,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'accepted_at': acceptedAt?.toIso8601String(),
      'role': role,
      'message': message,
    };
  }
}
