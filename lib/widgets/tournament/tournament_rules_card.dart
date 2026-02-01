import 'package:flutter/material.dart';

class TournamentRulesCard extends StatelessWidget {
  final dynamic rules;
  const TournamentRulesCard({super.key, required this.rules});

  @override
  Widget build(BuildContext context) {
    final List<String> rulesList = rules is String
        ? (rules as String)
            .split(RegExp(r'\r?\n|\n|\r'))
            .where((r) => r.trim().isNotEmpty)
            .toList()
        : (rules as List?)?.cast<String>() ?? [];
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
                Icon(Icons.rule, color: Colors.blue, size: 24),
                SizedBox(width: 8),
                Text('Tournament Rules',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 24),
            ...rulesList.map((rule) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.circle, size: 8, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                          child:
                              Text(rule, style: const TextStyle(fontSize: 15))),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
