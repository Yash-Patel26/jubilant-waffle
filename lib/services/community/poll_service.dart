import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamer_flick/models/community/poll.dart';
import 'package:gamer_flick/repositories/community/poll_repository.dart';
import 'package:gamer_flick/repositories/notification/notification_repository.dart';
import 'package:gamer_flick/repositories/game/leaderboard_repository.dart';

class PollService {
  final IPollRepository _pollRepository;
  final INotificationRepository _notificationRepository;
  final ILeaderboardRepository _leaderboardRepository;

  PollService(
    this._pollRepository,
    this._notificationRepository,
    this._leaderboardRepository,
  );

  // === Poll CRUD Operations ===

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
    final poll = await _pollRepository.createPoll(
      postId: postId,
      question: question,
      options: options,
      type: type,
      duration: duration,
      allowMultipleVotes: allowMultipleVotes,
      showResultsBeforeVoting: showResultsBeforeVoting,
      isAnonymous: isAnonymous,
    );

    return poll;
  }

  Future<CommunityPoll?> getPollById(String pollId) => _pollRepository.getPollById(pollId);

  Future<CommunityPoll?> getPollByPostId(String postId) => _pollRepository.getPollByPostId(postId);

  Future<void> vote({
    required String pollId,
    required String optionId,
    required String userId,
  }) async {
    await _pollRepository.vote(pollId: pollId, optionId: optionId, userId: userId);
    await _leaderboardRepository.updateUserScore(userId);
  }

  Future<void> removeVote({
    required String pollId,
    required String optionId,
    required String userId,
  }) async {
    await _pollRepository.removeVote(pollId: pollId, optionId: optionId, userId: userId);
  }

  Future<List<PollVote>> getUserVotes(String pollId, String userId) =>
      _pollRepository.getUserVotes(pollId, userId);

  Future<bool> hasUserVoted(String pollId, String userId) =>
      _pollRepository.hasUserVoted(pollId, userId);

  Future<String?> getUserVotedOptionId(String pollId, String userId) =>
      _pollRepository.getUserVotedOptionId(pollId, userId);

  Future<void> closePoll(String pollId, String userId) =>
      _pollRepository.closePoll(pollId, userId);

  Future<void> deletePoll(String pollId) => _pollRepository.deletePoll(pollId);

  Future<Map<String, int>> getPollResults(String pollId) =>
      _pollRepository.getPollResults(pollId);

  Future<List<Map<String, dynamic>>> getOptionVoters(
    String pollId,
    String optionId, {
    int limit = 50,
  }) =>
      _pollRepository.getOptionVoters(pollId, optionId, limit: limit);

  Future<List<CommunityPoll>> getTrendingPolls({int limit = 10}) =>
      _pollRepository.getTrendingPolls(limit: limit);

  RealtimeChannel subscribeToPollUpdates(
    String pollId,
    void Function(CommunityPoll poll) onUpdate,
  ) =>
      _pollRepository.subscribeToPollUpdates(pollId, onUpdate);

  RealtimeChannel subscribeToVoteUpdates(
    String pollId,
    void Function() onVoteChange,
  ) =>
      _pollRepository.subscribeToVoteUpdates(pollId, onVoteChange);
}

final pollServiceProvider = Provider<PollService>((ref) {
  return PollService(
    ref.watch(pollRepositoryProvider),
    ref.watch(notificationRepositoryProvider),
    ref.watch(leaderboardRepositoryProvider),
  );
});
