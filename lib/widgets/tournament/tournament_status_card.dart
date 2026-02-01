import 'package:flutter/material.dart';

class TournamentStatusCard extends StatelessWidget {
  final String status;
  final String type;
  final int participants;
  final int maxParticipants;
  const TournamentStatusCard({
    super.key,
    required this.status,
    required this.type,
    required this.participants,
    required this.maxParticipants,
  });

  @override
  Widget build(BuildContext context) {
    final isFull = participants >= maxParticipants;
    final statusColor = status == 'ongoing'
        ? Colors.green
        : status == 'completed'
            ? Colors.grey
            : Colors.blue;
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
              'Tournament Status',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  isFull ? Icons.people : Icons.people_outline,
                  color: isFull ? Colors.red : Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  '$participants/$maxParticipants participants',
                  style: TextStyle(
                    color: isFull ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status[0].toUpperCase() + status.substring(1),
                    style: TextStyle(
                        color: statusColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.sports_esports,
                  color: type == 'solo' ? Colors.blue : Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  type == 'solo' ? 'Solo Tournament' : 'Team Tournament',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
