class CommunityRules {
  final String communityId;
  final List<String> rules;

  CommunityRules({
    required this.communityId,
    required this.rules,
  });

  factory CommunityRules.fromJson(Map<String, dynamic> json) {
    return CommunityRules(
      communityId: json['communityId'] as String,
      rules: List<String>.from(json['rules'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'communityId': communityId,
      'rules': rules,
    };
  }
}
