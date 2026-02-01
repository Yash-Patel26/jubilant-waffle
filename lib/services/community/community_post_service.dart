import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gamer_flick/models/community/community_post.dart';
import 'package:gamer_flick/services/community/content_ranking_service.dart';
import 'package:gamer_flick/services/user/karma_service.dart';
import 'package:gamer_flick/services/moderation/mod_log_service.dart';

class CommunityPostService {
  final SupabaseClient _client = Supabase.instance.client;
  final ContentRankingService _rankingService = ContentRankingService();
  final KarmaService _karmaService = KarmaService();
  final ModLogService _modLogService = ModLogService();
  final String table = 'community_posts';

  Future<List<CommunityPost>> fetchPosts(String communityId,
      {String sortBy = 'hot', TopTimeWindow topWindow = TopTimeWindow.all}) async {
    // Use the enhanced ranking service for proper algorithms
    final sortType = _parseSortType(sortBy);
    return _rankingService.fetchSortedPosts(
      communityId,
      sortType: sortType,
      topWindow: topWindow,
    );
  }

  /// Legacy method for backward compatibility
  Future<List<CommunityPost>> fetchPostsLegacy(String communityId,
      {String sortBy = 'hot'}) async {
    final response = await _client
        .from(table)
        .select('*, profiles!community_posts_author_id_fkey(*), communities(*)')
        .eq('community_id', communityId)
        .order('created_at', ascending: false);

    final posts = (response as List)
        .map((data) => CommunityPost.fromJson(data as Map<String, dynamic>))
        .toList();

    // Use enhanced ranking algorithms
    final sortType = _parseSortType(sortBy);
    return _rankingService.sortPosts(posts, sortType);
  }

  SortType _parseSortType(String sortBy) {
    return switch (sortBy) {
      'hot' => SortType.hot,
      'new' => SortType.newPosts,
      'top' => SortType.top,
      'rising' => SortType.rising,
      'controversial' => SortType.controversial,
      'best' => SortType.best,
      _ => SortType.hot,
    };
  }

  Future<CommunityPost?> getPostById(String id) async {
    final response = await _client
        .from(table)
        .select('*, profiles!community_posts_author_id_fkey(*), communities(*)')
        .eq('id', id)
        .single();
    return CommunityPost.fromJson(response);
  }

  Future<CommunityPost> createPost(CommunityPost post) async {
    try {
      final response =
          await _client.from(table).insert(post.toJson()).select().single();
      return CommunityPost.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create community post: ${e.toString()}');
    }
  }

  Future<void> updatePost(CommunityPost post) async {
    await _client.from(table).update(post.toJson()).eq('id', post.id);
  }

  Future<void> deletePost(String id) async {
    await _client.from(table).delete().eq('id', id);
  }

