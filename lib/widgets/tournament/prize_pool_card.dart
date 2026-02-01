import 'package:flutter/material.dart';

class PrizePoolCard extends StatelessWidget {
  final Map<String, dynamic> tournament;
  const PrizePoolCard({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
    final prize = tournament['prize_pool'] ?? '0';
    final prizeDetails = tournament['prize_details'] ?? '';
    // Example: prizeDetails = '1st:1500,2nd:700,3rd:300'
    final breakdown = <String, String>{};
    if (prizeDetails is String && prizeDetails.isNotEmpty) {
      for (final part in prizeDetails.split(',')) {
        final kv = part.split(':');
        if (kv.length == 2) breakdown[kv[0].trim()] = kv[1].trim();
      }
    }
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
                Text('Prize Pool',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 24),
            Text(' 24$prize',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                    color: Colors.green)),
            const SizedBox(height: 16),
            if (breakdown.isNotEmpty) ...[
              for (final entry in breakdown.entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          '${entry.key[0].toUpperCase()}${entry.key.substring(1)} Place:',
                          style: const TextStyle(fontSize: 16)),
                      Text(' 24${entry.value}',
                          style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
