class Tournament {
  final String id;
  final String name;
  final String description;
  final String type; // 'solo' or 'team'
  final String game;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime createdAt;
  final String createdBy;
  final int maxParticipants;
  final String status; // 'upcoming', 'ongoing', 'completed'
  final Map<String, dynamic>? creator;
  final int? participantCount;
  final int? matchCount;
  final String? prizePool;
  final String? rules;
  final String? mediaUrl;

  Tournament({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.game,
    required this.startDate,
    this.endDate,
    required this.createdAt,
    required this.createdBy,
    required this.maxParticipants,
    required this.status,
    this.creator,
    this.participantCount,
    this.matchCount,
    this.prizePool,
    this.rules,
    this.mediaUrl,
  });

  factory Tournament.fromMap(Map<String, dynamic> map) {
    return Tournament(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? 'Untitled Tournament').toString(),
      description: (map['description'] ?? '').toString(),
      type: (map['type'] ?? 'solo').toString(),
      game: (map['game'] ?? 'Gaming').toString(),
      startDate: map['start_date'] != null
          ? DateTime.tryParse(map['start_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      endDate: map['end_date'] != null
          ? DateTime.tryParse(map['end_date'].toString())
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      createdBy: (map['created_by'] ?? '').toString(),
      maxParticipants: int.tryParse(map['max_participants']?.toString() ?? '0') ?? 0,
      status: map['status']?.toString() ?? 'upcoming',
      creator: map['creator'] as Map<String, dynamic>?,
      participantCount: map['participants'] is List && (map['participants'] as List).isNotEmpty
          ? int.tryParse(map['participants'][0]['count']?.toString() ?? '0')
          : int.tryParse(map['participant_count']?.toString() ?? '0'),
      matchCount: map['matches'] is List && (map['matches'] as List).isNotEmpty
          ? int.tryParse(map['matches'][0]['count']?.toString() ?? '0')
          : int.tryParse(map['match_count']?.toString() ?? '0'),
      prizePool: map['prize_pool']?.toString(),
      rules: map['rules']?.toString(),
      mediaUrl: map['media_url']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type,
      'game': game,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'created_by': createdBy,
      'max_participants': maxParticipants,
      'status': status,
      'creator': creator,
      'participant_count': participantCount,
      'match_count': matchCount,
      'prize_pool': prizePool,
      'rules': rules,
      'media_url': mediaUrl,
    };
  }

  bool get isOngoing {
    final now = DateTime.now();
    if (endDate != null) {
      return now.isAfter(startDate) && now.isBefore(endDate!);
    }
    // If no end date, consider ongoing for 24 hours after start
    return now.isAfter(startDate) &&
        now.isBefore(startDate.add(const Duration(days: 1)));
  }

  bool get isUpcoming => DateTime.now().isBefore(startDate);

  bool get isCompleted {
    if (endDate != null) {
      return DateTime.now().isAfter(endDate!);
    }
    return false;
  }

  String get statusText {
    if (isOngoing) return 'Ongoing';
    if (isUpcoming) return 'Upcoming';
    if (isCompleted) return 'Completed';
    return 'Unknown';
  }

  // JSON serialization methods
  factory Tournament.fromJson(Map<String, dynamic> json) =>
      Tournament.fromMap(json);
  Map<String, dynamic> toJson() => toMap();
}