  // Reddit-style voting system with karma tracking
  Future<void> votePost(String postId, String oderId, int vote) async {
    try {
      // Get post author for karma
      final post = await getPostById(postId);
      final authorId = post?.authorId;

      // Check if user already voted
      final existingVote = await _client
          .from('community_post_likes')
          .select()
          .eq('post_id', postId)
          .eq('user_id', oderId)
          .maybeSingle();

      final previousVote = existingVote?['vote'] as int? ?? 0;

      if (existingVote != null) {
        // Update existing vote
        await _client
            .from('community_post_likes')
            .update({'vote': vote})
            .eq('post_id', postId)
            .eq('user_id', oderId);
      } else {
        // Create new vote
        await _client.from('community_post_likes').insert({
          'post_id': postId,
          'user_id': oderId,
          'vote': vote,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // Update post score and vote counts
      await _updatePostVoteCounts(postId);

      // Update author's karma
      if (authorId != null && authorId != oderId) {
        await _karmaService.onVoteChanged(
          authorId: authorId,
          isPost: true,
          previousVote: previousVote,
          newVote: vote,
        );
      }
    } catch (e) {
      throw Exception('Failed to vote on post: ${e.toString()}');
    }
  }

  Future<void> _updatePostVoteCounts(String postId) async {
    try {
      // Get all votes for this post
      final votes = await _client
          .from('community_post_likes')
          .select('vote')
          .eq('post_id', postId);

      int upvotes = 0;
      int downvotes = 0;

      for (final vote in votes as List) {
        final voteValue = vote['vote'] as int;
        if (voteValue == 1) {
          upvotes++;
        } else if (voteValue == -1) {
          downvotes++;
        }
      }

      final score = upvotes - downvotes;
      final totalVotes = upvotes + downvotes;
      final upvoteRatio = totalVotes > 0 ? upvotes / totalVotes : 1.0;

      // Update post with new vote counts
      await _client.from(table).update({
        'upvotes': upvotes,
        'downvotes': downvotes,
        'score': score,
        'upvote_ratio': upvoteRatio,
      }).eq('id', postId);
    } catch (e) {
      print('Error updating post vote counts: $e');
    }
  }

  Future<int> getLikeCount(String postId) async {
    final response = await _client
        .from('community_post_likes')
        .select('id')
        .eq('post_id', postId)
        .eq('vote', 1);
    return (response as List).length;
  }

  Future<bool> isPostLikedByUser(String postId, String userId) async {
    final response = await _client
        .from('community_post_likes')
        .select('vote')
        .eq('post_id', postId)
        .eq('user_id', userId)
        .maybeSingle();

    return response != null && response['vote'] == 1;
  }

  Future<int> getUserVote(String postId, String userId) async {
    final response = await _client
        .from('community_post_likes')
        .select('vote')
        .eq('post_id', postId)
        .eq('user_id', userId)
        .maybeSingle();

    return response?['vote'] as int? ?? 0;
  }

  // Reddit-style post management with mod logging
  Future<void> pinPost(String postId, {String? moderatorId, String? communityId}) async {
    await _client.from(table).update({'pinned': true}).eq('id', postId);
    if (moderatorId != null && communityId != null) {
      await _modLogService.logPostPin(
        communityId: communityId,
        moderatorId: moderatorId,
        postId: postId,
        pinned: true,
      );
    }
  }

  Future<void> unpinPost(String postId, {String? moderatorId, String? communityId}) async {
    await _client.from(table).update({'pinned': false}).eq('id', postId);
    if (moderatorId != null && communityId != null) {
      await _modLogService.logPostPin(
        communityId: communityId,
        moderatorId: moderatorId,
        postId: postId,
        pinned: false,
      );
    }
  }

  Future<void> lockPost(String postId, {String? moderatorId, String? communityId, String? reason}) async {
    await _client.from(table).update({'locked': true}).eq('id', postId);
    if (moderatorId != null && communityId != null) {
      await _modLogService.logPostLock(
        communityId: communityId,
        moderatorId: moderatorId,
        postId: postId,
        locked: true,
        reason: reason,
      );
    }
  }

  Future<void> unlockPost(String postId, {String? moderatorId, String? communityId}) async {
    await _client.from(table).update({'locked': false}).eq('id', postId);
    if (moderatorId != null && communityId != null) {
      await _modLogService.logPostLock(
        communityId: communityId,
        moderatorId: moderatorId,
        postId: postId,
        locked: false,
      );
    }
  }

  Future<void> markAsSpoiler(String postId) async {
    await _client.from(table).update({'spoiler': true}).eq('id', postId);
  }

  Future<void> markAsNsfw(String postId) async {
    await _client.from(table).update({'nsfw': true}).eq('id', postId);
  }

  Future<void> enableContestMode(String postId) async {
    await _client.from(table).update({'contest_mode': true}).eq('id', postId);
  }

  Future<void> disableContestMode(String postId) async {
    await _client.from(table).update({'contest_mode': false}).eq('id', postId);
  }

  Future<void> removePost(String postId, String reason, {String? moderatorId, String? communityId}) async {
    // Get post data before removal for mod log
    Map<String, dynamic>? postData;
    if (moderatorId != null && communityId != null) {
      final post = await getPostById(postId);
      postData = post?.toJson();
    }

    await _client.from(table).update({
      'removed': true,
      'removal_reason': reason,
    }).eq('id', postId);

    if (moderatorId != null && communityId != null) {
      await _modLogService.logPostRemoval(
        communityId: communityId,
        moderatorId: moderatorId,
        postId: postId,
        reason: reason,
        postData: postData,
      );
    }
  }

  Future<void> restorePost(String postId) async {
    await _client.from(table).update({
      'removed': false,
      'removal_reason': null,
    }).eq('id', postId);
  }

  // Reddit-style comment system with contest mode support
  Future<List<CommunityPostComment>> fetchComments(String postId,
      {String sortBy = 'best', bool? contestMode}) async {
    final response = await _client
        .from('community_post_comments')
        .select('*, profiles(*)')
        .eq('post_id', postId)
        .order('created_at', ascending: false);

    final comments = (response as List)
        .map((data) =>
            CommunityPostComment.fromJson(data as Map<String, dynamic>))
        .toList();

    // Filter top-level comments
    final topLevelComments =
        comments.where((c) => c.parentCommentId == null).toList();

    // Check if contest mode is enabled for this post
    bool useContestMode = contestMode ?? false;
    if (contestMode == null) {
      final post = await getPostById(postId);
      useContestMode = post?.contestMode ?? false;
    }

    // Use enhanced ranking service for proper sorting
    final commentSortType = _parseCommentSortType(sortBy);
    final sortedComments = _rankingService.sortComments(
      topLevelComments,
      sortType: commentSortType,
      contestMode: useContestMode,
    );

    // Fetch replies for each comment
    for (final comment in sortedComments) {
      final replies = await _fetchCommentReplies(comment.id);
      comment.replies.addAll(replies);
    }

    return sortedComments;
  }

  CommentSortType _parseCommentSortType(String sortBy) {
    return switch (sortBy) {
      'best' => CommentSortType.best,
      'top' => CommentSortType.top,
      'new' => CommentSortType.newComments,
      'controversial' => CommentSortType.controversial,
      'old' => CommentSortType.old,
      'qa' => CommentSortType.qa,
      _ => CommentSortType.best,
    };
  }

  Future<List<CommunityPostComment>> _fetchCommentReplies(
      String parentCommentId) async {
    final response = await _client
        .from('community_post_comments')
        .select('*, profiles(*)')
        .eq('parent_comment_id', parentCommentId)
        .order('score', ascending: false);

    return (response as List)
        .map((data) =>
            CommunityPostComment.fromJson(data as Map<String, dynamic>))
        .toList();
  }

  Future<CommunityPostComment> addComment({
    required String postId,
    required String userId,
    required String content,
    String? parentCommentId,
  }) async {
    try {
      final response = await _client
          .from('community_post_comments')
          .insert({
            'post_id': postId,
            'user_id': userId,
            'content': content,
            'parent_comment_id': parentCommentId,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select('*, profiles(*)')
          .single();

      // Update post comment count
      await _incrementCommentCount(postId);

      return CommunityPostComment.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add comment: ${e.toString()}');
    }
  }

  Future<void> _incrementCommentCount(String postId) async {
    await _client.rpc('increment_post_comment_count', params: {
      'post_id': postId,
    });
  }

  Future<void> deleteComment(String commentId) async {
    await _client.from('community_post_comments').delete().eq('id', commentId);
  }

  // Reddit-style comment voting with karma tracking
  Future<void> voteComment(String commentId, String oderId, int vote) async {
    try {
      // Get comment author for karma
      final commentResponse = await _client
          .from('community_post_comments')
          .select('user_id')
          .eq('id', commentId)
          .maybeSingle();
      final authorId = commentResponse?['user_id'] as String?;

      final existingVote = await _client
          .from('comment_likes')
          .select()
          .eq('comment_id', commentId)
          .eq('user_id', oderId)
          .maybeSingle();

      final previousVote = existingVote?['vote'] as int? ?? 0;

      if (existingVote != null) {
        await _client
            .from('comment_likes')
            .update({'vote': vote})
            .eq('comment_id', commentId)
            .eq('user_id', oderId);
      } else {
        await _client.from('comment_likes').insert({
          'comment_id': commentId,
          'user_id': oderId,
          'vote': vote,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      await _updateCommentVoteCounts(commentId);

      // Update author's karma
      if (authorId != null && authorId != oderId) {
        await _karmaService.onVoteChanged(
          authorId: authorId,
          isPost: false,
          previousVote: previousVote,
          newVote: vote,
        );
      }
    } catch (e) {
      throw Exception('Failed to vote on comment: ${e.toString()}');
    }
  }

  Future<void> _updateCommentVoteCounts(String commentId) async {
    try {
      final votes = await _client
          .from('comment_likes')
          .select('vote')
          .eq('comment_id', commentId);

      int upvotes = 0;
      int downvotes = 0;

      for (final vote in votes as List) {
        final voteValue = vote['vote'] as int;
        if (voteValue == 1) {
          upvotes++;
        } else if (voteValue == -1) {
          downvotes++;
        }
      }

      final score = upvotes - downvotes;

      await _client.from('community_post_comments').update({
        'upvotes': upvotes,
        'downvotes': downvotes,
        'score': score,
      }).eq('id', commentId);
    } catch (e) {
      print('Error updating comment vote counts: $e');
    }
  }

  // Reddit-style post analytics
  Future<Map<String, dynamic>> getPostAnalytics(String postId) async {
    try {
      final views =
          await _client.from('post_views').select('id').eq('post_id', postId);

      final shares =
          await _client.from('post_shares').select('id').eq('post_id', postId);

      return {
        'view_count': (views as List).length,
        'share_count': (shares as List).length,
        'engagement_rate': 0.0, // TODO: Calculate engagement rate
      };
    } catch (e) {
      return {
        'view_count': 0,
        'share_count': 0,
        'engagement_rate': 0.0,
      };
    }
  }
}
