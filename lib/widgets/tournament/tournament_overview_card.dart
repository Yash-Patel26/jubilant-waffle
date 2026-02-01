import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TournamentOverviewCard extends StatelessWidget {
  final Map<String, dynamic> tournament;
  const TournamentOverviewCard({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
    final startDate = tournament['start_date'] != null
        ? DateTime.parse(tournament['start_date'])
        : null;
    final endDate = tournament['end_date'] != null
        ? DateTime.parse(tournament['end_date'])
        : null;
    final status = tournament['status'] ?? 'upcoming';
    final participants = (tournament['participants'] as List?)?.length ?? 0;
    final maxParticipants = tournament['max_participants'] ?? 0;
    final statusColor = status == 'ongoing'
        ? Colors.green
        : status == 'completed'
            ? Colors.grey
            : Colors.blue;
    final statusText = status[0].toUpperCase() + status.substring(1);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.emoji_events, color: Colors.amber, size: 24),
                SizedBox(width: 8),
                Text('Tournament Overview',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 24),
            // Start Date & Time
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Start Date & Time',
                          style:
                              TextStyle(color: Colors.black54, fontSize: 13)),
                      Text(
                          startDate != null
                              ? DateFormat.yMMMEd().add_Hm().format(startDate)
                              : '-',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // End Date
            Row(
              children: [
                const Icon(Icons.access_time, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('End Date',
                          style:
                              TextStyle(color: Colors.black54, fontSize: 13)),
                      Text(
                          endDate != null
                              ? DateFormat.yMMMEd().format(endDate)
                              : '-',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Text('Tournament Status',
                    style: TextStyle(color: Colors.black54)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(statusText,
                      style: TextStyle(
                          color: statusColor, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Participants', style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: maxParticipants > 0
                        ? participants / maxParticipants
                        : 0,
                    backgroundColor: Colors.grey[300],
                    color: Colors.black,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                Text('$participants/$maxParticipants',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
