import 'package:flutter/material.dart';

class ParticipantsListCard extends StatelessWidget {
  final List participants;
  const ParticipantsListCard({super.key, required this.participants});

  Color _getRoleColor(String roleName) {
    switch (roleName.toLowerCase()) {
      case 'owner':
        return Colors.red;
      case 'moderator':
        return Colors.orange;
      case 'member':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Participants',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            if (participants.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No participants yet. Be the first to join!',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: participants.length,
                itemBuilder: (context, index) {
                  final participant = participants[index];
                  final profile = participant['profile'];
                  final role = participant['role'];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: profile?['avatar_url'] != null
                            ? NetworkImage(profile['avatar_url'])
                            : null,
                        child: profile?['avatar_url'] == null
                            ? Text(
                                profile?['username']?[0].toUpperCase() ?? 'U')
                            : null,
                      ),
                      title: Text(profile?['username'] ?? 'Unknown User'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (participant['in_game_name'] != null)
                            Text('In-game: ${participant['in_game_name']}'),
                          if (participant['team_name'] != null)
                            Text('Team: ${participant['team_name']}'),
                        ],
                      ),
                      trailing: role != null
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getRoleColor(role['name'])
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                role['name'],
                                style: TextStyle(
                                  color: _getRoleColor(role['name']),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : null,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
