import 'package:flutter/material.dart';

class RecentParticipantsCard extends StatelessWidget {
  final List participants;
  const RecentParticipantsCard({super.key, required this.participants});

  @override
  Widget build(BuildContext context) {
    final showList = participants.take(4).toList();
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
                Icon(Icons.group, color: Colors.black54, size: 24),
                SizedBox(width: 8),
                Text('Recent Participants',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 24),
            ...showList.map((p) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: p['profile']?['avatar_url'] != null &&
                                p['profile']!['avatar_url']
                                    .toString()
                                    .isNotEmpty
                            ? NetworkImage(p['profile']!['avatar_url'])
                            : null,
                        child: (p['profile']?['avatar_url'] == null ||
                                p['profile']!['avatar_url'].toString().isEmpty)
                            ? Text(
                                (p['profile']?['username'] ?? 'U')[0]
                                    .toUpperCase(),
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.black54))
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(p['profile']?['username'] ?? 'Unknown',
                              style: const TextStyle(fontSize: 15))),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (p['status'] == 'confirmed')
                              ? Colors.black
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          (p['status'] ?? 'pending').toString(),
                          style: TextStyle(
                            color: (p['status'] == 'confirmed')
                                ? Colors.white
                                : Colors.black54,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                child: const Text('View All Participants'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
