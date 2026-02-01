class CommunitySettings {
  final String communityId;
  final bool isPrivate;
  final bool requiresApprovalToJoin;
  final String? description;

  CommunitySettings({
    required this.communityId,
    required this.isPrivate,
    required this.requiresApprovalToJoin,
    this.description,
  });

  factory CommunitySettings.fromJson(Map<String, dynamic> json) {
    return CommunitySettings(
      communityId: json['communityId'] as String,
      isPrivate: json['isPrivate'] as bool,
      requiresApprovalToJoin: json['requiresApprovalToJoin'] as bool,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'communityId': communityId,
      'isPrivate': isPrivate,
      'requiresApprovalToJoin': requiresApprovalToJoin,
      'description': description,
    };
  }
}
