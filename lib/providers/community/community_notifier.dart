import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamer_flick/models/community/community.dart';
import 'package:gamer_flick/repositories/community/community_repository.dart';
import 'package:gamer_flick/providers/user/user_notifier.dart';
import 'package:gamer_flick/services/community/community_invite_service.dart';
import 'package:gamer_flick/services/community/community_post_service.dart';
import 'package:gamer_flick/models/community/community_member.dart';
import 'package:gamer_flick/models/community/community_invite.dart';
import 'package:gamer_flick/models/community/community_post.dart';

final communityRepositoryProvider = Provider<ICommunityRepository>((ref) {
  return SupabaseCommunityRepository();
});

final communitiesProvider = AsyncNotifierProvider<CommunityNotifier, List<Community>>(() {
  return CommunityNotifier();
});

class CommunityNotifier extends AsyncNotifier<List<Community>> {
  @override
  Future<List<Community>> build() async {
    return ref.read(communityRepositoryProvider).fetchCommunities();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(communityRepositoryProvider).fetchCommunities());
  }

  Future<void> createCommunity(Community community) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final newCommunity = await ref.read(communityRepositoryProvider).createCommunity(community);
      final currentList = state.value ?? [];
      return [newCommunity, ...currentList];
    });
  }

  Future<void> updateCommunity(Community community) async {
    final success = await ref.read(communityRepositoryProvider).updateCommunity(community);
    if (success) await refresh();
  }

  Future<void> deleteCommunity(String id) async {
    final success = await ref.read(communityRepositoryProvider).deleteCommunity(id);
    if (success) await refresh();
  }

  Future<void> joinCommunity(String communityId) async {
    final user = ref.read(userProvider).value;
    if (user == null) return;

    final success = await ref.read(communityRepositoryProvider).joinCommunity(communityId, user.id);
    if (success) {
      await refresh();
      ref.invalidate(communityMembershipProvider(communityId));
    }
  }

  Future<void> leaveCommunity(String communityId) async {
    final user = ref.read(userProvider).value;
    if (user == null) return;

    final success = await ref.read(communityRepositoryProvider).leaveCommunity(communityId, user.id);
    if (success) {
      await refresh();
      ref.invalidate(communityMembershipProvider(communityId));
    }
  }

  Future<void> search(String query) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(communityRepositoryProvider).searchCommunities(query: query));
  }

  Future<void> updateMemberRole(String communityId, String userId, String role) async {
    final success = await ref.read(communityRepositoryProvider).updateMemberRole(communityId, userId, role);
    if (success) {
      ref.invalidate(communityMembersProvider(communityId));
    }
  }

  Future<void> banMember(String communityId, String userId) async {
    final success = await ref.read(communityRepositoryProvider).banMember(communityId, userId);
    if (success) {
      ref.invalidate(communityMembersProvider(communityId));
    }
  }

  Future<void> unbanMember(String communityId, String userId) async {
    final success = await ref.read(communityRepositoryProvider).unbanMember(communityId, userId);
    if (success) {
      ref.invalidate(communityMembersProvider(communityId));
    }
  }

  Future<void> removeMember(String communityId, String userId) async {
    final success = await ref.read(communityRepositoryProvider).removeMember(communityId, userId);
    if (success) {
      ref.invalidate(communityMembersProvider(communityId));
    }
  }

  Future<void> createInvite({
    required String communityId,
    required String inviterId,
    String? inviteeEmail,
    String? inviteeUserId,
    DateTime? expiresAt,
    String? role,
    String? message,
  }) async {
    await CommunityInviteService().createInvite(
      communityId: communityId,
      inviterId: inviterId,
      inviteeEmail: inviteeEmail,
      inviteeUserId: inviteeUserId,
      expiresAt: expiresAt,
      role: role,
      message: message,
    );
    ref.invalidate(communityInvitesProvider(communityId));
  }

  Future<void> cancelInvite(String communityId, String inviteId) async {
    await CommunityInviteService().cancelInvite(inviteId);
    ref.invalidate(communityInvitesProvider(communityId));
  }

  Future<void> resendInvite(String communityId, String inviteId) async {
    await CommunityInviteService().resendInvite(inviteId);
    ref.invalidate(communityInvitesProvider(communityId));
  }
}

final communityDetailProvider = FutureProvider.family<Community?, String>((ref, communityId) async {
  return ref.watch(communityRepositoryProvider).getCommunityById(communityId);
});

final communityMembershipProvider = FutureProvider.family<bool, String>((ref, communityId) async {
  final user = ref.watch(userProvider).value;
  if (user == null) return false;
  
  final members = await ref.watch(communityRepositoryProvider).getCommunityMembers(communityId);
  return members.any((m) => m.userId == user.id);
});

final communityMembersProvider = FutureProvider.family<List<CommunityMember>, String>((ref, communityId) async {
  return ref.watch(communityRepositoryProvider).getCommunityMembers(communityId);
});



final communityInvitesProvider = FutureProvider.family<List<CommunityInvite>, String>((ref, communityId) async {
  return CommunityInviteService().fetchInvites(communityId);
});

final joinedCommunitiesProvider = FutureProvider<List<Community>>((ref) async {
  final user = ref.watch(userProvider).value;
  if (user == null) return [];
  
  final allCommunities = ref.watch(communitiesProvider).value ?? [];
  final repository = ref.watch(communityRepositoryProvider);
  
  // This is a bit inefficient if we have thousands of communities, 
  // but for the current scale it's fine.
  // Ideally, Supabase should handle this filter.
  final members = await Future.wait(allCommunities.map((c) => repository.getCommunityMembers(c.id)));
  
  final joinedIds = <String>[];
  for (int i = 0; i < allCommunities.length; i++) {
    if (members[i].any((m) => m.userId == user.id)) {
      joinedIds.add(allCommunities[i].id);
    }
  }
  
  return allCommunities.where((c) => joinedIds.contains(c.id)).toList();
});
