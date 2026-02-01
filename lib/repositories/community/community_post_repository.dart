import 'package:gamer_flick/models/community/community_post.dart';
import 'package:gamer_flick/services/community/content_ranking_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gamer_flick/services/core/network_service.dart';
import 'package:gamer_flick/services/core/error_reporting_service.dart';
import 'package:gamer_flick/services/user/karma_service.dart';
import 'package:gamer_flick/services/moderation/mod_log_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class ICommunityPostRepository {
  Future<List<CommunityPost>> fetchPosts(
    String communityId, {
    SortType sortType = SortType.hot,
    TopTimeWindow topWindow = TopTimeWindow.all,
    int limit = 50,
    int offset = 0,
  });

  Future<CommunityPost?> getPostById(String id);

  Future<CommunityPost> createPost(CommunityPost post);

  Future<void> updatePost(CommunityPost post);

  Future<void> deletePost(String id);

  Future<void> votePost({
    required String postId,
    required String userId,
    required int vote,
  });

  Future<void> pinPost(String postId, {String? moderatorId, String? communityId});

  Future<void> unpinPost(String postId, {String? moderatorId, String? communityId});

  Future<void> lockPost(String postId, {String? moderatorId, String? communityId, String? reason});

  Future<void> unlockPost(String postId, {String? moderatorId, String? communityId});

  Future<void> markAsSpoiler(String postId);

  Future<void> markAsNsfw(String postId);

  Future<void> enableContestMode(String postId);

  Future<void> disableContestMode(String postId);

  Future<void> removePost(
    String postId,
    String reason, {
    String? moderatorId,
    String? communityId,
  });

  Future<void> restorePost(String postId);

  Future<List<CommunityPostComment>> fetchComments(
    String postId, {
    CommentSortType sortBy = CommentSortType.best,
    bool? contestMode,
  });

  Future<CommunityPostComment> addComment({
    required String postId,
    required String userId,
    required String content,
    String? parentCommentId,
  });

  Future<void> deleteComment(String commentId);

  Future<void> voteComment({
    required String commentId,
    required String userId,
    required int vote,
  });

  Future<Map<String, dynamic>> getPostAnalytics(String postId);
  Future<int> getUserVote(String postId, String userId);
}

class SupabaseCommunityPostRepository implements ICommunityPostRepository {
  final SupabaseClient _client;
  final NetworkService _networkService;
  final ErrorReportingService _errorReportingService;
  final ContentRankingService _rankingService = ContentRankingService();
  final KarmaService _karmaService = KarmaService();
  final ModLogService _modLogService = ModLogService();

  SupabaseCommunityPostRepository({
    SupabaseClient? client,
    NetworkService? networkService,
    ErrorReportingService? errorReportingService,
  })  : _client = client ?? Supabase.instance.client,
        _networkService = networkService ?? NetworkService(),
        _errorReportingService = errorReportingService ?? ErrorReportingService();

  static const String _table = 'community_posts';

  @override
  Future<List<CommunityPost>> fetchPosts(
    String communityId, {
    SortType sortType = SortType.hot,
    TopTimeWindow topWindow = TopTimeWindow.all,
    int limit = 50,
    int offset = 0,
  }) async {
    return _networkService.executeWithRetry(operationName: 'CommunityPostRepository.fetchPosts', operation: () async {
      return _rankingService.fetchSortedPosts(
        communityId,
        sortType: sortType,
        topWindow: topWindow,
        limit: limit,
        offset: offset,
      );
    });
  }

  @override
  Future<CommunityPost?> getPostById(String id) async {
    return _networkService.executeWithRetry(operationName: 'CommunityPostRepository.getPostById', operation: () async {
      try {
        final response = await _client
            .from(_table)
            .select('*, profiles!community_posts_author_id_fkey(*), communities(*)')
            .eq('id', id)
            .single();
        return CommunityPost.fromJson(response);
      } catch (e, stack) {
        _errorReportingService.reportError(e, stack, context: 'Failed to get community post');
        return null;
      }
    });
  }

