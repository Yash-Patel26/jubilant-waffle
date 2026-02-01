class CommunityRole {
  final String id;
  final String communityId;
  final String name;
  final String? description;
  final bool isDefault;
  final List<String> permissions;

  CommunityRole({
    required this.id,
    required this.communityId,
    required this.name,
    this.description,
    this.isDefault = false,
    this.permissions = const [],
  });

  factory CommunityRole.fromMap(Map<String, dynamic> map) {
    return CommunityRole(
      id: map['id'] as String,
      communityId: map['community_id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      isDefault: map['is_default'] as bool? ?? false,
      permissions: map['permissions'] != null
          ? List<String>.from(map['permissions'])
          : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'community_id': communityId,
      'name': name,
      'description': description,
      'is_default': isDefault,
      'permissions': permissions,
    };
  }
}
