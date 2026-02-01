import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:gamer_flick/models/community/poll.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class IPollRepository {
  Future<CommunityPoll?> createPoll({
    required String postId,
    required String question,
    required List<String> options,
    PollType type = PollType.singleChoice,
    Duration? duration,
    bool allowMultipleVotes = false,
    bool showResultsBeforeVoting = false,
    bool isAnonymous = false,
  });
  Future<CommunityPoll?> getPollById(String pollId);
  Future<CommunityPoll?> getPollByPostId(String postId);
  Future<void> vote({
    required String pollId,
    required String optionId,
    required String userId,
  });
  Future<void> removeVote({
    required String pollId,
    required String optionId,
    required String userId,
  });
  Future<List<PollVote>> getUserVotes(String pollId, String userId);
  Future<bool> hasUserVoted(String pollId, String userId);
  Future<String?> getUserVotedOptionId(String pollId, String userId);
  Future<void> closePoll(String pollId, String userId);
  Future<void> deletePoll(String pollId);
  Future<Map<String, int>> getPollResults(String pollId);
  Future<List<Map<String, dynamic>>> getOptionVoters(
    String pollId,
    String optionId, {
    int limit = 50,
  });
  Future<List<CommunityPoll>> getTrendingPolls({int limit = 10});
  RealtimeChannel subscribeToPollUpdates(
    String pollId,
    void Function(CommunityPoll poll) onUpdate,
  );
  RealtimeChannel subscribeToVoteUpdates(
    String pollId,
    void Function() onVoteChange,
  );
}

class SupabasePollRepository implements IPollRepository {
  final SupabaseClient _client = Supabase.instance.client;
  final _uuid = const Uuid();

