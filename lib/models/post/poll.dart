class Poll {
  final String id;
  final String question;
  final List<String> options;
  final Map<String, int> votes; // option -> vote count
  final DateTime? expiresAt;

  Poll({
    required this.id,
    required this.question,
    required this.options,
    required this.votes,
    this.expiresAt,
  });

  factory Poll.fromJson(Map<String, dynamic> json) {
    return Poll(
      id: json['id'] as String,
      question: json['question'] as String,
      options: List<String>.from(json['options'] as List),
      votes: Map<String, int>.from(json['votes'] as Map),
      expiresAt:
          json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'votes': votes,
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }
}
