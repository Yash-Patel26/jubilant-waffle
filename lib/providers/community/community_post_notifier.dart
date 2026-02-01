import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamer_flick/models/community/community_post.dart';
import 'package:gamer_flick/repositories/community/community_post_repository.dart';
import 'package:gamer_flick/repositories/auth/auth_repository.dart';
import 'package:gamer_flick/services/community/content_ranking_service.dart';

class CommunityPostParams {
  final String communityId;
  final SortType sortType;
  final TopTimeWindow topWindow;

  CommunityPostParams({
    required this.communityId,
    this.sortType = SortType.hot,
    this.topWindow = TopTimeWindow.all,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommunityPostParams &&
          runtimeType == other.runtimeType &&
          communityId == other.communityId &&
          sortType == other.sortType &&
          topWindow == other.topWindow;

  @override
  int get hashCode => communityId.hashCode ^ sortType.hashCode ^ topWindow.hashCode;
}

class CommunityPostNotifier extends FamilyAsyncNotifier<List<CommunityPost>, CommunityPostParams> {
  late final ICommunityPostRepository _repository;

  @override
  FutureOr<List<CommunityPost>> build(CommunityPostParams arg) {
    _repository = ref.watch(communityPostRepositoryProvider);
    return _fetchPosts();
  }

  Future<List<CommunityPost>> _fetchPosts() async {
    return _repository.fetchPosts(
      arg.communityId,
      sortType: arg.sortType,
      topWindow: arg.topWindow,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchPosts());
  }

  Future<void> votePost(String postId, int vote) async {
    final auth = ref.read(authRepositoryProvider);
    final user = auth.currentUser;
    if (user == null) return;

    try {
      await _repository.votePost(
        postId: postId,
        userId: user.id,
        vote: vote,
      );
      
      // Update local state for immediate feedback if possible, 
      // or just refresh. Refreshing is safer with ranking algorithms.
      // But for a better UX, we might want to optimistic update.
      _optimisticVoteUpdate(postId, vote);
    } catch (e) {
      // Handle error, maybe revert optimistic update
      refresh();
    }
  }

  void _optimisticVoteUpdate(String postId, int vote) {
    if (!state.hasValue) return;
    
    final posts = state.value!;
    final index = posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = posts[index];
    // This is a bit simplified as we don't know the user's previous vote here easily
    // without more complex state management. For now, let's just refresh to be safe
    // but in a real app we'd have a user_votes map.
    refresh(); 
  }

  Future<void> createPost(CommunityPost post) async {
    await _repository.createPost(post);
    refresh();
  }

  Future<void> deletePost(String postId) async {
    await _repository.deletePost(postId);
    if (state.hasValue) {
      state = AsyncValue.data(
        state.value!.where((p) => p.id != postId).toList(),
      );
    }
  }

  // Moderation methods
  Future<void> pinPost(String postId) async {
    await _repository.pinPost(postId);
    refresh();
  }

  Future<void> lockPost(String postId, {String? reason}) async {
    await _repository.lockPost(postId, reason: reason);
    refresh();
  }

  // Comment management
  Future<void> addComment(String postId, String content) async {
    final auth = ref.read(authRepositoryProvider);
    final user = auth.currentUser;
    if (user == null) return;
  }
}

final communityPostsProvider = AsyncNotifierProviderFamily<CommunityPostNotifier, List<CommunityPost>, CommunityPostParams>(
  CommunityPostNotifier.new,
);

// Provider for specific post details
final communityPostDetailsProvider = FutureProvider.family<CommunityPost?, String>((ref, postId) {
  return ref.watch(communityPostRepositoryProvider).getPostById(postId);
});

// Provider for post comments
final communityPostCommentsProvider = FutureProvider.family<List<CommunityPostComment>, String>((ref, postId) {
  return ref.watch(communityPostRepositoryProvider).fetchComments(postId);
});

// Provider for user's vote on a post
final userPostVoteProvider = FutureProvider.family<int, String>((ref, postId) async {
  final auth = ref.watch(authRepositoryProvider);
  final user = auth.currentUser;
  if (user == null) return 0;
  
  return ref.watch(communityPostRepositoryProvider).getUserVote(postId, user.id);
});

