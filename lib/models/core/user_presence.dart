enum PresenceStatus {
  online,
  offline,
  away,
}

class UserPresence {
  final String userId;
  final PresenceStatus status;
  final DateTime lastSeen;

  UserPresence({
    required this.userId,
    required this.status,
    required this.lastSeen,
  });

  factory UserPresence.fromJson(Map<String, dynamic> json) {
    return UserPresence(
      userId: json['user_id'],
      status: PresenceStatus.values.firstWhere(
        (e) => e.toString() == 'PresenceStatus.${json['status']}',
        orElse: () => PresenceStatus.offline,
      ),
      lastSeen: DateTime.parse(json['last_seen']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'status': status.toString().split('.').last,
      'last_seen': lastSeen.toIso8601String(),
    };
  }
}
