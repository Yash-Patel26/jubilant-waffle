import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gamer_flick/models/tournament/tournament.dart';
import 'package:gamer_flick/models/tournament/tournament_match.dart';
import 'package:gamer_flick/models/tournament/tournament_participant.dart';
import 'package:gamer_flick/models/tournament/tournament_bracket.dart';
import 'package:gamer_flick/utils/error_handler.dart';

class EnhancedTournamentService {
  static final EnhancedTournamentService _instance =
      EnhancedTournamentService._internal();
  factory EnhancedTournamentService() => _instance;
  EnhancedTournamentService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  /// Create tournament with automated bracket generation
  Future<Tournament> createTournament({
    required String name,
    required String description,
    required String gameCategory,
    required int maxParticipants,
    required double prizePool,
    required DateTime startDate,
    required DateTime endDate,
    required double entryFee,
    required String createdBy,
    String? tournamentType,
    Map<String, dynamic>? settings,
  }) async {
    try {
      // Create tournament
      final tournamentData = {
        'name': name,
        'description': description,
        'game_category': gameCategory,
        'max_participants': maxParticipants,
        'current_participants': 0,
        'prize_pool': prizePool,
        'start_date': startDate.toUtc().toIso8601String(),
        'end_date': endDate.toUtc().toIso8601String(),
        'entry_fee': entryFee,
        'created_by': createdBy,
        'status': 'registration',
        'tournament_type': tournamentType ?? 'single_elimination',
        'settings': settings ?? {},
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };

      final response = await _client
          .from('tournaments')
          .insert(tournamentData)
          .select()
          .single();

      final tournament = Tournament.fromMap(response);

      // Create tournament roles
      await _createTournamentRoles(tournament.id, createdBy);

      // Initialize bracket structure
      await _initializeBracket(tournament.id, maxParticipants);

      return tournament;
    } catch (e) {
      ErrorHandler.logError('Failed to create tournament', e);
      rethrow;
    }
  }

  /// Create tournament roles
  Future<void> _createTournamentRoles(
      String tournamentId, String ownerId) async {
    try {
      await _client.from('tournament_roles').insert([
        {
          'tournament_id': tournamentId,
          'user_id': ownerId,
          'role': 'owner',
          'created_at': DateTime.now().toUtc().toIso8601String(),
        },
        {
          'tournament_id': tournamentId,
          'user_id': ownerId,
          'role': 'admin',
          'created_at': DateTime.now().toUtc().toIso8601String(),
        },
      ]);
    } catch (e) {
      ErrorHandler.logError('Failed to create tournament roles', e);
    }
  }

  /// Initialize bracket structure
  Future<void> _initializeBracket(
      String tournamentId, int maxParticipants) async {
    try {
      final rounds = _calculateRounds(maxParticipants);
      final bracketData = {
        'tournament_id': tournamentId,
        'total_rounds': rounds,
        'current_round': 1,
        'status': 'pending',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };

      await _client.from('tournament_brackets').insert(bracketData);
    } catch (e) {
      ErrorHandler.logError('Failed to initialize bracket', e);
    }
  }

  /// Calculate number of rounds needed
  int _calculateRounds(int participants) {
    int rounds = 1;
    int currentParticipants = participants;
    while (currentParticipants > 2) {
      currentParticipants = (currentParticipants / 2).ceil();
      rounds++;
    }
    return rounds;
  }

  /// Join tournament
  Future<void> joinTournament({
    required String tournamentId,
    required String userId,
    String? teamId,
  }) async {
    try {
      // Check if tournament is open for registration
      final tournament = await _client
          .from('tournaments')
          .select('status, current_participants, max_participants')
          .eq('id', tournamentId)
          .single();

      if (tournament['status'] != 'registration') {
        throw Exception('Tournament is not open for registration');
      }

      if (tournament['current_participants'] >=
          tournament['max_participants']) {
        throw Exception('Tournament is full');
      }

      // Check if user is already a participant
      final existingParticipant = await _client
          .from('tournament_participants')
          .select('id')
          .eq('tournament_id', tournamentId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingParticipant != null) {
        throw Exception('User is already a participant');
      }

      // Add participant
      await _client.from('tournament_participants').insert({
        'tournament_id': tournamentId,
        'user_id': userId,
        'team_id': teamId,
        'joined_at': DateTime.now().toUtc().toIso8601String(),
        'status': 'active',
      });

      // Update participant count
      await _client.rpc('increment_tournament_participants', params: {
        'tournament_id': tournamentId,
      });

      // Check if tournament is full and start if needed
      await _checkAndStartTournament(tournamentId);
    } catch (e) {
      ErrorHandler.logError('Failed to join tournament', e);
      rethrow;
    }
  }

