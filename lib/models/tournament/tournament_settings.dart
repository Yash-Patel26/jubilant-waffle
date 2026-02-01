class TournamentSettings {
  final String tournamentId;
  final int maxTeams;
  final int maxParticipantsPerTeam;
  final bool allowSpectators;
  final DateTime registrationDeadline;

  TournamentSettings({
    required this.tournamentId,
    required this.maxTeams,
    required this.maxParticipantsPerTeam,
    required this.allowSpectators,
    required this.registrationDeadline,
  });

  factory TournamentSettings.fromJson(Map<String, dynamic> json) {
    return TournamentSettings(
      tournamentId: json['tournamentId'] as String,
      maxTeams: json['maxTeams'] as int,
      maxParticipantsPerTeam: json['maxParticipantsPerTeam'] as int,
      allowSpectators: json['allowSpectators'] as bool,
      registrationDeadline: DateTime.parse(json['registrationDeadline']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tournamentId': tournamentId,
      'maxTeams': maxTeams,
      'maxParticipantsPerTeam': maxParticipantsPerTeam,
      'allowSpectators': allowSpectators,
      'registrationDeadline': registrationDeadline.toIso8601String(),
    };
  }
}