  @override
  Future<CommunityPoll?> createPoll({
    required String postId,
    required String question,
    required List<String> options,
    PollType type = PollType.singleChoice,
    Duration? duration,
    bool allowMultipleVotes = false,
    bool showResultsBeforeVoting = false,
    bool isAnonymous = false,
  }) async {
    try {
      final pollId = _uuid.v4();
      final now = DateTime.now();
      final expiresAt = duration != null ? now.add(duration) : null;

      final pollOptions = options.asMap().entries.map((entry) {
        return PollOption(
          id: _uuid.v4(),
          text: entry.value,
          voteCount: 0,
          position: entry.key,
        );
      }).toList();

      await _client.from('community_polls').insert({
        'id': pollId,
        'post_id': postId,
        'question': question,
        'type': type.name,
        'created_at': now.toIso8601String(),
        'expires_at': expiresAt?.toIso8601String(),
        'allow_multiple_votes': allowMultipleVotes,
        'show_results_before_voting': showResultsBeforeVoting,
        'is_anonymous': isAnonymous,
        'total_votes': 0,
        'is_closed': false,
      });

      for (final option in pollOptions) {
        await _client.from('poll_options').insert({
          'id': option.id,
          'poll_id': pollId,
          'text': option.text,
          'vote_count': 0,
          'position': option.position,
        });
      }

      await _client.from('community_posts').update({
        'post_type': 'poll',
        'poll_data': {
          'poll_id': pollId,
          'question': question,
          'option_count': options.length,
        },
      }).eq('id', postId);

      return CommunityPoll(
        id: pollId,
        postId: postId,
        question: question,
        options: pollOptions,
        type: type,
        createdAt: now,
        expiresAt: expiresAt,
        allowMultipleVotes: allowMultipleVotes,
        showResultsBeforeVoting: showResultsBeforeVoting,
        isAnonymous: isAnonymous,
        totalVotes: 0,
        isClosed: false,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<CommunityPoll?> getPollById(String pollId) async {
    try {
      final response = await _client
          .from('community_polls')
          .select('*, poll_options(*)')
          .eq('id', pollId)
          .single();

      return CommunityPoll.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<CommunityPoll?> getPollByPostId(String postId) async {
    try {
      final response = await _client
          .from('community_polls')
          .select('*, poll_options(*)')
          .eq('post_id', postId)
          .single();

      return CommunityPoll.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> vote({
    required String pollId,
    required String optionId,
    required String userId,
  }) async {
    try {
      await _client.from('poll_votes').insert({
        'id': _uuid.v4(),
        'poll_id': pollId,
        'option_id': optionId,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      });
      await _incrementOptionVoteCount(optionId);
      await _updatePollTotalVotes(pollId);
    } catch (e) {}
  }

  @override
  Future<void> removeVote({
    required String pollId,
    required String optionId,
    required String userId,
  }) async {
    try {
      final response = await _client
          .from('poll_votes')
          .select('id')
          .eq('poll_id', pollId)
          .eq('option_id', optionId)
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        final voteId = response['id'] as String;
        await _client.from('poll_votes').delete().eq('id', voteId);
        await _decrementOptionVoteCount(optionId);
        await _updatePollTotalVotes(pollId);
      }
    } catch (e) {}
  }

  Future<void> _incrementOptionVoteCount(String optionId) async {
    try {
      await _client.rpc('increment_poll_option_vote', params: {'option_uuid': optionId});
    } catch (e) {
      final currentResponse = await _client.from('poll_options').select('vote_count').eq('id', optionId).single();
      final currentCount = (currentResponse['vote_count'] ?? 0) as int;
      await _client.from('poll_options').update({'vote_count': currentCount + 1}).eq('id', optionId);
    }
  }

  Future<void> _decrementOptionVoteCount(String optionId) async {
    try {
      await _client.rpc('decrement_poll_option_vote', params: {'option_uuid': optionId});
    } catch (e) {
      final currentResponse = await _client.from('poll_options').select('vote_count').eq('id', optionId).single();
      final currentCount = (currentResponse['vote_count'] ?? 0) as int;
      await _client.from('poll_options').update({'vote_count': currentCount > 0 ? currentCount - 1 : 0}).eq('id', optionId);
    }
  }

  Future<void> _updatePollTotalVotes(String pollId) async {
    try {
      final response = await _client.from('poll_options').select('vote_count').eq('poll_id', pollId);
      int total = 0;
      for (final option in response as List) {
        total += (option['vote_count'] ?? 0) as int;
      }
      await _client.from('community_polls').update({'total_votes': total}).eq('id', pollId);
    } catch (e) {}
  }

  @override
  Future<List<PollVote>> getUserVotes(String pollId, String userId) async {
    try {
      final response = await _client.from('poll_votes').select('*').eq('poll_id', pollId).eq('user_id', userId);
      return (response as List).map((e) => PollVote.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<bool> hasUserVoted(String pollId, String userId) async {
    final votes = await getUserVotes(pollId, userId);
    return votes.isNotEmpty;
  }

  @override
  Future<String?> getUserVotedOptionId(String pollId, String userId) async {
    final votes = await getUserVotes(pollId, userId);
    return votes.firstOrNull?.optionId;
  }

  @override
  Future<void> closePoll(String pollId, String userId) async {
    try {
      await _client.from('community_polls').update({'is_closed': true}).eq('id', pollId);
    } catch (e) {}
  }

  @override
  Future<void> deletePoll(String pollId) async {
    try {
      await _client.from('community_polls').delete().eq('id', pollId);
    } catch (e) {}
  }

  @override
  Future<Map<String, int>> getPollResults(String pollId) async {
    try {
      final response = await _client.from('poll_options').select('id, vote_count').eq('poll_id', pollId);
      final results = <String, int>{};
      for (final option in response as List) {
        results[option['id'] as String] = (option['vote_count'] ?? 0) as int;
      }
      return results;
    } catch (e) {
      return {};
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getOptionVoters(String pollId, String optionId, {int limit = 50}) async {
    try {
      final response = await _client
          .from('poll_votes')
          .select('*, profiles(username, avatar_url)')
          .eq('poll_id', pollId)
          .eq('option_id', optionId)
          .limit(limit);
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<CommunityPoll>> getTrendingPolls({int limit = 10}) async {
    try {
      final response = await _client
          .from('community_polls')
          .select('*, poll_options(*)')
          .eq('is_closed', false)
          .order('total_votes', ascending: false)
          .limit(limit);
      return (response as List).map((e) => CommunityPoll.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  RealtimeChannel subscribeToPollUpdates(String pollId, void Function(CommunityPoll poll) onUpdate) {
    return _client
        .channel('poll_updates_$pollId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'community_polls',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'id', value: pollId),
          callback: (payload) async {
            final poll = await getPollById(pollId);
            if (poll != null) onUpdate(poll);
          },
        )
        .subscribe();
  }

  @override
  RealtimeChannel subscribeToVoteUpdates(String pollId, void Function() onVoteChange) {
    return _client
        .channel('vote_updates_$pollId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'poll_votes',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'poll_id', value: pollId),
          callback: (payload) => onVoteChange(),
        )
        .subscribe();
  }
}

final pollRepositoryProvider = Provider<IPollRepository>((ref) {
  return SupabasePollRepository();
});