  /// Leave tournament
  Future<void> leaveTournament({
    required String tournamentId,
    required String userId,
  }) async {
    try {
      // Check if tournament hasn't started
      final tournament = await _client
          .from('tournaments')
          .select('status')
          .eq('id', tournamentId)
          .single();

      if (tournament['status'] != 'registration') {
        throw Exception('Cannot leave tournament after it has started');
      }

      // Remove participant
      await _client
          .from('tournament_participants')
          .delete()
          .eq('tournament_id', tournamentId)
          .eq('user_id', userId);

      // Update participant count
      await _client.rpc('decrement_tournament_participants', params: {
        'tournament_id': tournamentId,
      });
    } catch (e) {
      ErrorHandler.logError('Failed to leave tournament', e);
      rethrow;
    }
  }

  /// Check and start tournament if full
  Future<void> _checkAndStartTournament(String tournamentId) async {
    try {
      final tournament = await _client
          .from('tournaments')
          .select('current_participants, max_participants')
          .eq('id', tournamentId)
          .single();

      if (tournament['current_participants'] >=
          tournament['max_participants']) {
        await _startTournament(tournamentId);
      }
    } catch (e) {
      ErrorHandler.logError('Failed to check and start tournament', e);
    }
  }

  /// Start tournament and generate matches
  Future<void> _startTournament(String tournamentId) async {
    try {
      // Update tournament status
      await _client.from('tournaments').update({
        'status': 'ongoing',
        'started_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', tournamentId);

      // Get participants with their ranks/XP for seeding
      final participants = await _client
          .from('tournament_participants')
          .select('''
            user_id,
            profiles!tournament_participants_user_id_fkey(
              rank,
              xp
            )
          ''')
          .eq('tournament_id', tournamentId)
          .eq('status', 'active');

      final List<Map<String, dynamic>> participantData = 
          List<Map<String, dynamic>>.from(participants);

      // Sort by rank (descending) or XP if rank is equal
      participantData.sort((a, b) {
        final rankA = (a['profiles']['rank'] ?? 0) as int;
        final rankB = (b['profiles']['rank'] ?? 0) as int;
        if (rankA != rankB) return rankB.compareTo(rankA);
        
        final xpA = (a['profiles']['xp'] ?? 0) as int;
        final xpB = (b['profiles']['xp'] ?? 0) as int;
        return xpB.compareTo(xpA);
      });

      final participantIds =
          participantData.map((p) => p['user_id'] as String).toList();

      // Generate first round matches with seeding (Top vs Bottom, etc.)
      await _generateFirstRoundMatches(tournamentId, participantIds);

      // Update bracket status
      await _client.from('tournament_brackets').update({
        'status': 'active',
        'current_round': 1,
      }).eq('tournament_id', tournamentId);
    } catch (e) {
      ErrorHandler.logError('Failed to start tournament', e);
    }
  }

  /// Generate first round matches
  Future<void> _generateFirstRoundMatches(
      String tournamentId, List<String> participants) async {
    try {
      // Shuffle participants for random seeding
      participants.shuffle();

      // Create matches
      for (int i = 0; i < participants.length; i += 2) {
        if (i + 1 < participants.length) {
          await _createMatch(
            tournamentId: tournamentId,
            round: 1,
            player1Id: participants[i],
            player2Id: participants[i + 1],
            matchNumber: (i ~/ 2) + 1,
          );
        } else {
          // Handle bye (odd number of participants)
          await _createMatch(
            tournamentId: tournamentId,
            round: 1,
            player1Id: participants[i],
            player2Id: null, // Bye
            matchNumber: (i ~/ 2) + 1,
          );
        }
      }
    } catch (e) {
      ErrorHandler.logError('Failed to generate first round matches', e);
    }
  }

  /// Create match
  Future<void> _createMatch({
    required String tournamentId,
    required int round,
    required String? player1Id,
    String? player2Id,
    required int matchNumber,
  }) async {
    try {
      await _client.from('tournament_matches').insert({
        'tournament_id': tournamentId,
        'round': round,
        'match_number': matchNumber,
        'player1_id': player1Id,
        'player2_id': player2Id,
        'status': player2Id == null ? 'bye' : 'pending',
        'winner_id': player2Id == null ? player1Id : null,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      ErrorHandler.logError('Failed to create match', e);
    }
  }

  /// Update match result
  Future<void> updateMatchResult({
    required String matchId,
    required String winnerId,
    String? score,
    Map<String, dynamic>? matchData,
  }) async {
    try {
      await _client.from('tournament_matches').update({
        'winner_id': winnerId,
        'score': score,
        'match_data': matchData,
        'status': 'completed',
        'completed_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', matchId);

      // Get match details for next round
      final match = await _client
          .from('tournament_matches')
          .select('tournament_id, round, match_number')
          .eq('id', matchId)
          .single();

      // Check if round is complete and generate next round
      await _checkAndGenerateNextRound(
        match['tournament_id'],
        match['round'],
      );
    } catch (e) {
      ErrorHandler.logError('Failed to update match result', e);
      rethrow;
    }
  }

  /// Check and generate next round
  Future<void> _checkAndGenerateNextRound(
      String tournamentId, int currentRound) async {
    try {
      // Check if all matches in current round are completed
      final pendingMatches = await _client
          .from('tournament_matches')
          .select('id')
          .eq('tournament_id', tournamentId)
          .eq('round', currentRound)
          .eq('status', 'pending');

      if (pendingMatches.isEmpty) {
        // Get winners from current round
        final winners = await _client
            .from('tournament_matches')
            .select('winner_id')
            .eq('tournament_id', tournamentId)
            .eq('round', currentRound)
            .not('winner_id', 'is', null);

        final winnerIds =
            (winners as List).map((w) => w['winner_id'] as String).toList();

        if (winnerIds.length > 1) {
          // Generate next round matches
          await _generateNextRoundMatches(
              tournamentId, currentRound + 1, winnerIds);
        } else if (winnerIds.length == 1) {
          // Tournament finished
          await _finishTournament(tournamentId, winnerIds.first);
        }
      }
    } catch (e) {
      ErrorHandler.logError('Failed to check and generate next round', e);
    }
  }

  /// Generate next round matches
  Future<void> _generateNextRoundMatches(
      String tournamentId, int round, List<String> winners) async {
    try {
      // Update bracket current round
      await _client
          .from('tournament_brackets')
          .update({'current_round': round}).eq('tournament_id', tournamentId);

      // Create matches for next round
      for (int i = 0; i < winners.length; i += 2) {
        if (i + 1 < winners.length) {
          await _createMatch(
            tournamentId: tournamentId,
            round: round,
            player1Id: winners[i],
            player2Id: winners[i + 1],
            matchNumber: (i ~/ 2) + 1,
          );
        } else {
          // Handle bye
          await _createMatch(
            tournamentId: tournamentId,
            round: round,
            player1Id: winners[i],
            player2Id: null,
            matchNumber: (i ~/ 2) + 1,
          );
        }
      }
    } catch (e) {
      ErrorHandler.logError('Failed to generate next round matches', e);
    }
  }

  /// Finish tournament
  Future<void> _finishTournament(String tournamentId, String winnerId) async {
    try {
      // Update tournament status
      await _client.from('tournaments').update({
        'status': 'completed',
        'winner_id': winnerId,
        'completed_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', tournamentId);

      // Update bracket status
      await _client
          .from('tournament_brackets')
          .update({'status': 'completed'}).eq('tournament_id', tournamentId);
    } catch (e) {
      ErrorHandler.logError('Failed to finish tournament', e);
    }
  }

  /// Get tournament with real-time updates
  RealtimeChannel subscribeToTournament(String tournamentId) {
    return _client
        .channel('public:tournaments:id=eq.$tournamentId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'tournaments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: tournamentId,
          ),
          callback: (payload) {
            try {
              final tournament = Tournament.fromMap(
                Map<String, dynamic>.from(payload.newRecord),
              );
              // This would typically emit to a stream controller
              print('Tournament updated: ${tournament.name}');
            } catch (e) {
              ErrorHandler.logError('Failed to process tournament update', e);
            }
          },
        )
        .subscribe();
  }

  /// Get tournament matches with real-time updates
  RealtimeChannel subscribeToTournamentMatches(String tournamentId) {
    return _client
        .channel('public:tournament_matches:tournament_id=eq.$tournamentId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'tournament_matches',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'tournament_id',
            value: tournamentId,
          ),
          callback: (payload) {
            try {
              // This would typically emit to a stream controller
              print('Tournament matches updated');
            } catch (e) {
              ErrorHandler.logError(
                  'Failed to process tournament matches update', e);
            }
          },
        )
        .subscribe();
  }

  /// Get tournament participants with real-time updates
  RealtimeChannel subscribeToTournamentParticipants(String tournamentId) {
    return _client
        .channel(
            'public:tournament_participants:tournament_id=eq.$tournamentId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'tournament_participants',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'tournament_id',
            value: tournamentId,
          ),
          callback: (payload) {
            try {
              // This would typically emit to a stream controller
              print('Tournament participants updated');
            } catch (e) {
              ErrorHandler.logError(
                  'Failed to process tournament participants update', e);
            }
          },
        )
        .subscribe();
  }

  /// Get tournament bracket
  Future<TournamentBracket?> getTournamentBracket(String tournamentId) async {
    try {
      final response = await _client
          .from('tournament_brackets')
          .select('*')
          .eq('tournament_id', tournamentId)
          .single();

      return TournamentBracket.fromJson(response);
    } catch (e) {
      ErrorHandler.logError('Failed to get tournament bracket', e);
      return null;
    }
  }

  /// Get tournament matches
  Future<List<TournamentMatch>> getTournamentMatches(String tournamentId,
      {int? round}) async {
    try {
      var query = _client
          .from('tournament_matches')
          .select('''
            *,
            player1:profiles!tournament_matches_player1_id_fkey(
              id,
              username,
              display_name,
              avatar_url
            ),
            player2:profiles!tournament_matches_player2_id_fkey(
              id,
              username,
              display_name,
              avatar_url
            ),
            winner:profiles!tournament_matches_winner_id_fkey(
              id,
              username,
              display_name,
              avatar_url
            )
          ''')
          .eq('tournament_id', tournamentId)
          .order('round')
          .order('match_number');

      if (round != null) {
        // Apply round filter after the select
        final response = await query;
        final allMatches = (response as List)
            .map((match) => TournamentMatch.fromMap(match))
            .toList();

        return allMatches.where((match) => match.roundNumber == round).toList();
      }

      final response = await query;
      return (response as List)
          .map((match) => TournamentMatch.fromMap(match))
          .toList();
    } catch (e) {
      ErrorHandler.logError('Failed to get tournament matches', e);
      return [];
    }
  }

  /// Get tournament participants
  Future<List<TournamentParticipant>> getTournamentParticipants(
      String tournamentId) async {
    try {
      final response = await _client.from('tournament_participants').select('''
            *,
            profiles!tournament_participants_user_id_fkey(
              id,
              username,
              display_name,
              avatar_url
            )
          ''').eq('tournament_id', tournamentId).order('joined_at');

      return (response as List)
          .map((participant) => TournamentParticipant.fromMap(participant))
          .toList();
    } catch (e) {
      ErrorHandler.logError('Failed to get tournament participants', e);
      return [];
    }
  }

  /// Get tournament statistics
  Future<Map<String, dynamic>> getTournamentStats(String tournamentId) async {
    try {
      final participants = await getTournamentParticipants(tournamentId);
      final matches = await getTournamentMatches(tournamentId);

      return {
        'total_participants': participants.length,
        'total_matches': matches.length,
        'completed_matches':
            matches.where((m) => (m.status ?? '') == 'completed').length,
        'pending_matches': matches.where((m) => (m.status ?? '') == 'pending').length,
        'current_round': matches.isNotEmpty
            ? matches.map((m) => m.roundNumber ?? 1).reduce((a, b) => a > b ? a : b)
            : 1,
      };
    } catch (e) {
      ErrorHandler.logError('Failed to get tournament stats', e);
      return {};
    }
  }
}