  @override
  Future<CommunityPost> createPost(CommunityPost post) async {
    return _networkService.executeWithRetry(operationName: 'CommunityPostRepository.createPost', operation: () async {
      try {
        final response = await _client.from(_table).insert(post.toJson()).select().single();
        final newPost = CommunityPost.fromJson(response);
        
        // Update karma
        await _karmaService.onPostCreated(post.authorId);
        
        return newPost;
      } catch (e, stack) {
        _errorReportingService.reportError(e, stack, context: 'Failed to create community post');
        rethrow;
      }
    });
  }

  @override
  Future<void> updatePost(CommunityPost post) async {
    await _networkService.executeWithRetry(operationName: 'CommunityPostRepository.updatePost', operation: () async {
      try {
        await _client.from(_table).update(post.toJson()).eq('id', post.id);
      } catch (e, stack) {
        _errorReportingService.reportError(e, stack, context: 'Failed to update community post');
        rethrow;
      }
    });
  }

  @override
  Future<void> deletePost(String id) async {
    await _networkService.executeWithRetry(operationName: 'CommunityPostRepository.deletePost', operation: () async {
      try {
        await _client.from(_table).delete().eq('id', id);
      } catch (e, stack) {
        _errorReportingService.reportError(e, stack, context: 'Failed to delete community post');
        rethrow;
      }
    });
  }

  @override
  Future<void> votePost({
    required String postId,
    required String userId,
    required int vote,
  }) async {
    await _networkService.executeWithRetry(operationName: 'CommunityPostRepository.votePost', operation: () async {
      try {
        // Get post author for karma
        final post = await getPostById(postId);
        final authorId = post?.authorId;

        // Check if user already voted
        final existingVote = await _client
            .from('community_post_likes')
            .select()
            .eq('post_id', postId)
            .eq('user_id', userId)
            .maybeSingle();

        final previousVote = existingVote?['vote'] as int? ?? 0;

        if (existingVote != null) {
          await _client
              .from('community_post_likes')
              .update({'vote': vote})
              .eq('post_id', postId)
              .eq('user_id', userId);
        } else {
          await _client.from('community_post_likes').insert({
            'post_id': postId,
            'user_id': userId,
            'vote': vote,
            'created_at': DateTime.now().toIso8601String(),
          });
        }

        // Update post counts
        await _updatePostVoteCounts(postId);

        // Update karma
        if (authorId != null && authorId != userId) {
          await _karmaService.onVoteChanged(
            authorId: authorId,
            isPost: true,
            previousVote: previousVote,
            newVote: vote,
          );
        }
      } catch (e, stack) {
        _errorReportingService.reportError(e, stack, context: 'Failed to vote on post');
        rethrow;
      }
    });
  }

  Future<void> _updatePostVoteCounts(String postId) async {
    try {
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

      await _client.from(_table).update({
        'upvotes': upvotes,
        'downvotes': downvotes,
        'score': score,
        'upvote_ratio': upvoteRatio,
      }).eq('id', postId);
    } catch (e, stack) {
      _errorReportingService.reportError(
        e,
        stack,
        context: 'Error updating post vote counts',
      );
    }
  }

  @override
  Future<void> pinPost(String postId, {String? moderatorId, String? communityId}) async {
    await _networkService.executeWithRetry(operationName: 'CommunityPostRepository.pinPost', operation: () async {
      await _client.from(_table).update({'pinned': true}).eq('id', postId);
      if (moderatorId != null && communityId != null) {
        await _modLogService.logPostPin(
          communityId: communityId,
          moderatorId: moderatorId,
          postId: postId,
          pinned: true,
        );
      }
    });
  }

  @override
  Future<void> unpinPost(String postId, {String? moderatorId, String? communityId}) async {
    await _networkService.executeWithRetry(operationName: 'CommunityPostRepository.unpinPost', operation: () async {
      await _client.from(_table).update({'pinned': false}).eq('id', postId);
      if (moderatorId != null && communityId != null) {
        await _modLogService.logPostPin(
          communityId: communityId,
          moderatorId: moderatorId,
          postId: postId,
          pinned: false,
        );
      }
    });
  }

