import 'package:flutter/material.dart';

class JoinLeaveCard extends StatelessWidget {
  final bool isJoined;
  final bool isLoading;
  final bool isFull;
  final VoidCallback onJoin;
  final VoidCallback onLeave;
  const JoinLeaveCard({
    super.key,
    required this.isJoined,
    required this.isLoading,
    required this.isFull,
    required this.onJoin,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: isJoined
              ? Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'You are registered!',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: isLoading ? null : onLeave,
                      icon: const Icon(Icons.exit_to_app),
                      label: const Text('Leave Tournament'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                )
              : ElevatedButton.icon(
                  onPressed: isLoading || isFull ? null : onJoin,
                  icon: const Icon(Icons.person_add),
                  label: Text(isFull ? 'Tournament Full' : 'Join Tournament'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isFull ? Colors.grey : Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
