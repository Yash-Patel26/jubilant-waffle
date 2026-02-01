class Event {
  final String id;
  final String creatorId;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final List<String> participantIds;

  Event({
    required this.id,
    required this.creatorId,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    this.location,
    required this.participantIds,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      creatorId: json['creator_id'],
      title: json['title'],
      description: json['description'],
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      location: json['location'],
      participantIds: List<String>.from(json['participant_ids']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creator_id': creatorId,
      'title': title,
      'description': description,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'location': location,
      'participant_ids': participantIds,
    };
  }
}
