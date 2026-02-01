import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gamer_flick/models/game/leaderboard_entry.dart';
import 'package:gamer_flick/repositories/game/leaderboard_repository.dart';
import 'package:gamer_flick/repositories/auth/auth_repository.dart';

/// A family-based [AsyncNotifier] that manages leaderboard state by type.
class LeaderboardNotifier extends FamilyAsyncNotifier<List<LeaderboardEntry>, LeaderboardType> {
  late final ILeaderboardRepository _repository;
  final SupabaseClient _client = Supabase.instance.client;
  
  // Channels for real-time updates
  RealtimeChannel? _leaderboardChannel;
  Timer? _refreshTimer;
  Timer? _debounceTimer;

  @override
  FutureOr<List<LeaderboardEntry>> build(LeaderboardType arg) {
    _repository = ref.watch(leaderboardRepositoryProvider);
    
    // Setup real-time subscriptions and periodic refresh
    _setupSubscriptions();
    _startPeriodicRefresh();

    ref.onDispose(() {
      _leaderboardChannel?.unsubscribe();
      _refreshTimer?.cancel();
      _debounceTimer?.cancel();
    });

    return _fetchLeaderboard();
  }

  Future<List<LeaderboardEntry>> _fetchLeaderboard() async {
    return _repository.getLeaderboard(type: arg);
  }

  void _setupSubscriptions() {
    try {
      // Subscribe to simplified leaderboard scores table directly
      _leaderboardChannel = _client.channel('leaderboard_updates_${arg.name}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'leaderboard_scores',
          callback: (_) => _debouncedRefresh(),
        ).subscribe();
    } catch (e) {
      // Silent fail - manual refresh or periodic timer will take over
    }
  }

  void _debouncedRefresh() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      refresh();
    });
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) => refresh());
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() => _fetchLeaderboard());
  }

  /// Manually update user score (triggers underlying logic)
  Future<void> updateUserScore() async {
    final userId = ref.read(authRepositoryProvider).currentUser?.id;
    if (userId != null) {
      await _repository.updateUserScore(userId);
      await refresh();
    }
  }
}

/// Global provider for the selected leaderboard type.
final leaderboardTypeProvider = StateProvider<LeaderboardType>((ref) => LeaderboardType.overall);

/// Global provider for the [LeaderboardNotifier] family.
final leaderboardProvider = AsyncNotifierProviderFamily<LeaderboardNotifier, List<LeaderboardEntry>, LeaderboardType>(
  LeaderboardNotifier.new,
);

/// Provider for a specific user's rank.
final userRankProvider = FutureProvider.family<LeaderboardEntry?, String>((ref, userId) {
  return ref.watch(leaderboardRepositoryProvider).getUserRank(userId);
});

/// Convenience provider for the current authenticated user's rank.
final currentUserRankProvider = FutureProvider<LeaderboardEntry?>((ref) async {
  final userId = ref.watch(authRepositoryProvider).currentUser?.id;
  if (userId == null) return null;
  return ref.watch(leaderboardRepositoryProvider).getUserRank(userId);
});
