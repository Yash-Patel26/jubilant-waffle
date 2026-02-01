class Team {
  final String id;
  final String name;
  final String? description;
  final String? logoUrl;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int? memberCount;
  final List<Map<String, dynamic>>? members;

  Team({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.memberCount,
    this.members,
  });

  factory Team.fromMap(Map<String, dynamic> map) {
    return Team(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      logoUrl: map['logo_url'] as String?,
      createdBy: map['created_by'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      memberCount: map['member_count'] as int?,
      members: map['members'] != null
          ? List<Map<String, dynamic>>.from(map['members'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'logo_url': logoUrl,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'member_count': memberCount,
      'members': members,
    };
  }

  // JSON serialization methods
  factory Team.fromJson(Map<String, dynamic> json) => Team.fromMap(json);
  Map<String, dynamic> toJson() => toMap();
}
