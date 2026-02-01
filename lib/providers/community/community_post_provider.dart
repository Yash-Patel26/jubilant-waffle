import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gamer_flick/services/community/community_post_service.dart';
import 'package:gamer_flick/models/community/community_post.dart';

class CommunityPostProvider extends ChangeNotifier {
  final CommunityPostService _postService = CommunityPostService();

  List<CommunityPost> _posts = [];
  bool _isLoading = false;
  String? _error;

  final Map<String, int> _likeCounts = {};
  final Map<String, bool> _likedByUser = {};
  final Map<String, int> _userVotes = {}; // Track user's vote (-1, 0, 1)

  final Map<String, List<CommunityPostComment>> _comments = {};
  final Map<String, bool> _commentsLoading = {};
  final Map<String, String?> _commentsError = {};

  List<CommunityPost> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Map<String, int> get likeCounts => _likeCounts;
  Map<String, bool> get likedByUser => _likedByUser;
  Map<String, int> get userVotes => _userVotes;

  List<CommunityPostComment> getComments(String postId) =>
      _comments[postId] ?? [];
  bool isCommentsLoading(String postId) => _commentsLoading[postId] ?? false;
  String? getCommentsError(String postId) => _commentsError[postId];

  Future<void> loadPosts(String communityId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _posts = await _postService.fetchPosts(communityId);
      // Sort: pinned posts first, then by createdAt descending
      _posts.sort((a, b) {
        if (a.pinned && !b.pinned) return -1;
        if (!a.pinned && b.pinned) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });
      await loadVotesForPosts();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> createPost(CommunityPost post, String communityId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final newPost = await _postService.createPost(post);
      _posts.insert(0, newPost);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow; // Re-throw to allow calling code to handle the error
    }
  }

  Future<void> updatePost(CommunityPost post, String communityId) async {
    try {
      await _postService.updatePost(post);
      await loadPosts(communityId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deletePost(String postId, String communityId) async {
    try {
      await _postService.deletePost(postId);
      _posts = _posts.where((p) => p.id != postId).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadVotesForPosts() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    for (final post in _posts) {
      // Get like count (upvotes only for backward compatibility)
      _likeCounts[post.id] = await _postService.getLikeCount(post.id);

      // Get user's vote
      final userVote = await _postService.getUserVote(post.id, user.id);
      _userVotes[post.id] = userVote;

      // Set likedByUser based on vote (1 = liked, 0 or -1 = not liked)
      _likedByUser[post.id] = userVote == 1;
    }
    notifyListeners();
  }

  Future<void> votePost(String postId, int vote) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await _postService.votePost(postId, user.id, vote);

      // Update local state
      _userVotes[postId] = vote;
      _likedByUser[postId] = vote == 1;

      // Update like count (only count upvotes for backward compatibility)
      if (vote == 1) {
        _likeCounts[postId] = (_likeCounts[postId] ?? 0) + 1;
      } else if (vote == 0 && _userVotes[postId] == 1) {
        // User removed their upvote
        _likeCounts[postId] = (_likeCounts[postId] ?? 1) - 1;
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Backward compatibility methods
  Future<void> likePost(String postId) async {
    await votePost(postId, 1);
  }

  Future<void> unlikePost(String postId) async {
    await votePost(postId, 0);
  }

  Future<void> downvotePost(String postId) async {
    await votePost(postId, -1);
  }

  Future<void> fetchComments(String postId) async {
    _commentsLoading[postId] = true;
    _commentsError[postId] = null;
    notifyListeners();
    try {
      final comments = await _postService.fetchComments(postId);
      _comments[postId] = comments;
    } catch (e) {
      _commentsError[postId] = e.toString();
    }
    _commentsLoading[postId] = false;
    notifyListeners();
  }

  Future<void> addComment(String postId, String content) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final comment = await _postService.addComment(
        postId: postId,
        userId: user.id,
        content: content,
      );
      _comments[postId] = [...(_comments[postId] ?? []), comment];
      notifyListeners();
    } catch (e) {
      _commentsError[postId] = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteComment(String postId, String commentId) async {
    try {
      await _postService.deleteComment(commentId);
      _comments[postId] =
          (_comments[postId] ?? []).where((c) => c.id != commentId).toList();
      notifyListeners();
    } catch (e) {
      _commentsError[postId] = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