  @override
  Future<void> lockPost(String postId, {String? moderatorId, String? communityId, String? reason}) async {
    await _networkService.executeWithRetry(operationName: 'CommunityPostRepository.lockPost', operation: () async {
      await _client.from(_table).update({'locked': true}).eq('id', postId);
      if (moderatorId != null && communityId != null) {
        await _modLogService.logPostLock(
          communityId: communityId,
          moderatorId: moderatorId,
          postId: postId,
          locked: true,
          reason: reason,
        );
      }
    });
  }

  @override
  Future<void> unlockPost(String postId, {String? moderatorId, String? communityId}) async {
    await _networkService.executeWithRetry(operationName: 'CommunityPostRepository.unlockPost', operation: () async {
      await _client.from(_table).update({'locked': false}).eq('id', postId);
      if (moderatorId != null && communityId != null) {
        await _modLogService.logPostLock(
          communityId: communityId,
          moderatorId: moderatorId,
          postId: postId,
          locked: false,
        );
      }
    });
  }

  @override
  Future<void> markAsSpoiler(String postId) async {
      await _networkService.executeWithRetry(operationName: 'CommunityPostRepository.markAsSpoiler', operation: () async {
      await _client.from(_table).update({'spoiler': true}).eq('id', postId);
    });
  }

  @override
  Future<void> markAsNsfw(String postId) async {
    await _networkService.executeWithRetry(operationName: 'CommunityPostRepository.markAsNsfw', operation: () async {
      await _client.from(_table).update({'nsfw': true}).eq('id', postId);
    });
  }

  @override
  Future<void> enableContestMode(String postId) async {
    await _networkService.executeWithRetry(operationName: 'CommunityPostRepository.enableContestMode', operation: () async {
      await _client.from(_table).update({'contest_mode': true}).eq('id', postId);
    });
  }

  @override
  Future<void> disableContestMode(String postId) async {
    await _networkService.executeWithRetry(operationName: 'CommunityPostRepository.disableContestMode', operation: () async {
      await _client.from(_table).update({'contest_mode': false}).eq('id', postId);
    });
  }

