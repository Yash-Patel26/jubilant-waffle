import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamer_flick/providers/game/leaderboard_notifier.dart';
import 'package:gamer_flick/models/game/leaderboard_entry.dart';

class LeaderboardTypeSelector extends ConsumerWidget {
  const LeaderboardTypeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentType = ref.watch(leaderboardTypeProvider);
    
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: LeaderboardType.values.map((type) {
          final isSelected = currentType == type;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildTypeChip(context, ref, type, isSelected),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTypeChip(
    BuildContext context,
    WidgetRef ref,
    LeaderboardType type,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () {
        ref.read(leaderboardTypeProvider.notifier).state = type;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6C7FFF) : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6C7FFF)
                : Colors.grey.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              type.displayName,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              type.description,
              style: TextStyle(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.8)
                    : Colors.grey.withValues(alpha: 0.6),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
