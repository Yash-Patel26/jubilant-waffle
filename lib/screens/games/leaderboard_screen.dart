import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamer_flick/providers/game/leaderboard_notifier.dart';
import 'package:gamer_flick/models/game/leaderboard_entry.dart';
import '../../widgets/leaderboard/leaderboard_entry_widget.dart';
import '../../widgets/leaderboard/leaderboard_type_selector.dart';
import '../../widgets/leaderboard/user_rank_card.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  @override
  Widget build(BuildContext context) {
    final type = ref.watch(leaderboardTypeProvider);
    final leaderboardState = ref.watch(leaderboardProvider(type));
    
    // We can use a FutureProvider for rank or watch the current user from auth
    final userRankState = ref.watch(currentUserRankProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            _buildAppBar(ref),

            // User Rank Card
            userRankState.when(
              data: (rank) => rank != null ? UserRankCard(entry: rank) : const SizedBox.shrink(),
              loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
              error: (err, stack) => const SizedBox.shrink(),
            ),

            // Leaderboard Type Selector
            const LeaderboardTypeSelector(),

            // Leaderboard Content
            Expanded(
              child: leaderboardState.when(
                data: (entries) => entries.isEmpty 
                    ? _buildEmptyWidget() 
                    : _buildLeaderboardList(entries),
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C7FFF)),
                  ),
                ),
                error: (err, stack) => _buildErrorWidget(err.toString()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Leaderboard',
              style: TextStyle(
                color: Color.fromARGB(255, 139, 139, 139),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            onPressed: () {
              final type = ref.read(leaderboardTypeProvider);
              ref.read(leaderboardProvider(type).notifier).refresh();
              ref.invalidate(currentUserRankProvider);
            },
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'Oops! Something went wrong',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final type = ref.read(leaderboardTypeProvider);
              ref.read(leaderboardProvider(type).notifier).refresh();
              ref.invalidate(currentUserRankProvider);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C7FFF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.emoji_events_outlined,
            color: Colors.grey,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Leaderboard Data',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start creating content and engaging with the community to appear on the leaderboard!',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList(List<LeaderboardEntry> entries) {
    return RefreshIndicator(
      onRefresh: () async {
        final type = ref.read(leaderboardTypeProvider);
        await ref.read(leaderboardProvider(type).notifier).refresh();
        ref.invalidate(currentUserRankProvider);
      },
      color: const Color(0xFF6C7FFF),
      backgroundColor: const Color(0xFF1A1A1A),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: LeaderboardEntryWidget(
              entry: entry,
              rank: index + 1,
            ),
          );
        },
      ),
    );
  }
}
