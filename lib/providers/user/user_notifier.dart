import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gamer_flick/models/core/profile.dart';
import 'package:gamer_flick/repositories/user/user_repository.dart';
/// Provider for the [IUserRepository] implementation.
final userRepositoryProvider = Provider<IUserRepository>((ref) {
  return SupabaseUserRepository(client: Supabase.instance.client);
});

/// A Riverpod [AsyncNotifier] that manages the current user's profile state.
class UserNotifier extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return null;

    final repository = ref.watch(userRepositoryProvider);
    return await repository.getProfile(userId);
  }

  /// Refreshes the user profile data.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return null;
      return await ref.read(userRepositoryProvider).getProfile(userId);
    });
  }

  /// Updates the current user's profile.
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final success = await ref.read(userRepositoryProvider).updateProfile(userId, updates);
      if (success) {
        // Refresh the profile after a successful update
        await refresh();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  /// Follows a user and refreshes the current user's profile to update stats.
  Future<bool> followUser(String targetUserId) async {
    try {
      final success = await ref.read(userRepositoryProvider).followUser(targetUserId);
      if (success) {
        await refresh();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  /// Unfollows a user and refreshes the current user's profile.
  Future<bool> unfollowUser(String targetUserId) async {
    try {
      final success = await ref.read(userRepositoryProvider).unfollowUser(targetUserId);
      if (success) {
        await refresh();
      }
      return success;
    } catch (e) {
      return false;
    }
  }
}

/// Global provider for the [UserNotifier].
final userProfileProvider = AsyncNotifierProvider<UserNotifier, Profile?>(() {
  return UserNotifier();
});

/// Alias for [userProfileProvider] to maintain compatibility with legacy naming.
final userProvider = userProfileProvider;

/// Provider for fetching any user's profile by ID.
final otherUserProfileProvider = FutureProvider.family<Profile?, String>((ref, userId) async {
  final repository = ref.watch(userRepositoryProvider);
  return await repository.getProfile(userId);
});