  @override
  Future<void> removePost(String postId, String reason, {String? moderatorId, String? communityId}) async {
    await _networkService.executeWithRetry(operationName: 'CommunityPostRepository.removePost', operation: () async {
      Map<String, dynamic>? postData;
      if (moderatorId != null && communityId != null) {
        final post = await getPostById(postId);
        postData = post?.toJson();
      }

      await _client.from(_table).update({
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
    });
  }

  @override
  Future<void> restorePost(String postId) async {
    await _networkService.executeWithRetry(operationName: 'CommunityPostRepository.restorePost', operation: () async {
      await _client.from(_table).update({
        'removed': false,
        'removal_reason': null,
      }).eq('id', postId);
    });
  }

  @override
  Future<List<CommunityPostComment>> fetchComments(
    String postId, {
    CommentSortType sortBy = CommentSortType.best,
    bool? contestMode,
  }) async {
    return _networkService.executeWithRetry(operationName: 'CommunityPostRepository.fetchComments', operation: () async {
      final response = await _client
          .from('community_post_comments')
          .select('*, profiles(*)')
          .eq('post_id', postId)
          .order('created_at', ascending: false);

      final comments = (response as List)
          .map((data) => CommunityPostComment.fromJson(data as Map<String, dynamic>))
          .toList();

      final topLevelComments = comments.where((c) => c.parentCommentId == null).toList();

      bool useContestMode = contestMode ?? false;
      if (contestMode == null) {
        final post = await getPostById(postId);
        useContestMode = post?.contestMode ?? false;
      }

      final sortedComments = _rankingService.sortComments(
        topLevelComments,
        sortType: sortBy,
        contestMode: useContestMode,
      );

      for (final comment in sortedComments) {
        final replies = await _fetchCommentReplies(comment.id);
        comment.replies.addAll(replies);
      }

      return sortedComments;
    });
  }

  Future<List<CommunityPostComment>> _fetchCommentReplies(String parentCommentId) async {
    final response = await _client
        .from('community_post_comments')
        .select('*, profiles(*)')
        .eq('parent_comment_id', parentCommentId)
        .order('score', ascending: false);

    return (response as List)
        .map((data) => CommunityPostComment.fromJson(data as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<CommunityPostComment> addComment({
    required String postId,
    required String userId,
    required String content,
    String? parentCommentId,
  }) async {
    return _networkService.executeWithRetry(operationName: 'CommunityPostRepository.addComment', operation: () async {
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

        await _client.rpc('increment_post_comment_count', params: {'post_id': postId});
        
        // Update karma
        await _karmaService.onCommentCreated(userId);

        return CommunityPostComment.fromJson(response);
      } catch (e, stack) {
        _errorReportingService.reportError(e, stack, context: 'Failed to add comment');
        rethrow;
      }
    });
  }

  @override
  Future<void> deleteComment(String commentId) async {
    await _networkService.executeWithRetry(operationName: 'CommunityPostRepository.deleteComment', operation: () async {
      try {
        await _client.from('community_post_comments').delete().eq('id', commentId);
      } catch (e, stack) {
        _errorReportingService.reportError(e, stack, context: 'Failed to delete comment');
        rethrow;
      }
    });
  }

  @override
  Future<void> voteComment({
    required String commentId,
    required String userId,
    required int vote,
  }) async {
    await _networkService.executeWithRetry(operationName: 'CommunityPostRepository.voteComment', operation: () async {
      try {
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
            .eq('user_id', userId)
            .maybeSingle();

        final previousVote = existingVote?['vote'] as int? ?? 0;

        if (existingVote != null) {
          await _client
              .from('comment_likes')
              .update({'vote': vote})
              .eq('comment_id', commentId)
              .eq('user_id', userId);
        } else {
          await _client.from('comment_likes').insert({
            'comment_id': commentId,
            'user_id': userId,
            'vote': vote,
            'created_at': DateTime.now().toIso8601String(),
          });
        }

        await _updateCommentVoteCounts(commentId);

        if (authorId != null && authorId != userId) {
          await _karmaService.onVoteChanged(
            authorId: authorId,
            isPost: false,
            previousVote: previousVote,
            newVote: vote,
          );
        }
      } catch (e, stack) {
        _errorReportingService.reportError(e, stack, context: 'Failed to vote on comment');
        rethrow;
      }
    });
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

      await _client.from('community_post_comments').update({
        'upvotes': upvotes,
        'downvotes': downvotes,
        'score': upvotes - downvotes,
      }).eq('id', commentId);
    } catch (e, stack) {
      _errorReportingService.reportError(
        e,
        stack,
        context: 'Error updating comment vote counts',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getPostAnalytics(String postId) async {
    try {
      final viewsResponse = await _client
          .from('post_views')
          .select('id')
          .eq('post_id', postId)
          .count(CountOption.exact);
      final sharesResponse = await _client
          .from('post_shares')
          .select('id')
          .eq('post_id', postId)
          .count(CountOption.exact);

      return {
        'view_count': viewsResponse.count,
        'share_count': sharesResponse.count,
        'engagement_rate': 0.0,
      };
    } catch (e) {
      return {'view_count': 0, 'share_count': 0, 'engagement_rate': 0.0};
    }
  }

  @override
  Future<int> getUserVote(String postId, String userId) async {
    return _networkService.executeWithRetry(operationName: 'CommunityPostRepository.getUserVote', operation: () async {
      final response = await _client
          .from('community_post_likes')
          .select('vote')
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();

      return response?['vote'] as int? ?? 0;
    });
  }
}

final communityPostRepositoryProvider = Provider<ICommunityPostRepository>((ref) {
  return SupabaseCommunityPostRepository();
});
